# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability, please report it responsibly via the **private GitHub Security Advisory channel**:

1. **Do NOT open a public issue** (public issues expose the vulnerability before it can be patched).
2. Open a [GitHub Security Advisory](https://github.com/AgriciDaniel/claude-ads/security/advisories/new) on this repo. This is the only supported private disclosure channel — do not email or DM.
3. Include: affected version (e.g. v1.5.1), reproduction steps, and impact assessment.

We aim to acknowledge reports within **48 hours** and provide an estimated resolution timeline within **7 days**.

## Supported Versions

Only the latest version receives security updates.

## Security Practices

- No credentials or API keys are stored in this repository
- Install scripts write only to user-level directories (`~/.claude/`, `~/.codex/`, `~/.cursor/`, etc. per `--target`)
- Python dependencies install in isolated virtual environments
- Shared SSRF validation module (`scripts/url_utils.py`) gates every user-supplied URL — IPv4 RFC1918 / loopback / link-local / CGNAT and IPv6 unspecified / loopback / ULA / link-local / IPv4-mapped are all blocked, with fail-closed DNS resolution
- Error messages are scrubbed via `sanitize_error()` before reaching stdout, JSON output, or audit reports — strips `key=`, `token=`, `secret=`, `password=`, and bare `Bearer <token>` substrings
- GitHub Actions are pinned to full commit SHAs; Dependabot auto-merge is restricted to patch updates only
- `pip-audit` runs on every CI build and fails on any reported vulnerability (no severity threshold — strictest policy)

## Outbound Network Destinations

The following endpoints may be contacted at runtime. All user-supplied URLs pass through the SSRF blocklist before any fetch is attempted; trusted vendor endpoints are hardcoded and not user-influenceable.

| Endpoint | Purpose | Script | Gated by |
|----------|---------|--------|----------|
| `generativelanguage.googleapis.com` | Gemini image generation (fallback path) | `generate_image.py` | API key (env var) |
| `api.openai.com` | OpenAI image generation (fallback path) | `generate_image.py` | API key (env var) |
| `api.stability.ai` | Stability AI image generation (fallback path) | `generate_image.py` | API key (env var) |
| `api.replicate.com` | Replicate model invocation (fallback path) | `generate_image.py` | API key (env var) |
| Replicate-returned result URL | Fetch generated image bytes | `generate_image.py` | HTTPS check + SSRF revalidation via `url_utils.validate_url` (v1.7.0+) |
| User-supplied URLs | Landing page analysis, screenshot capture, page fetch | `analyze_landing.py`, `capture_screenshot.py`, `fetch_page.py` | SSRF blocklist via `url_utils.validate_url` |
| `github.com` (read-only, via git clone) | Skill installation | `install.sh`, `install.ps1` | Hardcoded repo URL |
| PyPI (`pypi.org`, `files.pythonhosted.org`) | Python dependency install | `install.sh`, `install.ps1` | Hardcoded; trusted by `pip` |

If you discover any other outbound destination not listed above, please report it via the disclosure channel above.
