# SteadyTap Service-Grade SPECKIT

Last updated: 2026-03-08

## S - Scope
- 대상: accessibility-first iOS app + integrated FastAPI backend
- baseline 목표: mobile UX와 backend contract를 한 제품처럼 보이게 정리

## P - Product Thesis
- SteadyTap은 앱 데모와 API 데모가 따로 노는 프로젝트가 아니라 `사용자 경험과 coaching backend가 결합된 제품`이어야 한다.
- 리뷰어는 app flow와 backend contract를 함께 읽을 수 있어야 한다.

## E - Execution
- iOS flow, session model, backend endpoints를 같은 narrative로 유지
- app/backend README와 local runbook을 계속 동기화
- backend CI와 sample session proof를 baseline으로 유지

## C - Criteria
- backend tests green
- README에서 app + backend 구조가 즉시 이해됨
- coaching/session contract가 흔들리지 않음

## K - Keep
- accessibility-first stance
- integrated app/service posture

## I - Improve
- UI screenshots와 session transcript pack 강화
- sync/error-state UX 문서 추가

## T - Trace
- `README.md`
- `backend/`
- `Core/`
- `.github/workflows/backend-ci.yml`

