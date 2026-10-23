import requests
import json
import time
import os

DEFAULT_BASE_URL = os.getenv("VOKE_BASE_URL", "https://api.vokeapi.com/v1")
DEFAULT_API_KEY = os.getenv("VOKE_API_KEY", "")

# Query all available models
r = requests.get(f"{DEFAULT_BASE_URL}/models", headers={"Authorization": f"Bearer {DEFAULT_API_KEY}"})
data = r.json()
active_models = [m["id"] for m in data.get("data", [])]

print(f"Total Active Models on VokeAPI: {len(active_models)}")

test_models = [
    "gemini-3.8-flash",
    "gemini-3.1-pro",
    "gemini-3.5-flash-lite-thinking",
    "gpt-6-luna",
    "deepseek-v4-pro",
    "deepseek-v4.1-flash",
    "grok-4.7",
    "grok-4.6-fast",
    "step-5-preview",
    "qwen3.8-flash",
    "mimo-v2.6-flash",
    "nemotron-3-ultra-550b-a55b",
    "laguna-s-2.1"
]

print("-" * 75)
print(f"{'Model ID':<32} | {'Status':<8} | {'Latency':<8} | {'Response Preview'}")
print("-" * 75)

for m in test_models:
    start = time.time()
    try:
        resp = requests.post(
            f"{DEFAULT_BASE_URL}/chat/completions",
            headers={"Authorization": f"Bearer {DEFAULT_API_KEY}", "Content-Type": "application/json"},
            json={
                "model": m,
                "messages": [{"role": "user", "content": 'Return JSON only: {"status": "ok"}'}],
                "max_tokens": 80,
                "temperature": 0.1,
            },
            timeout=15,
        )
        elapsed = round(time.time() - start, 2)
        if resp.status_code == 200:
            content = resp.json().get("choices", [{}])[0].get("message", {}).get("content", "").replace("\n", " ").strip()
            print(f"{m:<32} | {resp.status_code:<8} | {elapsed}s    | {content[:45]}")
        else:
            print(f"{m:<32} | {resp.status_code:<8} | {elapsed}s    | Error: {resp.text[:45]}")
    except Exception as e:
        print(f"{m:<32} | ERR      | ---      | {e}")
