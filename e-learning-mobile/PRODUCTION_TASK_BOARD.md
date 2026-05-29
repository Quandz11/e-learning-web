# Mobile Production Task Board

## Huong dan dung board
- Trang thai:
  - `Todo`: chua bat dau
  - `In Progress`: dang thuc hien
  - `Done`: da hoan tat va qua acceptance
- Uu tien: `P0` (bat buoc), `P1` (cao), `P2` (nen co)
- Muc tieu: dua app den production voi rollout 25% -> 50% -> 100%.

## Todo

- [ ] `MOB-002` `P0` Firebase setup Android+iOS  
Mo ta: them `google-services.json`, `GoogleService-Info.plist`, cau hinh APNs key/certificate.  
Phu thuoc: `MOB-001`  
Acceptance: app nhan duoc push foreground/background tren Android va iOS.

- [ ] `MOB-003` `P0` Push token lifecycle hardening  
Mo ta: register/refresh/unregister token theo login/logout/switch account, xu ly retry va stale token.  
Phu thuoc: `MOB-002`  
Acceptance: token duoc dong bo dung tren server, khong gui nham account.

- [ ] `MOB-004` `P0` Realtime stability package  
Mo ta: reconnect strategy, unread sync REST vs SignalR, anti-duplicate events.  
Phu thuoc: `MOB-001`  
Acceptance: chat/notification reconnect on dinh khi doi network.

- [ ] `MOB-005` `P0` Payment callback production flow  
Mo ta: complete deeplink/universal link + polling timeout/retry + idempotency guard client.  
Phu thuoc: `MOB-001`  
Acceptance: callback thanh cong va order status dung 100% tren test suite.

- [ ] `MOB-006` `P0` Auth edge-case hardening  
Mo ta: OTP/2FA edge cases, refresh race condition, global invalid session handling.  
Phu thuoc: `MOB-001`  
Acceptance: khong con bug P1 trong auth regression.

- [ ] `MOB-007` `P1` Learning player production pass  
Mo ta: resume chinh xac, xu ly loi truy cap, completion sync on dinh.  
Phu thuoc: `MOB-001`  
Acceptance: E2E hoc vien cu/moi pass tren Android + iOS.

- [ ] `MOB-008` `P1` Forum/chat UX completion  
Mo ta: paging, optimistic update rollback, permissions theo role/author.  
Phu thuoc: `MOB-001`, `MOB-004`  
Acceptance: CRUD forum/chat khong mismatch voi backend permissions.

- [ ] `MOB-009` `P1` Wellness + AI end-to-end  
Mo ta: onboarding -> planner -> check-in -> coach -> history hoan chinh.  
Phu thuoc: `MOB-001`  
Acceptance: E2E wellness/AI pass, khong crash blocker.

- [ ] `MOB-010` `P0` Test automation gate  
Mo ta: unit+integration+E2E cho flow critical (auth, payment, progress, realtime).  
Phu thuoc: `MOB-003`, `MOB-004`, `MOB-005`, `MOB-006`, `MOB-007`  
Acceptance: pipeline xanh tren staging va nightly.

- [ ] `MOB-011` `P0` Performance hardening  
Mo ta: startup time budget, jank reduction, memory profile man hinh chinh.  
Phu thuoc: `MOB-007`, `MOB-008`, `MOB-009`  
Acceptance: dat nguong hieu nang da chot.

- [ ] `MOB-012` `P0` Security hardening  
Mo ta: redact log nhay cam, secure storage review, basic integrity checks.  
Phu thuoc: `MOB-006`  
Acceptance: security checklist pass truoc beta.

- [ ] `MOB-013` `P0` Observability + alerting  
Mo ta: Crashlytics/Sentry dashboard, funnel analytics, alert crash/API/payment spike.  
Phu thuoc: `MOB-010`  
Acceptance: dashboard co du KPI va alert test pass.

- [ ] `MOB-014` `P0` Release engineering + store readiness  
Mo ta: signing/provisioning, metadata, privacy form, data safety.  
Phu thuoc: `MOB-011`, `MOB-012`, `MOB-013`  
Acceptance: artifact release ready cho closed beta.

- [ ] `MOB-015` `P0` Staged rollout execution  
Mo ta: rollout 25% -> 50% -> 100% + go/no-go gate moi moc.  
Phu thuoc: `MOB-014`  
Acceptance: dat crash/conversion threshold moi stage.

- [ ] `MOB-016` `P1` Post-release stabilization window  
Mo ta: 2 tuan monitor, hotfix P1/P2, bao cao cohort retention + conversion.  
Phu thuoc: `MOB-015`  
Acceptance: production on dinh, khong con su co nghiem trong mo.

## In Progress
- [ ] `MOB-010` `P0` Test automation gate  
Tien do hien tai:
- Da nang cap workflow CI voi quality gate (`format/analyze/test --coverage`) truoc build Android/iOS.
- Da upload artifact coverage + Android APK de QA kiem tra.
- Con thieu: integration/E2E lanes va nightly matrix.
- [ ] `MOB-004` `P0` Realtime stability package  
Tien do hien tai:
- Da bo sung duplicate-event guard cho chat/notification realtime o controller.
- Da bo sung auto-resync unread va conversations sau reconnect.
- Da them unit tests cho duplicate message/notification.

## Done
- [x] `MOB-001` `P0` Contract freeze mobile-backend  
Mo ta: da tao tai lieu dong bang contract tai `MOBILE_BACKEND_CONTRACT_FREEZE.md`.

- [x] `MOB-000` Mobile architecture baseline  
Mo ta: scaffold Flutter + clean module structure + routing/auth/session foundation.

- [x] `MOB-000A` Community + realtime base  
Mo ta: forum CRUD, chat/notification realtime co reconnect co ban.

- [x] `MOB-000B` Phase 4.5 foundation  
Mo ta: backend co endpoint device token + mobile co push registration service (safe fallback neu chua co Firebase config).

## Milestone map
1. Milestone A (Beta-ready): `MOB-001` -> `MOB-013`
2. Milestone B (Release-ready): `MOB-014`
3. Milestone C (Production complete): `MOB-015` + `MOB-016`

## KPI gate truoc rollout 100%
- Crash-free users >= 99.5%
- Payment success rate dat target da chot
- Auth success rate va refresh success rate dat target da chot
- Khong con P0/P1 open
