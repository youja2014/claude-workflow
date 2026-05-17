# Python Style Rules

## 타입 힌트
- 모든 함수 시그니처에 타입 힌트 필수
- `from __future__ import annotations` 모든 파일 상단에
- 복잡한 타입은 TypeAlias로 정의
- Optional 대신 `X | None` 사용 (3.10+)
- 컬렉션: `list[str]`, `dict[str, int]` (내장 타입 사용)

## 클래스
- 데이터 클래스: `@dataclass` 또는 pydantic `BaseModel` 사용
- 불변 데이터: `@dataclass(frozen=True)` 또는 `NamedTuple`
- 상속보다 컴포지션 선호
- ABC는 실제로 다형성이 필요할 때만

## 비동기
- I/O 바운드 작업: async/await 사용
- CPU 바운드 작업: multiprocessing 사용
- async 함수에서 동기 블로킹 호출 금지
- asyncio.run()은 엔트리포인트에서만

## Import
- 표준 라이브러리 → 서드파티 → 로컬 순서 (isort가 처리)
- 와일드카드 import (`from x import *`) 금지
- 순환 import 금지 — TYPE_CHECKING 가드 사용

## 문자열
- f-string 사용 (% 포맷팅, .format() 금지)
- 긴 문자열: textwrap.dedent 또는 여러 줄 f-string
- 경로: pathlib.Path 사용, 문자열 연결 금지

## 프로젝트 구조
- src-layout 필수: `src/<package>/`
- 테스트: `tests/` (src와 분리)
- 설정: `src/<package>/config.py` (환경변수 로드)
- 상수: `src/<package>/constants.py`
