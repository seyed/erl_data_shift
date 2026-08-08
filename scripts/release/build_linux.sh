#!/usr/bin/env bash
set -e
echo "🐳 Building Linux binary inside Docker..."

# Run the build inside a standard Erlang container
docker run --rm \
  -v "$(pwd)":/app \
  -w /app \
  erlang:27-alpine \
  sh -c "apk add --no-cache git make gcc musl-dev && rebar3 as prod release"

echo "✅ Linux binary ready at: _build/prod/rel/erl_data_shift/bin/erl_data_shift"

# --- Package as a single self-extracting file -------------------------------
# Same approach as build_mac.sh: wrap the release dir (ERTS + bytecode) into
# one executable — a shell stub with an appended tar.gz. On first run it
# extracts to a per-version cache dir; later runs reuse that cache if present.
echo "📦 Packaging self-extracting single-file binary..."

RELEASE_DIR="_build/prod/rel/erl_data_shift"
# Pull version straight from rebar.config's {release, {erl_data_shift, "X.Y.Z"}, ...}
# so it never drifts out of sync with the actual build.
VERSION=$(grep -o '{release, {erl_data_shift, "[^"]*"' rebar.config | sed 's/.*"\(.*\)"/\1/')
OUT_DIR="_build/prod/bin"
OUT_FILE="${OUT_DIR}/erl_data_shift"
TARBALL="_build/prod/erl_data_shift-release.tar.gz"

mkdir -p "$OUT_DIR"
tar -C "_build/prod/rel" -czf "$TARBALL" erl_data_shift

# Shell stub: finds its own EOF marker, extracts the appended tarball to a
# per-version cache dir (skips extraction if already cached), then execs.
cat > "$OUT_FILE" <<STUB
#!/usr/bin/env bash
set -e
CACHE_DIR="\${HOME}/.cache/erl_data_shift/${VERSION}"
if [ ! -x "\${CACHE_DIR}/bin/erl_data_shift" ]; then
    mkdir -p "\${CACHE_DIR}"
    ARCHIVE_LINE=\$(awk '/__ARCHIVE_BELOW__\$/{print NR + 1; exit 0;}' "\$0")
    tail -n +"\${ARCHIVE_LINE}" "\$0" | tar -xz -C "\${CACHE_DIR}" --strip-components=1
fi
exec "\${CACHE_DIR}/bin/erl_data_shift" "\$@"
exit 0
__ARCHIVE_BELOW__
STUB

cat "$TARBALL" >> "$OUT_FILE"
chmod +x "$OUT_FILE"
rm -f "$TARBALL"

echo "✅ Single-file binary ready at: ${OUT_FILE}"