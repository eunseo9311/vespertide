#!/usr/bin/env bash
# Reproduce the unsafe-diff scenario end-to-end.
# Captures `vespertide diff`, `revision`, and `log` output into expected_output/.

set -euo pipefail

cd "$(dirname "$0")"
REPO_ROOT="$(cd ../.. && pwd)"

# Build the CLI once so each invocation below is instant.
(cd "$REPO_ROOT" && cargo build --quiet -p vespertide-cli)
VESP="$REPO_ROOT/target/debug/vespertide"

# Strip ANSI colors from captured output so the .txt files are paper-friendly.
export NO_COLOR=1

# Clean previous run.
rm -rf models migrations
mkdir -p models migrations expected_output

# Step 1: establish the initial schema (email is nullable, no UNIQUE).
cp snapshots/users.before.json models/users.json
"$VESP" revision -m "init users" > /dev/null

# Step 2: developer evolves the schema (email becomes NOT NULL + UNIQUE).
cp snapshots/users.after.json models/users.json

echo "=== vespertide diff ==="
"$VESP" diff | tee expected_output/diff.txt

echo
echo "=== vespertide revision ==="
"$VESP" revision \
    -m "require email" \
    --fill-with "users.email='anonymous@example.com'" \
    | tee expected_output/revision.txt

echo
echo "=== vespertide log ==="
"$VESP" log | tee expected_output/log.txt
