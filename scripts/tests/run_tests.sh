#!/usr/bin/env bash
set -e
echo "🧪 Running tests with coverage..."
 
# --cover flag enables cover data collection for the eunit run
rebar3 eunit --cover
 
# Generates human-readable + HTML coverage report from collected cover data
rebar3 cover --verbose
 
echo "✅ Coverage report: _build/test/cover/index.html"
