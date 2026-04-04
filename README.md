# dbt-base

dbt + Athena(Iceberg) 프로젝트 템플릿. 보안 검사(TruffleHog), SQL 린팅(sqlfluff), 모델 검증(dbt-checkpoint), AI 커밋 메시지(OpenCommit)가 pre-commit 훅으로 통합되어 있다.

## 사용 방법

### 1. 템플릿에서 저장소 생성

GitHub에서 **Use this template** → **Create a new repository**로 새 저장소를 생성한다.

```bash
git clone git@github.com:<org>/<new-repo>.git
cd <new-repo>
```

### 2. 초기 설정

```bash
npm run setup
```

`setup.sh`가 다음을 자동으로 처리한다:

- uv, npm, gh 필수 도구 확인
- NPM 패키지 및 Python/dbt 의존성 설치 (`requirements.txt`)
- pre-commit, TruffleHog 설치 (`uv tool install`)
- OpenCommit(Gemini) 설정
- Git Hooks 설치 (`uvx pre-commit install`)
- Git 사용자 정보 및 SonarQube 프로젝트 키 설정

> **사전 요구사항**: [uv](https://docs.astral.sh/uv/), Node.js (v22+), GitHub CLI (`gh`)

### 3. 프로젝트 이름 변경

`dbt_project.yml`과 `profiles.yml`에서 프로젝트명과 스키마를 수정한다.

```yaml
# dbt_project.yml
name: "my_project"        # ← "template"에서 변경
profile: "athena"

seeds:
  my_project:              # ← 프로젝트명과 동일하게
    +schema: bronze

models:
  my_project:              # ← 프로젝트명과 동일하게
    bronze:
      schema: bronze
```

```yaml
# profiles.yml
athena:
  target: dev
  outputs:
    dev:
      type: athena
      schema: my_project   # ← 프로젝트명과 동일하게
      # ... 나머지 연결 정보
```

### 4. AWS 인증 확인

```bash
# AWS 프로파일이 profiles.yml의 aws_profile_name과 일치하는지 확인
aws sts get-caller-identity --profile dev

# dbt 연결 테스트
dbt debug --profiles-dir .
```

---

## 프로젝트 구조

```
.
├── models/
│   ├── bronze/          # 원천 데이터 1:1 복제 (staging)
│   ├── silver/          # 비즈니스 로직 적용 (intermediate, fact, dimension)
│   └── gold/            # 최종 소비용 집계 테이블
├── macros/              # 재사용 가능한 SQL 매크로
├── seeds/               # CSV 정적 데이터
├── snapshots/           # SCD Type 2 스냅샷
├── analyses/            # 분석용 SQL (빌드 대상 아님)
├── tests/               # 커스텀 데이터 테스트
├── scripts/
│   ├── setup.sh                # 환경 초기 설정
│   ├── smart-commit-hook.sh    # AI 커밋 메시지 생성
│   └── validate_commit.py      # 커밋 메시지 규칙 검증
├── dbt_project.yml      # dbt 프로젝트 설정
├── profiles.yml         # Athena 연결 프로파일
├── .sqlfluff            # SQL 린팅 규칙
├── .dbt-checkpoint.yaml # dbt-checkpoint 설정
└── .pre-commit-config.yaml
```

---

## 모델 명명 규칙

| 접두어 | 용도 | 예시 |
|--------|------|------|
| `stg_` | 원천 데이터 정제 (staging) | `stg_users.sql` |
| `int_` | 중간 변환 (intermediate) | `int_user_sessions.sql` |
| `fct_` | 팩트 테이블 | `fct_orders.sql` |
| `dim_` | 디멘션 테이블 | `dim_products.sql` |
| `agg_` | 집계 테이블 | `agg_daily_revenue.sql` |
| `base_` | 기초 모델 | `base_raw_events.sql` |
| `meta_` | 메타데이터 모델 | `meta_column_stats.sql` |

---

## 컬럼 명명 규칙

pre-commit 훅이 데이터 타입에 따라 컬럼명을 자동 검증한다.

| 데이터 타입 | 규칙 | 예시 |
|-------------|------|------|
| `BOOLEAN` | `is_` / `has_` / `do_` 접두어 | `is_active`, `has_email` |
| `TIMESTAMP` | `_at` / `_timestamp` / `_time` 접미어 | `created_at`, `login_time` |
| `DATE` | `_date` / `_dt` 접미어 | `order_date`, `birth_dt` |
| `NUMERIC/DECIMAL` | `_amt` / `_amount` / `_price` / `_revenue` 접미어 | `total_amount`, `unit_price` |
| `INTEGER` | `n_` / `cnt_` / `total_` 접두어 | `n_orders`, `cnt_users` |

---

## 커밋 메시지 규칙

브랜치 유형에 따라 커밋 메시지 형식이 강제된다.

| 브랜치 | 형식 | 예시 |
|--------|------|------|
| `main` | `vX.Y.Z: 메시지` | `v1.2.3: 월별 집계 모델 추가` |
| `develop` | `develop: 메시지` | `develop: stg_users 컬럼 정리` |
| `feature/*` | `feature/이름: 메시지` | `feature/user-analytics: 세션 모델 구현` |
| `release/*` | `release/vX.Y.Z: 메시지` | `release/v2.0.0: 릴리스 준비` |
| `hotfix/*` | `hotfix/이름: 메시지` | `hotfix/null-fix: NULL 처리 수정` |

> AI가 자동으로 커밋 메시지를 작성하며, `prepare-commit-msg` 훅에서 브랜치명을 접두어로 붙여준다.

---

## Pre-commit 훅 실행 순서

커밋 시 다음 순서로 자동 실행된다.

```
1. TruffleHog        — 시크릿 키 유출 검사
2. 기본 검사          — EOF, trailing whitespace, YAML/JSON 검증
3. ruff              — Python 린팅 + 포매팅
4. sqlfluff          — SQL 자동 수정 + 린팅 (dbt templater)
5. dbt parse/docs    — manifest.json, catalog.json 갱신
6. dbt-checkpoint    — 모델 명명규칙, 문서화, 컬럼 계약 검증
7. 커밋 메시지        — AI 생성 + 브랜치별 형식 검증
```

---

## 주요 명령어

```bash
# 모든 모델 실행
dbt run --profiles-dir .

# 특정 모델만 실행
dbt run --profiles-dir . --models stg_users

# 특정 레이어 실행
dbt run --profiles-dir . --models silver.*

# 테스트
dbt test --profiles-dir .

# seed 데이터 로드
dbt seed --profiles-dir .

# 문서 생성 및 서버
dbt docs generate --profiles-dir .
dbt docs serve --profiles-dir . --host 0.0.0.0 --port 8080

# 연결 확인
dbt debug --profiles-dir .

# SQL 컴파일 (실행 없이 확인)
dbt compile --profiles-dir . --models stg_users
```

---

## 모델 추가 시 체크리스트

1. `models/<layer>/` 디렉토리에 SQL 파일 생성 (명명규칙 준수)
2. 같은 디렉토리의 `schema.yml`에 모델 정의 추가
   - 모델 description 작성
   - 모든 컬럼 나열 및 description 작성
   - 컬럼 data_type에 맞는 명명규칙 적용
3. `ref()` / `source()`로 의존성 참조 (하드코딩 금지)
4. SQL 끝에 세미콜론 없을 것

```yaml
# schema.yml 예시
models:
  - name: stg_users
    description: "사용자 원천 데이터 정제 모델"
    columns:
      - name: user_id
        description: "사용자 고유 식별자"
      - name: is_active
        description: "활성 사용자 여부"
        data_type: BOOLEAN
      - name: created_at
        description: "계정 생성 시각"
        data_type: TIMESTAMP
```

---

## Iceberg 테이블 주의사항

Athena에서 Iceberg 테이블 생성 시 RENAME을 통한 near-zero downtime 전략을 사용하므로, `profiles.yml`의 `s3_data_naming` 옵션에 `unique`가 포함되어야 한다.

```yaml
# profiles.yml
s3_data_naming: schema_table_unique  # 기본값, 변경하지 않을 것
```

이 설정이 없으면 다음 에러가 발생한다:

```
You need to have an unique table location when creating Iceberg table
since we use the RENAME feature to have near-zero downtime.
```
