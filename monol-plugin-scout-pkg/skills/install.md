---
description: 플러그인 설치 - 추천된 플러그인을 설치합니다 (한글: 설치, 플러그인설치)
argument-hint: "<plugin-name[@marketplace]>"
allowed-tools: [Read, Bash, AskUserQuestion]
hooks:
  Stop:
    - hooks:
        - type: command
          command: "bash ${CLAUDE_PLUGIN_ROOT}/hooks/track-usage.sh install"
          timeout: 5
---

# /scout install - 플러그인 설치

추천된 플러그인을 설치합니다.

## 사용법

```
/scout install <plugin-name>                    # 기본 설치
/scout install <plugin-name>@<marketplace>      # 마켓플레이스 지정
/scout install --list                           # 설치된 플러그인 목록
```

## 인자: $ARGUMENTS

## 동작

### Phase 1: 설치 전 확인

1. **플러그인 존재 확인**:
   - 마켓플레이스에서 플러그인 검색
   - 이미 설치되어 있는지 확인

2. **거절 이력 확인**:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/lib/rejection-learner.sh check <plugin-name>
   ```

3. **보안 점검**:
   - 라이선스 확인
   - 저자 신뢰도 확인
   - 알려진 취약점 확인

### Phase 2: 사용자 확인

AskUserQuestion으로 설치 확인:

```yaml
questions:
  - question: "<plugin-name> 플러그인을 설치하시겠습니까?"
    header: "설치 확인"
    options:
      - label: "설치"
        description: "지금 설치합니다"
      - label: "취소"
        description: "설치하지 않습니다"
      - label: "나중에"
        description: "30일 후 다시 추천받습니다"
    multiSelect: false
```

### Phase 3: 설치 실행

사용자가 "설치"를 선택한 경우:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/lib/plugin-manager.sh install <plugin-name>[@marketplace] recommendation
```

### Phase 4: 결과 안내

설치 완료 후 메시지:

```markdown
## 설치 완료

**플러그인**: <plugin-name>
**마켓플레이스**: <marketplace>

Claude Code를 재시작하면 플러그인이 활성화됩니다.

### 사용법
- 해당 플러그인의 명령어와 기능을 안내
```

### Phase 5: 거절 시 기록

사용자가 "취소" 또는 "나중에"를 선택한 경우:

```bash
# 취소 선택 시
bash ${CLAUDE_PLUGIN_ROOT}/lib/rejection-learner.sh record <plugin-name> "not-relevant" <category>

# 나중에 선택 시
bash ${CLAUDE_PLUGIN_ROOT}/lib/rejection-learner.sh record <plugin-name> "later" <category>
```

## 거절 이유 코드

| 코드 | 의미 |
|------|------|
| not-relevant | 프로젝트와 관련 없음 |
| wrong-language | 사용하지 않는 언어 |
| already-have | 유사한 플러그인 이미 있음 |
| too-complex | 너무 복잡함 |
| not-trusted | 신뢰할 수 없음 |
| later | 나중에 설치 |

## 예시

```
/scout install typescript-lsp
→ typescript-lsp 설치

/scout install code-review@monol
→ monol 마켓플레이스에서 code-review 설치

/scout install --list
→ 설치된 플러그인 목록 표시
```

## 안전 규칙

1. **항상 사용자 확인 필요** - 자동 설치 금지
2. **백업 생성** - 설치 전 settings.json 백업
3. **롤백 지원** - 문제 시 복원 가능
