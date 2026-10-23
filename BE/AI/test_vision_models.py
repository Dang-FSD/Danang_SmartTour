import requests
import json
import time
import os

DEFAULT_BASE_URL = os.getenv("VOKE_BASE_URL", "https://api.vokeapi.com/v1")
DEFAULT_API_KEY = os.getenv("VOKE_API_KEY", "")
img_b64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="

candidate_models = [
    "gemini-3.8-flash",
    "gemini-3.1-pro",
    "deepseek-v4-pro",
    "step-5-preview",
    "qwen3.8-flash",
]

print("-" * 65)
print(f"{'Model':<24} | {'Status':<6} | {'Time':<6} | {'Vision Response'}")
print("-" * 65)

for m in candidate_models:
    start = time.time()
    try:
        r = requests.post(
            f"{DEFAULT_BASE_URL}/chat/completions",
            headers={"Authorization": f"Bearer {DEFAULT_API_KEY}", "Content-Type": "application/json"},
            json={
                "model": m,
                "messages": [{
                    "role": "user",
                    "content": [
                        {"type": "text", "text": "What color is this single pixel image? Answer in 3 words."},
                        {"type": "image_url", "image_url": {"url": f"data:image/png;base64,{img_b64}"}}
                    ]
                }],
                "max_tokens": 50
            },
            timeout=15
        )
        elapsed = round(time.time() - start, 2)
        if r.status_code == 200:
            msg = r.json().get("choices", [{}])[0].get("message", {}).get("content", "").replace("\n", " ").strip()
            print(f"{m:<24} | {r.status_code:<6} | {elapsed}s | {msg[:35]}")
        else:
            print(f"{m:<24} | {r.status_code:<6} | {elapsed}s | Error: {r.text[:35]}")
    except Exception as e:
        print(f"{m:<24} | ERR    | ---   | {e}")
