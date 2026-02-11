import { DynamoDBClient, PutItemCommand, QueryCommand } from "@aws-sdk/client-dynamodb";
import { ApiGatewayManagementApiClient, PostToConnectionCommand } from "@aws-sdk/client-apigatewaymanagementapi";

const ddb = new DynamoDBClient({});
const MESSAGES_TABLE = process.env.MESSAGES_TABLE;
const CONNECTIONS_TABLE = process.env.CONNECTIONS_TABLE;

// Look up username from connections table by connectionId (scan with filter)
async function lookupUsername(connectionId) {
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
  return item?.username?.S || "anonymous";
}

export const handler = async (event) => {
  // Derive the management API endpoint from the request context (avoids circular TF dep)
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

  const channel = body.channel || "general";
  const content = body.content;

  if (!content) {
    return { statusCode: 400, body: "Missing content" };
  }

  // Server-derived username — ignore any client-provided username
  const username = await lookupUsername(connectionId);

  const timestamp = new Date().toISOString();
  const message = { channel, timestamp, content, username };

  // Store message in DynamoDB
  await ddb.send(
    new PutItemCommand({
      TableName: MESSAGES_TABLE,
      Item: {
        channel: { S: channel },
        timestamp: { S: timestamp },
        content: { S: content },
        username: { S: username },
      },
    })
  );

  // Fan-out: get all connections for this channel
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
          Data: Buffer.from(JSON.stringify(message)),
        })
      );
    } catch (err) {
      if (err.statusCode === 410) {
        // Stale connection — clean up
        const { DeleteItemCommand } = await import("@aws-sdk/client-dynamodb");
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

  return { statusCode: 200, body: "Message sent" };
};
