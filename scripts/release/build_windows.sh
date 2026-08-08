#!/usr/bin/env bash
set -e

echo "🪟 Windows Build:"
echo "   Cross-compiling Erlang releases to Windows from macOS is not supported."
echo "   Please use the CI pipeline (GitHub Actions) to generate the Windows binary."
echo "   Or run this script on a Windows machine with Erlang installed."

# If running ON Windows (via Git Bash):
if [[ "$OSTYPE" == "msys" ]]; then
    rebar3 as prod release
    echo "✅ Windows binary ready."
fi   
