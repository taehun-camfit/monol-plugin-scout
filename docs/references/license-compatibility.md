# License Compatibility Matrix

## Permissive Licenses (Recommended)

| License | Commercial | Modification | Distribution | Private |
|---------|------------|--------------|--------------|---------|
| MIT | Yes | Yes | Yes | Yes |
| Apache-2.0 | Yes | Yes | Yes | Yes |
| BSD-2-Clause | Yes | Yes | Yes | Yes |
| BSD-3-Clause | Yes | Yes | Yes | Yes |
| ISC | Yes | Yes | Yes | Yes |

**Requirements**: Attribution in documentation/source

---

## Copyleft Licenses (Caution)

| License | Commercial | Modification | Copyleft |
|---------|------------|--------------|----------|
| GPL-3.0 | Yes* | Yes* | Strong |
| GPL-2.0 | Yes* | Yes* | Strong |
| LGPL-3.0 | Yes | Yes* | Weak |
| MPL-2.0 | Yes | Yes* | Weak |

*Derivative works must use same license

---

## Compatibility with Project Licenses

### If your project uses MIT/Apache-2.0:
- **Permissive**: Full compatibility
- **LGPL**: Compatible (for linking)
- **GPL**: May require project relicensing

### If your project uses GPL:
- **All open source**: Compatible
- **Proprietary plugins**: Not compatible

---

## Recommendations

| Project Type | Recommended Plugin Licenses |
|--------------|----------------------------|
| Commercial/Enterprise | MIT, Apache-2.0, BSD |
| Open Source | Any OSI-approved |
| Internal Tools | MIT, Apache-2.0, LGPL |

---

## Unknown License Handling

1. Check for LICENSE file in repository
2. Check package.json/Cargo.toml for license field
3. Contact author for clarification
4. **If unclear**: Avoid installation
