# DBT Base (Project Template)

이 저장소는 팀의 표준 개발 환경, 보안 설정(TruffleHog), 코드 품질 분석(SonarQube), AI 커밋 메시지 작성 도구가 통합된 기본 템플릿 저장소입니다.

새로운 프로젝트를 시작할 때 이 저장소를 템플릿으로 사용하여 생성하십시오.

## 1. 주요 기능 (Features)

---

- 보안 (Security): TruffleHog를 통한 비밀 키(Secret Key) 커밋 방지
- 품질 (Quality): SonarQube/SonarCloud 연동 자동화
- 자동화 (Automation): pre-commit 훅을 이용한 코드 포맷팅(Prettier) 및 커밋 메시지 검사
- AI 지원 (AI Assistant): OpenCommit(Gemini)을 이용한 커밋 메시지 자동 작성

## 2. 필수 요구 사항 (Prerequisites)

---

이 템플릿을 사용하기 위해 로컬 환경에 다음 도구들이 설치되어 있어야 합니다.

- Node.js (v22 이상)
  - macOS: `brew install node`
  - Ubuntu: `curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - && sudo apt install -y nodejs`
  - Amazon Linux 2023: `sudo dnf install nodejs22`

- Python (v3.11)
  - macOS: `brew install python@3.11`
  - Ubuntu: `sudo add-apt-repository ppa:deadsnakes/ppa -y && sudo apt install python3.11 python3.11-venv`
  - Amazon Linux 2023: `sudo dnf install python3.11 python3.11-devel`

- GitHub CLI (gh) (시크릿 자동 등록)
  - macOS: `brew install gh`
  - Ubuntu: `sudo apt install gh`
  - Amazon Linux 2023:
    `sudo dnf install 'dnf-command(config-manager)' & sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo & sudo dnf install gh`

## 3. 초기 설정 (Setup)

---

저장소를 Clone 받은 후, 프로젝트 루트에서 다음 명령어를 최초 한 번 실행하십시오.

```bash
npm run setup
```

## 4. DBT 설치

---

DBT를 설치합니다.

```bash
pip install -r requirements.txt
```

## 5. 명령어

---

### dbt init

DBT 프로젝트를 생성합니다.

```bash
# 프로젝트 초기화
dbt init <project>
```

### dbt run

데이터 변환을 실행하고 테이블을 생성하거나 업데이트합니다.

```bash
# 모든 모델 실행
dbt run

# 특정 모델 실행
dbt run --models 모델이름

# 특정 폴더 내 모든 모델 실행
dbt run --models bronze.*

# 최신 모델만 실행 (이전 모델과 비교하여 변경된 것만 실행)
dbt run --models @models
```

### dbt docs

dbt 프로젝트에 대한 문서를 생성하고 로컬 웹 서버에서 호스팅합니다.

```bash
# 문서 생성
dbt docs generate

# 문서 서버 실행
dbt docs serve --host 0.0.0.0 --port 8080
```

### dbt debug

dbt 설정을 확인하고 환경이 정상적으로 작동하는지 확인합니다.

```bash
# dbt 환경 진단
dbt debug
```

### dbt compile

모델을 실행하기 전에 SQL 코드를 컴파일하여 최종 SQL 쿼리를 미리 검토할 수 있습니다.

```bash
# 모든 모델 컴파일
dbt compile

# 특정 모델만 컴파일
dbt compile --models 모델이름
```

### dbt test

모델이나 데이터의 품질을 검증하기 위한 테스트를 실행합니다.

```bash
# 모든 테스트 실행
dbt test

# 특정 모델의 테스트만 실행
dbt test --models 모델이름

# 특정 테스트만 실행
dbt test --select 테스트이름
```

### dbt seed

CSV 파일로부터 정적 데이터를 데이터베이스에 로드합니다.

```bash
# 모든 seed 데이터 로드
dbt seed

# 특정 seed 파일만 로드
dbt seed --select 시드파일이름
```

### dbt run-operation

매크로를 실행하여 특정 작업을 수행합니다.

```bash
# 특정 매크로 실행
dbt run-operation 매크로이름
```

### dbt snapshot

스냅샷을 통해 시간에 따른 데이터 변경 사항을 기록합니다.

```bash
# 모든 스냅샷 실행
dbt snapshot

# 특정 스냅샷만 실행
dbt snapshot --select 스냅샷이름
```

## Integration

---

### datahub

```bash
dbt compile
# target/compiled/<프로젝트>/models/<모델>.sql: 데이터베이스에서 실행될 최종 SQL 쿼리

dbt docs generate
# target/manifest.json: 프로젝트 전체 메타데이터(모델, 소스, 관계 등)가 담긴 JSON 파일
# target/catalog.json: 데이터베이스의 실제 스키마 정보가 담긴 JSON 파일
# target/index.html: 웹에서 볼 수 있는 문서 페이지(정적 파일)
# target/graph.gpickle 등 문서화에 필요한 여러 파일 생성

dbt source freshness
# target/source.json: 소스 freshness 체크 결과가 담긴 JSON 파일
```

## Issue

---

### 1. You need to have an unique table location when creating Iceberg table ...

- dbt에서 athena 백엔드 엔진을 사용하여 S3에 Iceberg 테이블을 생성할 때 발생될 수 있는 오류이다.
- Iceberg 테이블을 생성할 때, 생성될 테이블을 임의의 공간에 먼저 생성한 다음, RENAME 기능을 사용하여 Iceberg 메타데이터에서 테이블을 참조 경로를 새로운 경로로 원자적으로 교체한다.
- 테이블을 다시 생성하는 과정에서 교체 순간의 다운타임을 최소화하기 위한 방식이며, iceberg 테이블 사용 시 profiles.yml 파일의 s3_data_naming 옵션에서 `unique`가 포함된 옵션의
  사용이 강제된다. (default: schema_table_unique)

```bash
15:15:46  Running with dbt=1.10.13
15:15:47  Registered adapter: athena=1.9.5
15:15:47  [WARNING]: Configuration paths exist in your dbt_project.yml file which do not apply to any resources.
There are 2 unused configuration paths:
- models.<schema>.gold
- models.<schema>.bronze
15:15:47  Found 1 model, 1 source, 474 macros
15:15:47
15:15:47  Concurrency: 1 threads (target='prod')
15:15:47
15:15:56  1 of 1 START sql table model <schema>_silver.int_category_tree ............... [RUN]
15:15:56  1 of 1 ERROR creating sql table model <schema>_silver.int_category_tree ...... [ERROR in 0.32s]
15:15:56
15:15:56  Finished running 1 table model in 0 hours 0 minutes and 9.36 seconds (9.36s).
15:15:56
15:15:56  Completed with 1 error, 0 partial successes, and 0 warnings:
15:15:56
15:15:56  Failure in model int_category_tree (models/silver/int_<table>.sql)
15:15:56    Compilation Error in model int_<table> (models/silver/int_<table>.sql)
            You need to have an unique table location when creating Iceberg table since we use the RENAME feature
            to have near-zero downtime.
```
