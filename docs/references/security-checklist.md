# Plugin Security Checklist

## Pre-Installation Review

### Source Verification
- [ ] Plugin source is from known marketplace
- [ ] Repository URL is accessible and valid
- [ ] Author/organization can be verified
- [ ] No typosquatting in name (e.g., "typescrit-lsp")

### License Review
- [ ] License file is present
- [ ] License is OSI-approved
- [ ] License is compatible with project
- [ ] No unusual restrictions or obligations

### Maintenance Status
- [ ] Active development (commits in last year)
- [ ] Issues are being addressed
- [ ] Security issues get prompt response
- [ ] Reasonable open/closed issue ratio

### Author Trust
- [ ] Author has other reputable projects
- [ ] Organization is verified (if applicable)
- [ ] No history of malicious packages

---

## Red Flags

### Immediate Rejection
- Unknown or missing license
- Obfuscated code
- Requests excessive permissions
- Known critical vulnerabilities
- Author cannot be verified
- Typosquatting on popular plugin names

### Proceed with Caution
- Last update > 1 year ago
- No issue response
- GPL license (copyleft implications)
- New/unknown author
- Very few stars or forks
- No documentation

---

## Security Warning Triggers

| Condition | Warning Level |
|-----------|---------------|
| License unknown | Critical |
| Critical vulnerability | Critical |
| Author unknown | Critical |
| Last update > 2 years | Critical |
| License restrictive | Moderate |
| Minor vulnerability | Moderate |
| New author | Moderate |
| Last update > 1 year | Moderate |
| Community-managed | Informational |
| Attribution required | Informational |
| Beta/experimental | Informational |

---

## Warning Message Templates

### Critical Warning
```
⚠️ CRITICAL: [plugin-name]
- [Issue description]
- Installation NOT recommended
- Risk: [specific risk]
```

### Moderate Warning
```
⚠️ Warning: [plugin-name]
- [Issue description]
- Proceed with caution
- Consider: [alternative or mitigation]
```

### Informational Notice
```
ℹ️ Notice: [plugin-name]
- [Information]
- No action required
```
