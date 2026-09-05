# Security Policy

## Supported Versions

| Version | Supported |
| ------- | --------- |
| 1.x     | ✅ |
| < 1.0   | ❌ |

## Reporting a Vulnerability

**Do NOT report security vulnerabilities through public GitHub issues.**

### GitHub Security Advisories (Preferred)

1. Go to the [Security tab](https://github.com/seyed/erl_data_shift/security/advisories)
2. Click **"Report a vulnerability"**
3. Fill out the advisory form

This creates a private discussion visible only to maintainers.

### Email

Send an email to `seyed@swiftter.com` with:

- **Subject**: `[SECURITY] Brief description`
- **Affected versions**
- **Reproduction steps**
- **Impact assessment** (e.g. data exposure, integrity compromise, PII leak)
- **Suggested fix** (optional)

## Response Timeline

| Severity | Acknowledged | Patched |
|----------|-------------|---------|
| Critical | 24 hours | 7 days |
| High | 48 hours | 14 days |
| Medium | 1 week | 30 days |
| Low | 2 weeks | 90 days |

These are targets, not guarantees.

## Disclosure Policy

- **Coordinated disclosure** – we agree on a timeline before making anything public. 
- **Credit** – reporters are credited in release notes and advisories (anonymity respected on request). 
- **CVE** – we request a CVE for all verified vulnerabilities. 

## Data-Specific Considerations

This project handles data. When reporting, please note:

- Whether the vulnerability could expose **PII or sensitive records**
- Whether **data integrity** (corruption, silent mutation, injection) is at risk
- Whether the issue affects **data in transit** vs **data at rest**

## Bug Bounty

We do not currently offer a bug bounty program. Security reports are greatly appreciated and will be credited.   
