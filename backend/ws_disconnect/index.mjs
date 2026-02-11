import { DynamoDBClient, QueryCommand, DeleteItemCommand } from "@aws-sdk/client-dynamodb";

const ddb = new DynamoDBClient({});
const CONNECTIONS_TABLE = process.env.CONNECTIONS_TABLE;

export const handler = async (event) => {
  const connectionId = event.requestContext.connectionId;

  try {
    // Look up channel via GSI on connection_id
    const queryResult = await ddb.send(
      new QueryCommand({
        TableName: CONNECTIONS_TABLE,
        IndexName: "connection_id-index",
        KeyConditionExpression: "connection_id = :cid",
        ExpressionAttributeValues: {
          ":cid": { S: connectionId },
        },
      })
    );

    // Delete all connection records for this connection_id
    const deletePromises = (queryResult.Items || []).map((item) =>
      ddb.send(
        new DeleteItemCommand({
          TableName: CONNECTIONS_TABLE,
          Key: {
            channel: item.channel,
            connection_id: item.connection_id,
          },
        })
      )
    );

    await Promise.all(deletePromises);

    return { statusCode: 200, body: "Disconnected" };
  } catch (err) {
    console.error("Disconnect error:", err);
    return { statusCode: 500, body: "Failed to disconnect" };
  }
};
