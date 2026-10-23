#!/usr/bin/env python3
"""
VokeAPI Model Test Script
Tests multiple models to find the best one for DaNang SmartTour AI.
Only uses officially available models on VokeAPI.
Run: python test_vokeapi.py --key YOUR_KEY
"""

import os
import sys
import json
import time
import argparse
import requests
from typing import Dict, List, Any

# Import official VokeAPI active models catalog
try:
    from voke_models import VOKE_ACTIVE_MODELS, VALID_MODEL_IDS
except ImportError:
    from BE.AI.voke_models import VOKE_ACTIVE_MODELS, VALID_MODEL_IDS

# ─── Config ──────────────────────────────────────────────────────
DEFAULT_BASE_URL = os.getenv("VOKE_BASE_URL", "https://api.vokeapi.com/v1")
DEFAULT_API_KEY = os.getenv("VOKE_API_KEY", "sk-voke-8TdlVJrLc63ThIiCcffFMFWfh0u6kaXrEZtZoG0XjMoOZjNm")

# Top Flagship Models from VokeAPI
DEFAULT_MODELS = [
    "deepseek-v4-pro",
    "gemini-3.8-flash",
    "gemini-3.1-pro",
    "gemini-3.5-flash-lite-thinking",
    "step-5-preview",
    "deepseek-v4.1-flash",
    "laguna-s-2.1",
    "grok-4.7",
]
TIMEOUT = 30

# Test prompts for different use cases
TEST_CASES = {
    "simple": "Reply with only: OK",
    "json_output": 'Return JSON: {"status": "ok", "model": "your_model_name"}',
    "food_analysis": "Analyze: 'Bún chả cá Đà Nẵng'. List hidden ingredients (pork broth, peanuts, fish sauce). Return JSON only.",
    "structured_safety": """You are a food safety analyzer. Input: "Mì Quảng gà". Output JSON:
{
  "dish": "Mì Quảng gà",
  "hidden_ingredients": ["chicken broth", "peanut oil", "fish sauce", "peanuts"],
  "allergen_flags": {"peanut": true, "fish": true, "pork": false},
  "dietary_verdict": {"halal": false, "vegetarian": false, "pescatarian": true},
  "safety_level": "YELLOW",
  "chef_note": "Remove peanuts, use separate oil"
}""",
}

# ─── Helpers ─────────────────────────────────────────────────────
def call_api(base_url: str, api_key: str, model: str, prompt: str, max_tokens: int = 500) -> Dict[str, Any]:
    url = f"{base_url}/chat/completions"
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }
    payload = {
        "model": model,
        "messages": [{"role": "user", "content": prompt}],
        "max_tokens": max_tokens,
        "temperature": 0.1,
    }
    start = time.time()
    try:
        resp = requests.post(url, headers=headers, json=payload, timeout=TIMEOUT)
        elapsed = time.time() - start
        return {
            "success": resp.status_code == 200,
            "status_code": resp.status_code,
            "elapsed_ms": round(elapsed * 1000, 2),
            "response": resp.json() if resp.status_code == 200 else resp.text,
            "headers": dict(resp.headers),
        }
    except requests.exceptions.Timeout:
        return {"success": False, "error": "timeout", "elapsed_ms": round((time.time() - start) * 1000, 2)}
    except Exception as e:
        return {"success": False, "error": str(e), "elapsed_ms": round((time.time() - start) * 1000, 2)}

def extract_content(result: Dict) -> str:
    if not result.get("success"):
        return f"ERROR: {result.get('error', 'unknown')}"
    try:
        return result["response"]["choices"][0]["message"]["content"].strip()
    except Exception:
        return str(result["response"])

def print_result(model: str, test_name: str, result: Dict):
    status = "[OK]" if result.get("success") else "[ERR]"
    elapsed = result.get("elapsed_ms", 0)
    content = extract_content(result).replace("\n", " ")
    print(f"{status} {model:30} | {test_name:18} | {elapsed:>8}ms | {content[:80]}")

def test_model(base_url: str, api_key: str, model: str) -> Dict[str, Any]:
    meta = VOKE_ACTIVE_MODELS.get(model, {})
    disp = meta.get("display_name", model)
    print(f"\n{'='*70}")
    print(f"Testing Model: {disp}")
    print(f"{'='*70}")
    results = {}
    for test_name, prompt in TEST_CASES.items():
        max_tokens = 800 if test_name in ("food_analysis", "structured_safety") else 100
        result = call_api(base_url, api_key, model, prompt, max_tokens)
        results[test_name] = result
        print_result(model, test_name, result)
        time.sleep(0.3)
    return results

def main():
    parser = argparse.ArgumentParser(description="Test VokeAPI Verified Active Models")
    parser.add_argument("--key", default=DEFAULT_API_KEY, help="VokeAPI key")
    parser.add_argument("--base-url", default=DEFAULT_BASE_URL, help="API base URL")
    parser.add_argument("--models", nargs="+", default=DEFAULT_MODELS, help="Models to test")
    parser.add_argument("--all", action="store_true", help="Test ALL 19 active VokeAPI models")
    parser.add_argument("--only", choices=list(TEST_CASES.keys()), help="Run only one test case")
    args = parser.parse_args()

    api_key = args.key
    if not api_key:
        print("[ERR] No API key provided.")
        sys.exit(1)
    base_url = args.base_url.rstrip("/")
    models = VALID_MODEL_IDS if args.all else args.models

    invalid = [m for m in models if m not in VALID_MODEL_IDS]
    if invalid:
        print(f"[ERR] These models are NOT provided by VokeAPI: {invalid}")
        print(f"[INFO] Allowed VokeAPI models: {', '.join(VALID_MODEL_IDS)}")
        sys.exit(1)

    print(f"[LINK] Base URL: {base_url}")
    print(f"[BOT] Target Models ({len(models)}): {', '.join(models)}")

    all_results = {}
    for model in models:
        try:
            if args.only:
                result = call_api(base_url, api_key, model, TEST_CASES[args.only], 
                                 800 if args.only in ("food_analysis", "structured_safety") else 100)
                all_results[model] = {args.only: result}
                print_result(model, args.only, result)
            else:
                all_results[model] = test_model(base_url, api_key, model)
        except KeyboardInterrupt:
            break
        except Exception as e:
            print(f"[ERR] {model}: {e}")

    print(f"\n{'='*70}")
    print("VOKEAPI BENCHMARK SUMMARY")
    print(f"{'='*70}")
    for model, results in all_results.items():
        ok = sum(1 for r in results.values() if r.get("success"))
        total = len(results)
        avg_ms = sum(r.get("elapsed_ms", 0) for r in results.values() if r.get("success")) / max(ok, 1)
        tag = "[PASS]" if ok == total else "[PARTIAL/FAIL]"
        print(f"{tag:<14} {model:30} | {ok}/{total} passed | avg {avg_ms:6.0f}ms")

if __name__ == "__main__":
    main()