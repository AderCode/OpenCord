import { DynamoDBClient, PutItemCommand } from "@aws-sdk/client-dynamodb";

const ddb = new DynamoDBClient({});
const CONNECTIONS_TABLE = process.env.CONNECTIONS_TABLE;

export const handler = async (event) => {
  const connectionId = event.requestContext.connectionId;
  const channel = event.queryStringParameters?.channel || "general";

  // Extract authenticated user info from Lambda authorizer context
  const authorizer = event.requestContext.authorizer || {};
  const userId = authorizer.userId || "unknown";
  const username = authorizer.username || "anonymous";

  const ttl = Math.floor(Date.now() / 1000) + 86400; // 24 hours

  try {
    await ddb.send(
      new PutItemCommand({
        TableName: CONNECTIONS_TABLE,
        Item: {
          channel: { S: channel },
          connection_id: { S: connectionId },
          ttl: { N: String(ttl) },
          connected_at: { S: new Date().toISOString() },
          user_id: { S: userId },
          username: { S: username },
        },
      })
    );

    return { statusCode: 200, body: "Connected" };
  } catch (err) {
    console.error("Connect error:", err);
    return { statusCode: 500, body: "Failed to connect" };
  }
};
