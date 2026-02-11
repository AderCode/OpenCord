const COGNITO_USER_POOL_ID = process.env.COGNITO_USER_POOL_ID;
const COGNITO_CLIENT_ID = process.env.COGNITO_CLIENT_ID;
const REGION = process.env.AWS_REGION;
const ISSUER = `https://cognito-idp.${REGION}.amazonaws.com/${COGNITO_USER_POOL_ID}`;
const JWKS_URL = `${ISSUER}/.well-known/jwks.json`;

// Module-scope JWKS cache (persists across warm invocations)
let cachedJwks = null;

async function fetchJwks() {
  if (cachedJwks) return cachedJwks;
  const res = await fetch(JWKS_URL);
  if (!res.ok) throw new Error(`Failed to fetch JWKS: ${res.status}`);
  cachedJwks = await res.json();
  return cachedJwks;
}

function base64UrlDecode(str) {
  const padded = str.replace(/-/g, "+").replace(/_/g, "/");
  const binary = atob(padded);
  return Uint8Array.from(binary, (c) => c.charCodeAt(0));
}

function decodeJwtParts(token) {
  const parts = token.split(".");
  if (parts.length !== 3) throw new Error("Invalid JWT format");
  const header = JSON.parse(new TextDecoder().decode(base64UrlDecode(parts[0])));
  const payload = JSON.parse(new TextDecoder().decode(base64UrlDecode(parts[1])));
  return { header, payload, signatureInput: parts[0] + "." + parts[1], signature: parts[2] };
}

async function importJwk(jwk) {
  return crypto.subtle.importKey(
    "jwk",
    { kty: jwk.kty, n: jwk.n, e: jwk.e },
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["verify"]
  );
}

async function verifySignature(cryptoKey, signatureInput, signature) {
  const data = new TextEncoder().encode(signatureInput);
  const sig = base64UrlDecode(signature);
  return crypto.subtle.verify("RSASSA-PKCS1-v1_5", cryptoKey, sig, data);
}

function generatePolicy(principalId, effect, methodArn, context) {
  const arnParts = methodArn.split(":");
  const apiGatewayArn = arnParts[5].split("/");
  const resource = `arn:aws:execute-api:${arnParts[3]}:${arnParts[4]}:${apiGatewayArn[0]}/${apiGatewayArn[1]}/*`;

  return {
    principalId,
    policyDocument: {
      Version: "2012-10-17",
      Statement: [
        {
          Action: "execute-api:Invoke",
          Effect: effect,
          Resource: resource,
        },
      ],
    },
    context,
  };
}

export const handler = async (event) => {
  const token = event.queryStringParameters?.token;
  if (!token) {
    console.error("No token provided");
    return "Unauthorized";
  }

  try {
    const { header, payload, signatureInput, signature } = decodeJwtParts(token);

    // Fetch JWKS and find matching key
    const jwks = await fetchJwks();
    const jwk = jwks.keys.find((k) => k.kid === header.kid);
    if (!jwk) {
      console.error("No matching kid in JWKS");
      return "Unauthorized";
    }

    // Verify signature
    const cryptoKey = await importJwk(jwk);
    const valid = await verifySignature(cryptoKey, signatureInput, signature);
    if (!valid) {
      console.error("Invalid signature");
      return "Unauthorized";
    }

    // Validate claims
    const now = Math.floor(Date.now() / 1000);
    if (payload.exp <= now) {
      console.error("Token expired");
      return "Unauthorized";
    }
    if (payload.iss !== ISSUER) {
      console.error("Invalid issuer");
      return "Unauthorized";
    }
    if (payload.aud !== COGNITO_CLIENT_ID && payload.client_id !== COGNITO_CLIENT_ID) {
      console.error("Invalid audience");
      return "Unauthorized";
    }
    if (payload.token_use !== "id") {
      console.error("Invalid token_use");
      return "Unauthorized";
    }

    // Return Allow policy with user context
    return generatePolicy(payload.sub, "Allow", event.methodArn, {
      userId: payload.sub,
      username: payload["cognito:username"] || payload.preferred_username || payload.sub,
      email: payload.email || "",
    });
  } catch (err) {
    console.error("Auth error:", err);
    return "Unauthorized";
  }
};
