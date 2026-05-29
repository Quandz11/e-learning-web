# Mobile Backend Contract Freeze (v1)

## Purpose
- Lock API contracts used by mobile app until production rollout is complete.
- Prevent accidental breaking changes between backend and Flutter clients.

## Effective date
- Start: 2026-05-30
- End: until production rollout reaches 100% and stabilization window closes.

## Global response conventions
- Success:
  - `2xx` with payload per endpoint.
- Error:
  - Must expose stable shape:
    - `code`: machine-readable error code
    - `message`: human-readable summary
    - `errors`: optional field-level/detail map
- Any new field must be additive and backward compatible.
- Existing field names/types must not change during freeze.

## Auth contracts
- `POST /api/auth/login`
- `POST /api/auth/register`
- `POST /api/auth/verify-otp`
- `POST /api/auth/refresh`
- `POST /api/auth/logout`
- Contract notes:
  - Access/refresh token fields must remain stable.
  - Refresh behavior must be idempotent for repeated client retry.

## Payment contracts
- `POST /api/payments/checkout`
- `GET /api/payments/status`
- `GET /api/payments/status-by-code`
- `GET /api/payments/my-orders`
- `POST /api/payments/webhook/payos` (server-server)
- Contract notes:
  - `orderId`, `orderCode`, `status`, `amount`, `items` fields must be stable.
  - Callback/deeplink mapping fields required by mobile must be preserved.

## Chat contracts
- `GET /api/chat/conversations`
- `GET /api/chat/conversations/{id}/messages`
- `POST /api/chat/messages`
- `PUT /api/chat/conversations/{id}/read`
- `GET /api/chat/unread-count`
- SignalR hub:
  - `/hubs/chat`
  - Events: `ReceiveMessage`
  - Methods: `SendMessage`, `JoinConversation`, `LeaveConversation`, `MarkAsRead`

## Notification contracts
- `GET /api/notifications`
- `PUT /api/notifications/{id}/read`
- `PUT /api/notifications/read-all`
- `POST /api/notifications/device-tokens`
- `DELETE /api/notifications/device-tokens/{deviceId}`
- SignalR hub:
  - `/hubs/notification`
  - Events: `ReceiveNotification`

## Forum contracts
- `GET /api/forum/categories`
- `GET /api/forum/categories/{categoryId}/threads`
- `GET /api/forum/threads/{id}`
- `GET /api/forum/threads/{threadId}/posts`
- `POST /api/forum/threads`
- `PUT /api/forum/threads/{id}`
- `DELETE /api/forum/threads/{id}`
- `POST /api/forum/posts`
- `PUT /api/forum/posts/{id}`
- `DELETE /api/forum/posts/{id}`

## Wellness + AI contracts (mobile critical)
- Endpoints used by mobile in current scope must remain additive-only.
- Any payload changes require:
  1. RFC note in PR
  2. mobile compatibility review
  3. staged rollout plan

## Change control during freeze
- Allowed without version bump:
  - Add optional fields
  - Add new endpoints not used by current app builds
- Not allowed:
  - Rename/remove required fields
  - Change required field type
  - Change endpoint semantics used by released mobile builds

## Owner and approval
- Backend owner: API contract maintainer
- Mobile owner: Flutter lead
- Required approvals for contract changes: backend + mobile
