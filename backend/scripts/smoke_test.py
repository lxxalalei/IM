from __future__ import annotations

import json
import sys
from datetime import datetime
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import ProxyHandler, Request, build_opener

BASE_URL = "http://127.0.0.1:8000"
OPENER = build_opener(ProxyHandler({}))


def main() -> int:
    try:
        assert get_json("/health") == {"status": "ok"}

        conversations = get_json("/api/conversations")["items"]
        assert conversations, "Expected seeded conversations"

        search = get_json("/api/conversations", {"q": "千里马"})["items"]
        assert search, "Expected search results for 千里马"
        assert search[0]["id"] == "qianli"

        contacts = get_json("/api/contacts")["items"]
        assert contacts, "Expected seeded contacts"

        contact_search = get_json("/api/contacts", {"q": "Flutter"})["items"]
        assert contact_search, "Expected contact search results for Flutter"
        assert contact_search[0]["id"] == "u_xiaoyu"

        messages_before = get_json("/api/conversations/qianli/messages")["items"]
        payload = {
            "content": f"smoke test {datetime.now().isoformat(timespec='seconds')}",
        }
        created = post_json("/api/conversations/qianli/messages", payload)
        assert created["content"] == payload["content"]
        assert created["isMine"] is True

        messages_after = get_json("/api/conversations/qianli/messages")["items"]
        assert len(messages_after) == len(messages_before) + 1

        patch("/api/conversations/qianli/read")
    except (AssertionError, HTTPError, URLError) as error:
        print(f"Smoke test failed: {error}", file=sys.stderr)
        return 1

    print("Backend smoke test passed")
    return 0


def get_json(path: str, query: dict[str, str] | None = None) -> dict:
    url = f"{BASE_URL}{path}"
    if query:
        url = f"{url}?{urlencode(query)}"
    with OPENER.open(url, timeout=5) as response:
        return json.loads(response.read().decode("utf-8"))


def post_json(path: str, payload: dict[str, str]) -> dict:
    request = Request(
        f"{BASE_URL}{path}",
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with OPENER.open(request, timeout=5) as response:
        return json.loads(response.read().decode("utf-8"))


def patch(path: str) -> None:
    request = Request(f"{BASE_URL}{path}", method="PATCH")
    with OPENER.open(request, timeout=5):
        return


if __name__ == "__main__":
    raise SystemExit(main())
