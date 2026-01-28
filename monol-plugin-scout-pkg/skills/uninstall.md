---
description: 플러그인 제거 - 설치된 플러그인을 제거합니다 (한글: 제거, 삭제, 언인스톨)
argument-hint: "<plugin-name>"
allowed-tools: [Read, Bash, AskUserQuestion]
hooks:
  Stop:
    - hooks:
        - type: command
          command: "bash ${CLAUDE_PLUGIN_ROOT}/hooks/track-usage.sh uninstall"
          timeout: 5
---

# /scout uninstall - 플러그인 제거

설치된 플러그인을 제거합니다.

## 사용법

```
/scout uninstall <plugin-name>    # 플러그인 제거
/scout remove <plugin-name>       # 별칭
```

## 인자: $ARGUMENTS

## 동작

### Phase 1: 플러그인 확인

1. **설치 여부 확인**:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/lib/plugin-manager.sh status <plugin-name>
   ```

2. **사용량 확인**:
   - usage.json에서 해당 플러그인의 사용 통계 조회
   - 최근 사용 빈도 확인

### Phase 2: 사용자 확인

AskUserQuestion으로 제거 확인:

```yaml
questions:
  - question: "<plugin-name> 플러그인을 제거하시겠습니까?"
    header: "제거 확인"
    options:
      - label: "제거"
        description: "지금 제거합니다"
      - label: "비활성화만"
        description: "제거하지 않고 비활성화만"
      - label: "취소"
        description: "제거하지 않습니다"
    multiSelect: false
```

### Phase 3: 제거 실행

사용자가 "제거"를 선택한 경우:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/lib/plugin-manager.sh uninstall <plugin-name>
```

사용자가 "비활성화만"을 선택한 경우:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/lib/plugin-manager.sh disable <plugin-name>
```

### Phase 4: 결과 안내

```markdown
## 제거 완료

**플러그인**: <plugin-name>

Claude Code를 재시작하면 완전히 제거됩니다.

### 복원하려면
```
/scout install <plugin-name>
```
```

## 예시

```
/scout uninstall old-formatter
→ old-formatter 제거

/scout remove unused-plugin
→ unused-plugin 제거
```

## 안전 규칙

1. **항상 사용자 확인 필요** - 자동 제거 금지
2. **백업 생성** - 제거 전 settings.json 백업
3. **복원 안내** - 재설치 방법 안내
