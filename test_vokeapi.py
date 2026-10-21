#!/usr/bin/env python3
"""
VokeAPI Model Test Script
Tests multiple models to find the best one for DaNang SmartTour AI.
Run: python test_vokeapi.py --key YOUR_KEY
"""

import os
import sys
import json
import time
import argparse
import requests
from typing import Dict, List, Any

# ─── Config ──────────────────────────────────────────────────────
DEFAULT_BASE_URL = "https://api.vokeapi.com/v1"
DEFAULT_MODELS = [
    "gpt-4o-mini",
    "gpt-4o",
    "gemini-2.0-flash",
    "gemini-1.5-pro",
    "claude-3.5-sonnet",
    "llama-3.1-70b",
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
    status = "✅" if result.get("success") else "❌"
    elapsed = result.get("elapsed_ms", 0)
    content = extract_content(result)
    print(f"{status} {model:20} | {test_name:15} | {elapsed:>8}ms | {content[:120]}")

def test_model(base_url: str, api_key: str, model: str) -> Dict[str, Any]:
    print(f"\n{'='*60}")
    print(f"Testing model: {model}")
    print(f"{'='*60}")
    results = {}
    for test_name, prompt in TEST_CASES.items():
        max_tokens = 800 if test_name in ("food_analysis", "structured_safety") else 100
        result = call_api(base_url, api_key, model, prompt, max_tokens)
        results[test_name] = result
        print_result(model, test_name, result)
        time.sleep(0.5)  # be nice to API
    return results

def check_rate_limits(headers: Dict) -> Dict[str, str]:
    limits = {}
    for k, v in headers.items():
        kl = k.lower()
        if "ratelimit" in kl or "rate-limit" in kl:
            limits[k] = v
    return limits

# ─── Main ────────────────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser(description="Test VokeAPI models")
    parser.add_argument("--key", required=True, help="VokeAPI key")
    parser.add_argument("--base-url", default=DEFAULT_BASE_URL, help="API base URL")
    parser.add_argument("--models", nargs="+", default=DEFAULT_MODELS, help="Models to test")
    parser.add_argument("--only", choices=list(TEST_CASES.keys()), help="Run only one test case")
    args = parser.parse_args()

    api_key = args.key
    base_url = args.base_url.rstrip("/")
    models = args.models

    print(f"🔗 Base URL: {base_url}")
    print(f"🔑 Key: {api_key[:8]}...{api_key[-4:]}")
    print(f"🤖 Models: {', '.join(models)}")
    print(f"🧪 Tests: {list(TEST_CASES.keys()) if not args.only else [args.only]}")

    all_results = {}
    for model in models:
        try:
            if args.only:
                result = call_api(base_url, api_key, model, TEST_CASES[args.only], 
                                 800 if args.only in ("food_analysis", "structured_safety") else 100)
                all_results[model] = {args.only: result}
                print_result(model, args.only, result)
                if "headers" in result:
                    print(f"   Rate limits: {check_rate_limits(result['headers'])}")
            else:
                all_results[model] = test_model(base_url, api_key, model)
        except KeyboardInterrupt:
            print("\n⏹ Interrupted")
            break
        except Exception as e:
            print(f"❌ {model}: {e}")

    # Summary
    print(f"\n{'='*60}")
    print("SUMMARY")
    print(f"{'='*60}")
    for model, results in all_results.items():
        ok = sum(1 for r in results.values() if r.get("success"))
        total = len(results)
        avg_ms = sum(r.get("elapsed_ms", 0) for r in results.values() if r.get("success")) / max(ok, 1)
        print(f"{model:20} | {ok}/{total} passed | avg {avg_ms:.0f}ms")

    # Save raw results
    out_file = "vokeapi_test_results.json"
    with open(out_file, "w") as f:
        json.dump(all_results, f, indent=2, ensure_ascii=False)
    print(f"\n💾 Raw results saved to {out_file}")

if __name__ == "__main__":
    main()