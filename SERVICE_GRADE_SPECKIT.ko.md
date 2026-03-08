# SteadyTap Service-Grade SPECKIT

Last updated: 2026-03-08

## S - Scope
- 대상: accessibility-first iOS app + integrated FastAPI backend
- 이번 iteration 목표: reviewer가 앱 홈 화면과 backend API만 봐도 sync boundary, coaching contract, cloud/local posture를 이해하게 만든다.

## P - Product Thesis
- SteadyTap은 앱 데모와 API 데모가 따로 노는 프로젝트가 아니라 `사용자 경험과 coaching backend가 결합된 제품`이어야 한다.
- 리뷰어는 app flow와 backend contract를 함께 읽을 수 있어야 한다.

## E - Execution
- `GET /v1/runtime-brief`와 `GET /v1/schema/coach-report`로 backend reviewer surface를 고정한다.
- 앱 홈 화면에 service brief card를 넣어 auth mode, storage mode, schema, review flow를 먼저 보여준다.
- iOS flow, session model, backend endpoints를 같은 narrative로 유지한다.

## C - Criteria
- backend tests green
- README에서 app + backend 구조와 service surfaces가 즉시 이해됨
- coaching/session contract가 흔들리지 않음
- 앱 홈에서 cloud/local posture가 명확히 보인다

## K - Keep
- accessibility-first stance
- integrated app/service posture

## I - Improve
- UI screenshots와 session transcript pack 강화
- sync/error-state UX 문서 추가
- backend replay fixtures와 cloud failure evidence 강화

## T - Trace
- `README.md`
- `backend/`
- `Core/`
- `.github/workflows/backend-ci.yml`
