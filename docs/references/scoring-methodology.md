# Scoring Methodology Reference

## Detailed Formulas

### Project Match Score Calculation

```
project_match = language + framework + category + dependency + architecture

Where:
  language   = 0-30 points (exact: 30, related: 15, none: 0)
  framework  = 0-25 points (exact: 25, compatible: 15, none: 0)
  category   = 0-20 points (high: 20, medium: 10, low: 5)
  dependency = 0-15 points (no conflict: 15, minor: 5, major: 0)
  architecture = 0-10 points (excellent: 10, good: 5, poor: 0)

Total possible: 100 points
```

### Multi-Language Projects

When multiple languages are detected:

```
weighted_score = (primary_lang_score × 0.6) + (secondary_lang_score × 0.4)
```

Primary language is determined by:
1. Explicit config (package.json → JS/TS)
2. File count percentage
3. Build tool presence

### Popularity Score Normalization

GitHub stars vary widely. Use logarithmic normalization:

```
normalized_stars = min(log10(stars + 1) / log10(100000) × 100, 100)

Examples:
  10 stars      → 25 points
  100 stars     → 50 points
  1,000 stars   → 75 points
  10,000 stars  → 100 points
```

### Commit Freshness

```
freshness_score = max(0, 100 - (days_since_update × 0.27))

Examples:
  1 day ago    → 100 points
  30 days ago  → 92 points
  180 days ago → 51 points
  365 days ago → 1 point
```

### Composite Score

```
composite = (project_match × 0.40) + (popularity × 0.30) + (security × 0.30)
```

### Edge Cases

| Scenario | Handling |
|----------|----------|
| No GitHub data | Use default popularity = 50 |
| Unknown license | Security license score = 0 |
| No recent commits | Commits score = 5 (minimum) |
| Fork of popular repo | Use original repo's stats |
| Archived repository | Reduce popularity by 50% |
