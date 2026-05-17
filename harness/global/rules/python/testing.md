# Python Testing Rules

## 구조
- 테스트 파일: `tests/test_<module>.py`
- 테스트 함수: `test_<행위>_<조건>_<기대결과>()`
- 예시: `test_login_with_invalid_password_returns_401()`
- conftest.py: 공유 fixture 정의

## Fixture
- fixture는 conftest.py에 정의
- scope 명시: function(기본), class, module, session
- fixture 팩토리: 다양한 변형이 필요할 때 사용
- 정리(cleanup): yield fixture 사용

## Assertion
- assert 문 하나에 하나의 검증만
- 커스텀 에러 메시지 포함: `assert result == expected, f"Got {result}"`
- pytest.raises로 예외 테스트
- pytest.approx로 부동소수점 비교

## Mock
- 외부 의존성(API, DB, 파일시스템)만 mock
- 내부 구현은 mock하지 말 것 — 리팩토링에 취약해짐
- mock 사용 시 호출 검증(assert_called_with) 포함

## 커버리지
- 최소 80% 라인 커버리지 목표
- 100% 추구하지 말 것 — 의미 있는 테스트에 집중
- 핵심 비즈니스 로직은 100% 커버
- 에러 경로도 테스트 포함

## TDD
- RED: 실패하는 테스트 먼저 작성
- GREEN: 테스트를 통과하는 최소한의 코드 작성
- REFACTOR: 중복 제거, 구조 개선
- 모든 새 기능은 TDD로 시작하는 것을 권장
