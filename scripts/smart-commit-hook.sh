#!/usr/bin/env bash

# Git이 전달하는 인자
COMMIT_MSG_FILE="$1"
COMMIT_SOURCE="$2"
SHA1="$3"

# 1. 예외 처리: Merge, Amend, 혹은 이미 메시지가 있는 경우 건너뜀
if [[ "$COMMIT_SOURCE" = "merge" ]] || [[ "$COMMIT_SOURCE" = "commit" ]]; then
    exit 0
fi

# 2. OpenCommit 설치 확인
if ! command -v oco &> /dev/null; then
    echo "OpenCommit이 설치되지 않아 AI 메시지 생성을 건너뜁니다."
    exit 0
fi

# 3. 현재 브랜치 정보
current_branch=$(git branch --show-current)
echo "AI가 커밋 메시지를 작성 중입니다..."

# 4. AI 메시지 생성 및 파싱
RAW_OUTPUT=$(CI=1 oco --fg 2>&1 || true)

GENERATED_MSG=$(echo "$RAW_OUTPUT" | awk '/^——————————————————$/ {if (p) exit; p=1; next} p')
if [[ -z "$GENERATED_MSG" ]]; then
    GENERATED_MSG=$(echo "$RAW_OUTPUT" | grep -E '^(feat|fix|docs|style|refactor|perf|test|chore|revert|build|ci)(\(.*\))?:' | head -n 1)
fi

# 접두어(feat:) 제거
if [[ -n "$GENERATED_MSG" ]]; then
    CLEAN_MSG=$(echo "$GENERATED_MSG" | sed -E 's/^(feat|fix|docs|style|refactor|perf|test|chore|revert|build|ci)(\(.*\))?:\s*//')
    if [[ ${#CLEAN_MSG} -gt 0 ]]; then
        GENERATED_MSG="$CLEAN_MSG"
    fi
fi

if [[ -z "$GENERATED_MSG" ]]; then
    echo "메시지 생성 실패. 기본 에디터를 엽니다."
    exit 0
fi

# 5. 브랜치별 메시지 가공
if [[ "$current_branch" = "main" ]]; then
    LAST_COMMIT_MSG=$(git log -1 --pretty=%B)

    if [[ $LAST_COMMIT_MSG =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
        major=${BASH_REMATCH[1]}
        minor=${BASH_REMATCH[2]}
        patch=${BASH_REMATCH[3]}

        if [[ $patch -ge 100 ]]; then
            new_minor=$((minor + 1))
            new_patch=1
            new_version="v${major}.${new_minor}.${new_patch}"
        else
            new_patch=$((patch + 1))
            new_version="v${major}.${minor}.${new_patch}"
        fi
    else
        new_version="v0.0.1"
    fi

    FINAL_MSG="#$new_version: $GENERATED_MSG"
else
    FINAL_MSG="#$current_branch: $GENERATED_MSG"
fi

# 6. 결과 파일 작성
TEMP_FILE=$(mktemp)
echo "$FINAL_MSG" > "$TEMP_FILE"
echo "" >> "$TEMP_FILE"
cat "$COMMIT_MSG_FILE" >> "$TEMP_FILE"
mv "$TEMP_FILE" "$COMMIT_MSG_FILE"
