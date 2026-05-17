"""Shared URL validation utilities with SSRF protection.

Used by fetch_page.py, analyze_landing.py, capture_screenshot.py, and
generate_image.py to validate user-supplied URLs before making HTTP requests
or launching browsers, and to sanitize exception messages before surfacing
them to the user.
"""

import ipaddress
import re
import socket
from urllib.parse import urlparse

# Sensitive substrings to redact from any error message before logging or
# returning to the caller. Catches `key=...`, `token: ...`, `secret=...`,
# `password=...`, and bare `Bearer <token>` headers regardless of case.
_SENSITIVE_PATTERN = re.compile(
    r'(key|token|secret|password)\s*[=:]\s*\S+|Bearer\s+\S+', re.IGNORECASE,
)


def sanitize_error(err: Exception) -> str:
    """Strip potential API keys / tokens / passwords from an exception message.

    Use whenever an exception's str() reaches stdout, JSON output, or a user-
    facing error field. The redaction is irreversible — the goal is to make
    the message safe to log, not to preserve the original details.

    Args:
        err: The exception to format.

    Returns:
        The exception string with sensitive substrings replaced.
    """
    msg = str(err)
    return _SENSITIVE_PATTERN.sub(
        lambda m: (m.group(1) + '=***') if m.group(1) else 'Bearer ***', msg,
    )

_BLOCKED_NETS = [
    # IPv4 private/reserved
    ipaddress.ip_network("0.0.0.0/8"),       # "this network" — aliases localhost on Linux
    ipaddress.ip_network("127.0.0.0/8"),
    ipaddress.ip_network("10.0.0.0/8"),
    ipaddress.ip_network("172.16.0.0/12"),
    ipaddress.ip_network("192.168.0.0/16"),
    ipaddress.ip_network("169.254.0.0/16"),
    ipaddress.ip_network("100.64.0.0/10"),    # CGNAT / shared address space (cloud VPCs)
    # IPv6 private/reserved
    ipaddress.ip_network("::/128"),         # unspecified address (some kernels coerce to localhost)
    ipaddress.ip_network("::1/128"),
    ipaddress.ip_network("fc00::/7"),
    ipaddress.ip_network("fe80::/10"),
    ipaddress.ip_network("::ffff:0:0/96"),  # IPv4-mapped IPv6
]


def validate_url(url: str) -> str:
    """Validate URL scheme and block private/internal IPs (SSRF protection).

    Args:
        url: The URL to validate. If no scheme, https:// is prepended.

    Returns:
        The validated URL string (with scheme).

    Raises:
        ValueError: If URL has invalid scheme, no hostname, resolves to
                    a blocked IP, or DNS resolution fails.
    """
    parsed = urlparse(url)
    if not parsed.scheme:
        url = f"https://{url}"
        parsed = urlparse(url)
    if parsed.scheme not in ("http", "https"):
        raise ValueError(f"Invalid URL scheme: {parsed.scheme}. Only http/https allowed.")
    hostname = parsed.hostname
    if not hostname:
        raise ValueError("URL has no hostname.")
    try:
        resolved = socket.getaddrinfo(hostname, None, socket.AF_UNSPEC, socket.SOCK_STREAM)
        for _, _, _, _, addr in resolved:
            ip = ipaddress.ip_address(addr[0])
            for net in _BLOCKED_NETS:
                if ip in net:
                    raise ValueError(f"URL resolves to blocked private/internal IP: {ip}")
    except socket.gaierror as exc:
        raise ValueError(f"DNS resolution failed for {hostname}: {exc}") from exc
    return url
