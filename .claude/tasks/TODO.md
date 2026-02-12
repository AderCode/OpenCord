# OpenCord — Remaining Work

## Completed

- [x] Terraform infrastructure (37 files) — DNS, ACM, Cognito, API Gateway HTTP/WS, S3+CloudFront, Lambdas, DynamoDB, monitoring
- [x] Backend Lambda functions — message CRUD, WebSocket lifecycle, presence, JWT verification
- [x] Frontend React PWA (74 files) — glassmorphism dark theme, auth flow, real-time chat, responsive layout, PWA

## In Progress

_(nothing currently in progress)_

## Remaining — Backend Enhancements

- [x] WebSocket authorizer — Lambda REQUEST authorizer on `$connect` validates JWT; server derives username from connections table
- [x] Message edit/delete API — backend only supports create + read
- [ ] Channel CRUD API — no endpoints to create/list/delete channels; frontend hardcodes `general`, `random`, `help`
- [ ] Typing indicator events — WebSocket action for `startTyping`/`stopTyping` broadcast
- [ ] User presence API — expose connected users per channel via REST (DynamoDB connections table exists but isn't queried by frontend)
- [ ] Rate limiting — API Gateway throttling config or Lambda-level rate limits
- [ ] Message pagination cursor — current `before=<timestamp>` works but cursor-based would be more robust

## Remaining — Frontend Enhancements

- [ ] Members panel — wire up to real presence data once backend exposes it
- [ ] Typing indicator — wire up `TypingIndicator.jsx` once backend supports typing events
- [x] Message edit/delete UI — once backend supports it
- [ ] Channel creation UI — replace the join-by-name input with proper create/browse flow once API exists
- [ ] Emoji reactions — no backend support yet
- [ ] File/image uploads — needs S3 presigned URL endpoint
- [ ] User profile/settings page
- [ ] Thread/reply support
- [ ] Search messages
- [ ] Replace placeholder PNG icons with proper designed icons
- [ ] Splash screen images for iOS PWA

## Remaining — Voice & Video

- [ ] WebRTC signaling server (could be a separate WebSocket route or Lambda)
- [ ] Voice channel UI
- [ ] Video channel UI
- [ ] Screen sharing

## Remaining — DevOps & Quality

- [ ] Unit tests — no test framework set up yet (Vitest recommended for frontend)
- [ ] E2E tests — Playwright or Cypress
- [ ] CI/CD pipeline — GitHub Actions for lint, test, build, deploy
- [ ] Frontend deployment automation — `aws s3 sync dist/ s3://<bucket>` + CloudFront invalidation
- [ ] Environment-specific configs (staging vs production)
- [ ] Error tracking (Sentry or similar)
- [ ] Analytics

## Remaining — Security

- [ ] Content Security Policy headers (CloudFront response headers policy)
- [ ] Input sanitization on message content (XSS prevention)
- [ ] WAF rules review and tuning
- [ ] Cognito advanced security features (compromised credentials, adaptive auth)
- [ ] Audit logging

## Notes

- Frontend derives all URLs from `VITE_BASE_DOMAIN` — no AWS resource IDs exposed
- Cognito Client ID must be provided as `VITE_COGNITO_CLIENT_ID` (AWS-generated, not in Terraform outputs yet)
- DynamoDB tables: `messages` (PK: channel, SK: timestamp), `connections` (PK: channel, SK: connection_id + TTL)
