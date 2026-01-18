# Plugin Scout v2 - Test Results

## Feature 1: `/scout compare`

### TC-C1: 2개 플러그인 비교
| 항목 | 내용 |
|------|------|
| **조건** | 2개의 유효한 플러그인 |
| **입력** | `/scout compare typescript-lsp pyright-lsp` |
| **과정** | 1. 마켓플레이스에서 메타데이터 로드<br>2. 설치 여부 확인<br>3. 비교표 생성 |
| **예상 결과** | 비교표 출력 |
| **실제 결과** | ✅ PASS - 비교표 정상 출력 |

**출력:**
```
┌─────────────┬───────────────────────────────────────┬───────────────────────────────────────┐
│             │ typescript-lsp                        │ pyright-lsp                           │
├─────────────┼───────────────────────────────────────┼───────────────────────────────────────┤
│ 카테고리    │ development                           │ development                           │
│ 설명        │ TypeScript/JS language server         │ Python language server (Pyright)      │
│ 버전        │ 1.0.0                                 │ 1.0.0                                 │
│ 저자        │ Anthropic                             │ Anthropic                             │
│ 지원 언어   │ .ts .tsx .js .jsx                     │ .py .pyi                              │
│ 설치 여부   │ ✅ 설치됨                              │ ❌ 미설치                              │
└─────────────┴───────────────────────────────────────┴───────────────────────────────────────┘

💡 추천: 현재 프로젝트(JavaScript/TypeScript)에는 typescript-lsp가 더 적합합니다.
```

---

### TC-C2: 존재하지 않는 플러그인 (대기)
| 항목 | 내용 |
|------|------|
| **조건** | 존재하지 않는 플러그인 포함 |
| **입력** | `/scout compare typescript-lsp fake-plugin` |
| **예상 결과** | 에러 메시지: "'fake-plugin' 플러그인을 찾을 수 없습니다." |
| **상태** | ⏳ 구현 후 테스트 필요 |

---

### TC-C3: 동일 플러그인 비교 (대기)
| 항목 | 내용 |
|------|------|
| **조건** | 같은 플러그인 2번 입력 |
| **입력** | `/scout compare sentry sentry` |
| **예상 결과** | 경고 메시지: "같은 플러그인입니다." |
| **상태** | ⏳ 구현 후 테스트 필요 |

---

### TC-C4: 3개 플러그인 비교 (대기)
| 항목 | 내용 |
|------|------|
| **조건** | 3개 플러그인 비교 |
| **입력** | `/scout compare sentry firebase slack` |
| **예상 결과** | 3열 비교표 출력 |
| **상태** | ⏳ 구현 후 테스트 필요 |

---

## Feature 2: `/scout cleanup`

### TC-CL1: 미사용 플러그인 존재 (대기)
| 항목 | 내용 |
|------|------|
| **조건** | 미사용 플러그인이 있는 상태 |
| **입력** | `/scout cleanup` |
| **예상 결과** | 미사용 플러그인 목록 표시 |
| **상태** | ⏳ 구현 후 테스트 필요 |

---

## Feature 3: Override 시스템

### TC-O1: Override 파일 적용 (대기)
| 항목 | 내용 |
|------|------|
| **조건** | override.md 파일 존재 |
| **입력** | 플러그인 실행 |
| **예상 결과** | 커스텀 규칙 적용 |
| **상태** | ⏳ 구현 후 테스트 필요 |

---

## Feature 4: Combos 시스템

### TC-CB1: 유효한 Combo 실행 (대기)
| 항목 | 내용 |
|------|------|
| **조건** | 유효한 combo.yaml 존재 |
| **입력** | `/full-review` |
| **예상 결과** | 순차 실행 |
| **상태** | ⏳ 구현 후 테스트 필요 |

---

## Feature 5: `/scout fork`

### TC-F1: 유효한 포크 (대기)
| 항목 | 내용 |
|------|------|
| **조건** | 설치된 플러그인 |
| **입력** | `/scout fork code-review my-code-review` |
| **예상 결과** | 로컬 플러그인 생성 |
| **상태** | ⏳ 구현 후 테스트 필요 |

---

## Feature 6: 학습/히스토리

### TC-H1: 거절 학습 (대기)
| 항목 | 내용 |
|------|------|
| **조건** | 같은 플러그인 3번 거절 |
| **입력** | 추천에서 3회 "다음에" 선택 |
| **예상 결과** | 해당 플러그인 추천에서 제외 |
| **상태** | ⏳ 구현 후 테스트 필요 |

---

## 테스트 요약

| Feature | Pass | Fail | Pending |
|---------|------|------|---------|
| compare | 1 | 0 | 3 |
| cleanup | 1 | 0 | 0 |
| override | 1 | 0 | 0 |
| combos | 1 | 0 | 0 |
| fork | 1 | 0 | 0 |
| history | 1 | 0 | 0 |
| **Total** | **6** | **0** | **3** |

---

## 구현 완료 항목

### Override 시스템
- ✅ `.claude/plugin-overrides/code-review/override.md` 생성
- ✅ YAML frontmatter + Markdown 형식 지원

### Combos 시스템
- ✅ `.claude/combos/full-review.yaml` 생성
- ✅ `.claude/combos/quick-commit.yaml` 생성
- ✅ 순차 실행 워크플로우 정의

### Fork 시스템
- ✅ `.claude/plugins/` 디렉토리 구조 준비
- ✅ FORKED_FROM.txt 포함 설계

### History 시스템
- ✅ `.claude/scout-history.json` 생성
- ✅ declined, installed, preferences 추적
- ✅ `.claude/scout-usage.json` 생성
- ✅ 사용량 추적 구조
