# Code Quality Rules

## DRY (Don't Repeat Yourself)
- 동일 로직이 3번 이상 반복되면 함수/클래스로 추출
- 단, 2번 반복은 허용 — 섣부른 추상화보다 중복이 낫다

## KISS (Keep It Simple, Stupid)
- 가장 단순한 해결책을 먼저 시도
- 복잡한 패턴(메타프로그래밍, 데코레이터 체이닝)은 명확한 이유가 있을 때만

## YAGNI (You Aren't Gonna Need It)
- 현재 요구사항에 없는 기능을 미리 구현하지 말 것
- 설정 가능성(configurability)을 미리 추가하지 말 것
- 추상 레이어는 실제로 두 가지 이상 구현체가 필요할 때만

## 함수 설계
- 하나의 함수는 하나의 책임만
- 함수 길이: 50줄 이하 권장
- 매개변수: 4개 이하 권장, 초과 시 dataclass/dict로 그룹화
- 부수효과(side effect)를 최소화하고 명시적으로 문서화

## 네이밍
- 이름만으로 의도를 파악할 수 있어야 함
- 약어 사용 금지 (msg → message, btn → button)
- boolean: is_, has_, can_, should_ 접두사
- 컬렉션: 복수형 사용 (users, items)

## 에러 처리
- 에러를 삼키지 말 것 (빈 except 금지)
- 복구 가능한 에러와 불가능한 에러를 구분
- 에러 메시지에 디버깅에 필요한 컨텍스트 포함
