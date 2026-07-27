#!/usr/bin/env python3
"""Print the user/assistant thread of one session. Usage: read_session.py SESSION.jsonl"""
import json, sys

with open(sys.argv[1]) as f:
    for line in f:
        try:
            d = json.loads(line)
        except Exception:
            continue
        t = d.get("type")
        if t not in ("user", "assistant"):
            continue
        content = d.get("message", {}).get("content", "")
        text = ""
        if isinstance(content, str):
            text = content
        elif isinstance(content, list):
            for block in content:
                if isinstance(block, dict) and block.get("type") == "text":
                    text += block.get("text", "") + "\n"
        if text.strip():
            role = "USER" if t == "user" else "ASSISTANT"
            ts = d.get("timestamp", "")[:16]
            print(f"\n--- {role} [{ts}] ---")
            print(text[:800])
            if len(text) > 800:
                print(f"[...{len(text)-800} more chars]")
