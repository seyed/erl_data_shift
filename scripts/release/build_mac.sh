#!/usr/bin/env bash
set -e
echo "🍎 Building macOS binary natively..."

KERL_VERSION="27.1.2"
KERL_DIR="$HOME/.kerl"
KERL_BIN="$KERL_DIR/kerl"
KERL_INSTALL_DIR="$HOME/erlang-${KERL_VERSION}"

# Helper: does the currently active `erl` have a working crypto app?
has_crypto() {
    command -v erl &> /dev/null && \
    erl -noshell -eval 'case code:lib_dir(crypto) of {error,_} -> halt(1); _ -> halt(0) end.' &> /dev/null
}

# If system Erlang is missing or lacks crypto, build one with kerl (no brew)
if ! has_crypto; then
    echo "⚠️  No working Erlang+crypto found. Bootstrapping via kerl (no Homebrew)..."

    # Install kerl itself if not already present
    mkdir -p "$KERL_DIR"
    if [ ! -x "$KERL_BIN" ]; then
        curl -sL -o "$KERL_BIN" https://raw.githubusercontent.com/kerl/kerl/master/kerl
        chmod +x "$KERL_BIN"
    fi

    # macOS's SDK does NOT ship OpenSSL headers, so build OpenSSL from source (no brew)
    OPENSSL_VERSION="3.3.2"
    OPENSSL_PREFIX="$HOME/.kerl/openssl-${OPENSSL_VERSION}"
    if [ ! -d "$OPENSSL_PREFIX" ]; then
        echo "🔧 Building OpenSSL ${OPENSSL_VERSION} from source (one-time, no brew)..."
        TMP_SSL_DIR=$(mktemp -d)
        curl -sL "https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz" \
            -o "$TMP_SSL_DIR/openssl.tar.gz"
        tar -xzf "$TMP_SSL_DIR/openssl.tar.gz" -C "$TMP_SSL_DIR"
        (
            cd "$TMP_SSL_DIR/openssl-${OPENSSL_VERSION}"
            OSSL_TARGET="darwin64-arm64-cc"
            [ "$(uname -m)" = "x86_64" ] && OSSL_TARGET="darwin64-x86_64-cc"
            ./Configure "$OSSL_TARGET" --prefix="$OPENSSL_PREFIX" no-shared
            make -j"$(sysctl -n hw.ncpu)"
            make install_sw   # skip docs, faster
        )
        rm -rf "$TMP_SSL_DIR"
    fi

    # Point kerl at our self-built OpenSSL so crypto compiles correctly
    export KERL_CONFIGURE_OPTIONS="--with-ssl=${OPENSSL_PREFIX}"

    # Build + install the OTP version only if not already installed
    if [ ! -d "$KERL_INSTALL_DIR" ]; then
        # Remove any stale/incomplete build dir from a previous failed run (avoids lock file errors)
        rm -rf "$KERL_DIR/builds/$KERL_VERSION"
        "$KERL_BIN" build "$KERL_VERSION" "$KERL_VERSION"
        "$KERL_BIN" install "$KERL_VERSION" "$KERL_INSTALL_DIR"
    fi

    # Activate this Erlang for the rest of the script
    # shellcheck disable=SC1091
    source "$KERL_INSTALL_DIR/activate"

    # Verify crypto is now available; bail with a clear message if not
    if ! has_crypto; then
        echo "❌ Error: kerl-built Erlang still lacks crypto. Your macOS SDK may be missing OpenSSL headers."
        echo "   Try: sudo xcode-select --install"
        exit 1
    fi
    echo "✅ kerl-built Erlang ${KERL_VERSION} with crypto is active."
fi

# Ensure rebar3 is recent enough to avoid a known relx/OTP27 bug (atom_to_list badarg
# in write_start_scripts_for) present in older rebar3 bundled relx versions.
MIN_REBAR3_VERSION="3.24.0"
CURRENT_REBAR3_VERSION=$(rebar3 --version | grep -o 'rebar [0-9.]*' | awk '{print $2}')
if [ "$(printf '%s\n' "$MIN_REBAR3_VERSION" "$CURRENT_REBAR3_VERSION" | sort -V | head -n1)" != "$MIN_REBAR3_VERSION" ]; then
    echo "⚠️  rebar3 ${CURRENT_REBAR3_VERSION} is too old (needs >= ${MIN_REBAR3_VERSION}). Upgrading..."
    rebar3 local upgrade
fi

# Run the build
rebar3 as prod release
echo "✅ macOS binary ready at: _build/prod/rel/erl_data_shift/bin/erl_data_shift"

# --- Package as a single self-extracting file -------------------------------
# Wraps the whole release dir (ERTS + bytecode) into one executable: a small
# shell stub followed by an appended tar.gz of the release. On first run it
# extracts to a cache dir and execs the real binary from there; later runs
# reuse that cache dir if the version already exists.
echo "📦 Packaging self-extracting single-file binary..."

RELEASE_DIR="_build/prod/rel/erl_data_shift"
# Pull version straight from rebar.config's {release, {erl_data_shift, "X.Y.Z"}, ...}
# so it never drifts out of sync with the actual build.
VERSION=$(grep -o '{release, {erl_data_shift, "[^"]*"' rebar.config | sed 's/.*"\(.*\)"/\1/')
OUT_DIR="_build/prod/bin"
OUT_FILE="${OUT_DIR}/eds"
TARBALL="_build/prod/erl_data_shift-release.tar.gz"

mkdir -p "$OUT_DIR"
tar -C "_build/prod/rel" -czf "$TARBALL" erl_data_shift

# Shell stub: finds its own EOF marker, extracts the appended tarball to a
# per-version cache dir (skips extraction if already cached), then execs.
# "foreground" is injected automatically so the user just runs `eds <command>`
# instead of `eds foreground <command>`.
cat > "$OUT_FILE" <<STUB
#!/usr/bin/env bash
set -e
CACHE_DIR="\${HOME}/.cache/erl_data_shift/${VERSION}"
if [ ! -x "\${CACHE_DIR}/bin/erl_data_shift" ]; then
    mkdir -p "\${CACHE_DIR}"
    ARCHIVE_LINE=\$(awk '/__ARCHIVE_BELOW__\$/{print NR + 1; exit 0;}' "\$0")
    tail -n +"\${ARCHIVE_LINE}" "\$0" | tar -xz -C "\${CACHE_DIR}" --strip-components=1
fi
exec "\${CACHE_DIR}/bin/erl_data_shift" foreground "\$@"
exit 0
__ARCHIVE_BELOW__
STUB

cat "$TARBALL" >> "$OUT_FILE"
chmod +x "$OUT_FILE"
rm -f "$TARBALL"

echo "✅ Single-file binary ready at: ${OUT_FILE}"