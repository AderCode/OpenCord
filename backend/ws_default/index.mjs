import { DynamoDBClient, PutItemCommand, QueryCommand, UpdateItemCommand, DeleteItemCommand, GetItemCommand } from "@aws-sdk/client-dynamodb";
import { ApiGatewayManagementApiClient, PostToConnectionCommand } from "@aws-sdk/client-apigatewaymanagementapi";
import crypto from "node:crypto";

const ddb = new DynamoDBClient({});
const MESSAGES_TABLE = process.env.MESSAGES_TABLE;
const CONNECTIONS_TABLE = process.env.CONNECTIONS_TABLE;

// Look up username and role from connections table by connectionId
async function lookupUser(connectionId) {
  const result = await ddb.send(
    new QueryCommand({
      TableName: CONNECTIONS_TABLE,
      IndexName: "connection_id-index",
      KeyConditionExpression: "connection_id = :cid",
      ExpressionAttributeValues: {
        ":cid": { S: connectionId },
      },
      Limit: 1,
    })
  );
  const item = result.Items?.[0];
  return {
    username: item?.username?.S || "anonymous",
    role: item?.role?.S || "member",
  };
}

// Look up a message by its message_id using the GSI
async function getMessageByID(messageId) {
  const result = await ddb.send(
    new QueryCommand({
      TableName: MESSAGES_TABLE,
      IndexName: "message_id-index",
      KeyConditionExpression: "message_id = :mid",
      ExpressionAttributeValues: {
        ":mid": { S: messageId },
      },
      Limit: 1,
    })
  );
  return result.Items?.[0] || null;
}

// Broadcast a payload to all connections in a channel
async function broadcastToChannel(apigw, channel, payload) {
  const connections = await ddb.send(
    new QueryCommand({
      TableName: CONNECTIONS_TABLE,
      KeyConditionExpression: "channel = :ch",
      ExpressionAttributeValues: {
        ":ch": { S: channel },
      },
    })
  );

  const postCalls = (connections.Items || []).map(async (item) => {
    const targetId = item.connection_id.S;
    try {
      await apigw.send(
        new PostToConnectionCommand({
          ConnectionId: targetId,
          Data: Buffer.from(JSON.stringify(payload)),
        })
      );
    } catch (err) {
      if (err.statusCode === 410) {
        await ddb.send(
          new DeleteItemCommand({
            TableName: CONNECTIONS_TABLE,
            Key: {
              channel: item.channel,
              connection_id: item.connection_id,
            },
          })
        );
      }
    }
  });

  await Promise.all(postCalls);
}

export const handler = async (event) => {
  const { domainName, stage } = event.requestContext;
  const endpoint = `https://${domainName}/${stage}`;
  const apigw = new ApiGatewayManagementApiClient({ endpoint });

  const connectionId = event.requestContext.connectionId;
  let body;

  try {
    body = JSON.parse(event.body);
  } catch {
    return { statusCode: 400, body: "Invalid JSON" };
  }

  const action = body.action || "sendMessage";

  // --- sendMessage ---
  if (action === "sendMessage") {
    const channel = body.channel || "general";
    const content = body.content;

    if (!content) {
      return { statusCode: 400, body: "Missing content" };
    }

    const { username, role } = await lookupUser(connectionId);
    const timestamp = new Date().toISOString();
    const message_id = crypto.randomUUID();

    await ddb.send(
      new PutItemCommand({
        TableName: MESSAGES_TABLE,
        Item: {
          channel: { S: channel },
          timestamp: { S: timestamp },
          content: { S: content },
          username: { S: username },
          message_id: { S: message_id },
        },
      })
    );

    await broadcastToChannel(apigw, channel, {
      type: "newMessage",
      message_id,
      channel,
      timestamp,
      content,
      username,
      role,
    });

    return { statusCode: 200, body: "Message sent" };
  }

  // --- editMessage ---
  if (action === "editMessage") {
    const { message_id, content } = body;

    if (!message_id || !content) {
      return { statusCode: 400, body: "Missing message_id or content" };
    }

    const item = await getMessageByID(message_id);
    if (!item) {
      return { statusCode: 404, body: "Message not found" };
    }

    const { username, role } = await lookupUser(connectionId);
    if (role !== "owner" && item.username?.S !== username) {
      return { statusCode: 403, body: "Not authorized to edit this message" };
    }

    const edited_at = new Date().toISOString();

    await ddb.send(
      new UpdateItemCommand({
        TableName: MESSAGES_TABLE,
        Key: {
          channel: item.channel,
          timestamp: item.timestamp,
        },
        UpdateExpression: "SET content = :c, edited_at = :e",
        ExpressionAttributeValues: {
          ":c": { S: content },
          ":e": { S: edited_at },
        },
      })
    );

    await broadcastToChannel(apigw, item.channel.S, {
      type: "editMessage",
      message_id,
      channel: item.channel.S,
      timestamp: item.timestamp.S,
      content,
      edited_at,
    });

    return { statusCode: 200, body: "Message edited" };
  }

  // --- deleteMessage ---
  if (action === "deleteMessage") {
    const { message_id } = body;

    if (!message_id) {
      return { statusCode: 400, body: "Missing message_id" };
    }

    const item = await getMessageByID(message_id);
    if (!item) {
      return { statusCode: 404, body: "Message not found" };
    }

    const { username, role } = await lookupUser(connectionId);
    if (role !== "owner" && item.username?.S !== username) {
      return { statusCode: 403, body: "Not authorized to delete this message" };
    }

    await ddb.send(
      new DeleteItemCommand({
        TableName: MESSAGES_TABLE,
        Key: {
          channel: item.channel,
          timestamp: item.timestamp,
        },
      })
    );

    await broadcastToChannel(apigw, item.channel.S, {
      type: "deleteMessage",
      message_id,
      channel: item.channel.S,
      timestamp: item.timestamp.S,
    });

    return { statusCode: 200, body: "Message deleted" };
  }

  return { statusCode: 400, body: "Unknown action" };
};
