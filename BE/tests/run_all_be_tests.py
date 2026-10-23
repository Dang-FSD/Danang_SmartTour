#!/usr/bin/env python3
"""
DaNang SmartTour AI — Master Backend Test Runner
Discovers and executes all backend test suites with structured reporting.
Usage: python tests/run_all_be_tests.py
"""

import sys
import os
import unittest
import time

# Force UTF-8 encoding for Windows terminals
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

# Ensure project root (parent of tests) is on sys.path
be_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
workspace_root = os.path.abspath(os.path.join(be_root, ".."))

if be_root not in sys.path:
    sys.path.insert(0, be_root)
if workspace_root not in sys.path:
    sys.path.insert(0, workspace_root)


def main():
    print("=" * 70)
    print("DaNang SmartTour AI - Backend Test Runner (Python 3)")
    print("=" * 70)

    loader = unittest.TestLoader()
    start_dir = os.path.dirname(__file__)
    suite = loader.discover(start_dir, pattern="test_*.py")

    start_time = time.time()
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    elapsed = time.time() - start_time

    print("\n" + "=" * 70)
    print("Backend Test Execution Summary:")
    print(f"   * Total Tests Run: {result.testsRun}")
    print(f"   * Failures: {len(result.failures)}")
    print(f"   * Errors: {len(result.errors)}")
    print(f"   * Duration: {elapsed:.2f} seconds")
    print("=" * 70)

    if result.wasSuccessful():
        print("ALL BACKEND TESTS PASSED (100% Zero False-Safety Verified)")
        sys.exit(0)
    else:
        print("SOME BACKEND TESTS FAILED")
        sys.exit(1)


if __name__ == "__main__":
    main()
