#!/usr/bin/env bash
set -e

echo "🐳 Building Linux binary inside Docker..."

# Run the build inside a standard Erlang container
docker run --rm \
  -v "$(pwd)":/app \
  -w /app \
  erlang:27-alpine \
  sh -c "apk add --no-cache git make gcc musl-dev && rebar3 as prod release"

# Extract the binary from the build folder
# The binary is now available at: _build/prod/rel/erl_data_shift/bin/erl_data_shift
echo "✅ Linux binary ready at: _build/prod/rel/erl_data_shift/bin/erl_data_shift"   
