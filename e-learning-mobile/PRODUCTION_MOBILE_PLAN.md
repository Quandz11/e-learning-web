# Mobile Production Plan (Flutter)

## 1) Scope va muc tieu
- Muc tieu: dua ung dung mobile len production cho Android + iOS voi do on dinh cao, theo doi duoc, va rollout an toan.
- Kien truc giu nguyen: Riverpod + Clean Architecture + module-based features.
- Backend dung chung server hien tai, khong doi domain logic, chi bo sung contract can thiet cho mobile native.

## 2) Definition of Done
- Crash-free users >= 99.5%.
- Khong con blocker P0/P1 truoc rollout 100%.
- E2E critical journeys pass tren Android va iOS.
- Login/refresh/payment/realtime dat SLA da chot.
- Co runbook van hanh, rollback, va dashboard theo doi production.

## 3) Sprint backlog chi tiet

## Sprint 1 (2 tuan) - Contract lock + Push/Realtime production
### Muc tieu
- Khoa API contract va hoan tat luong push notification/realtime production-grade.

### Backlog
1. Backend API contract freeze:
- Chot schema loi chung: `code`, `message`, `errors`.
- Chot payload cho chat/notification/forum/payment callbacks.

2. Push notification:
- Tich hop Firebase config that (`google-services.json`, `GoogleService-Info.plist`).
- Hoan tat APNs key/certificate cho iOS.
- Hoan tat token lifecycle: register, refresh, unregister theo login/logout/account switch.
- Mapping push -> deep link dung man hinh.

3. Realtime:
- Hardening SignalR reconnect va session restore.
- Dong bo unread counters giua REST va realtime.
- Test reconnect khi doi network (wifi <-> 4G).

4. Payment mobile return:
- Deeplink/universal link callback end-to-end.
- Polling + retry + timeout behavior.
- Idempotency guard o client side.

### Acceptance
- Push nhan duoc foreground/background/khi app khoi dong lai.
- Realtime chat va notification reconnect on dinh, khong duplicate event.
- Payment callback ve dung trang thai don hang.

## Sprint 2 (2 tuan) - Hoan tat nghiep vu hoc vien + quality gates
### Muc tieu
- Day du luong nghiep vu hoc vien va dat quality gate de vao beta.

### Backlog
1. Auth hardening:
- Xu ly edge-case OTP/2FA.
- Fix race condition refresh token.
- Global logout va invalid session handling.

2. Learning module:
- Resume bai hoc chinh xac.
- Player video/PDF production behavior.
- Xu ly loi truy cap (het han/chua mua) thong nhat UX.

3. Forum + Chat:
- Pagination, refresh, optimistic update co rollback.
- Permissions (author/admin) chinh xac theo backend.

4. Wellness + AI:
- Hoan tat flow: onboarding -> plan -> check-in -> coach/chat history.

5. Test automation:
- Unit tests cho auth/session/payment/progress/chat state.
- Integration tests cho module critical.
- E2E journeys critical.

### Acceptance
- Toan bo critical journeys pass o staging.
- Regression suite xanh.
- Khong co bug nghiem trong o flow chinh.

## Sprint 3 (1-2 tuan) - Beta + performance + security + release ops
### Muc tieu
- Dat production readiness va rollout theo tung giai doan.

### Backlog
1. Hieu nang:
- Toi uu startup time.
- Giam jank/frame drop o man hinh chinh.
- On dinh memory usage.

2. Bao mat:
- Redact log nhay cam.
- Tang cuong secure storage usage.
- Them kiem tra basic integrity (root/jailbreak level can ban neu can).

3. Observability:
- Dashboard Crashlytics/Sentry theo release.
- Analytics funnel: register -> checkout -> completion -> retention.
- Alerting cho API error rate/crash spike/payment failure.

4. Release engineering:
- Android signing + iOS provisioning/profile.
- Store metadata, privacy form, data safety.
- Internal build -> closed beta -> staged rollout (25/50/100).

### Acceptance
- Dat KPI crash-free va conversion threshold.
- Go/no-go checklist pass moi moc rollout.
- Co rollback playbook da test.

## 4) Work breakdown theo module
### Core
- Env/flavor consistency.
- Router/deeplink map production.
- Network retry/backoff/cancel standards.
- Global error handling + telemetry.

### Auth
- Session restore + silent refresh.
- Token lifecycle + force logout flow.

### Learning
- Course list/detail/my-courses.
- Progress update + mark complete consistency.

### Payment
- Checkout flow + return URLs.
- Order status polling + retry strategy.

### Community
- Forum CRUD permissions.
- Chat/notification realtime + unread sync.

### Wellness/AI
- Planner/check-in/coach.
- AI task/chat history coherence.

## 5) KPI va gate truoc production
- Crash-free users >= 99.5%.
- API error rate (4xx/5xx) trong nguong da chot.
- Payment success rate dat target.
- D1 retention va completion rate dat target toi thieu cho beta cohort.

## 6) RACI de xuat
- Mobile team: implementation, test automation, performance.
- Backend team: contract support, callback/deeplink mapping, error standardization.
- QA: test matrix device + regression + E2E sign-off.
- PM/PO: release criteria, KPI threshold, go/no-go.

## 7) Release checklist
1. Build staging signed va pass regression.
2. Closed beta pass KPI toi thieu.
3. Security + privacy checklist complete.
4. Rollout 25% theo doi 24h.
5. Rollout 50% theo doi 24h.
6. Rollout 100% + post-release monitoring 2 tuan.

## 8) Ke hoach ngay sau production (2 tuan)
- Hotfix window cho P1/P2.
- Theo doi conversion va retention theo cohort.
- Chot backlog toi uu sprint tiep theo dua tren data production.
