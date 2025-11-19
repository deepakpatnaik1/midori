#!/bin/bash

# Simple test runner for Midori
# Runs unit tests using Swift compiler

set -e

cd "$(dirname "$0")/.."

echo "🧪 Running Midori Tests..."
echo ""

# Compile and run tests
swift test --package-path .

echo ""
echo "✅ All tests passed!"
