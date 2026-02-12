import { DynamoDBClient, QueryCommand } from "@aws-sdk/client-dynamodb";

const ddb = new DynamoDBClient({});
const MESSAGES_TABLE = process.env.MESSAGES_TABLE;

export const handler = async (event) => {
  const method = event.requestContext?.http?.method || event.httpMethod;
  const path = event.requestContext?.http?.path || event.path;

  // GET /messages?channel=general&limit=50&before=<timestamp>
  if (method === "GET" && path === "/messages") {
    const params = event.queryStringParameters || {};
    const channel = params.channel || "general";
    const limit = Math.min(parseInt(params.limit) || 50, 100);

    const queryParams = {
      TableName: MESSAGES_TABLE,
      KeyConditionExpression: "channel = :ch",
      ExpressionAttributeValues: {
        ":ch": { S: channel },
      },
      ScanIndexForward: false, // newest first
      Limit: limit,
    };

    if (params.before) {
      queryParams.KeyConditionExpression += " AND #ts < :before";
      queryParams.ExpressionAttributeNames = { "#ts": "timestamp" };
      queryParams.ExpressionAttributeValues[":before"] = { S: params.before };
    }

    try {
      const result = await ddb.send(new QueryCommand(queryParams));

      const messages = (result.Items || []).map((item) => ({
        channel: item.channel.S,
        timestamp: item.timestamp.S,
        content: item.content.S,
        username: item.username?.S || "unknown",
        message_id: item.message_id?.S || null,
        edited_at: item.edited_at?.S || null,
      }));

      return {
        statusCode: 200,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          messages,
          hasMore: !!result.LastEvaluatedKey,
        }),
      };
    } catch (err) {
      console.error("Query error:", err);
      return {
        statusCode: 500,
        body: JSON.stringify({ error: "Internal server error" }),
      };
    }
  }

  return {
    statusCode: 404,
    body: JSON.stringify({ error: "Not found" }),
  };
};
