#!/usr/bin/env bash
# Plain-bash test file for
# claude-prose-format-posttool-hook.sh.
#
# Usage:
#   bash test-claude-prose-format-posttool-hook.sh
#
# Exits 0 when every assertion passes, non-zero
# otherwise. No bats dependency by design - the sibling
# hook tests set that precedent.
#
# Each fixture gets its own scratch git repo under
# TMPDIR, so --changed-only always sees the fixture's
# whole content as changed (untracked, or staged but
# never committed).
#
# This never touches this repo's own history.

set -uo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$script_dir/claude-prose-format-posttool-hook.sh"

pass_count=0
fail_count=0

TMPDIR=$(mktemp -d)
export TMPDIR
trap 'rm -rf "$TMPDIR"' EXIT

bash_bin="$(command -v bash)"

# assert_eq - inline assert helper: compares expected vs
# actual, prints ok/not-ok.
assert_eq() {
  local description="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    pass_count=$((pass_count + 1))
    printf 'ok - %s\n' "$description"
  else
    fail_count=$((fail_count + 1))
    printf 'not ok - %s\n  expected: %s\n  actual:   %s\n' "$description" "$expected" "$actual"
  fi
}

# assert_contains - passes when actual contains needle.
assert_contains() {
  local description="$1" needle="$2" actual="$3"
  if [[ "$actual" == *"$needle"* ]]; then
    pass_count=$((pass_count + 1))
    printf 'ok - %s\n' "$description"
  else
    fail_count=$((fail_count + 1))
    printf 'not ok - %s\n  expected to contain: %s\n  actual:   %s\n' "$description" "$needle" "$actual"
  fi
}

# assert_not_contains - passes when actual does NOT
# contain needle.
assert_not_contains() {
  local description="$1" needle="$2" actual="$3"
  if [[ "$actual" != *"$needle"* ]]; then
    pass_count=$((pass_count + 1))
    printf 'ok - %s\n' "$description"
  else
    fail_count=$((fail_count + 1))
    printf 'not ok - %s\n  expected NOT to contain: %s\n  actual:   %s\n' "$description" "$needle" "$actual"
  fi
}

# new_repo_fixture - creates a fresh scratch git repo
# under TMPDIR and echoes its path.
new_repo_fixture() {
  local dir
  dir=$(mktemp -d)
  git init -q "$dir"

  # A committer identity is needed for later commands in
  # this repo, even though these fixtures never commit -
  # git init alone is enough for get-changed-lines.sh's
  # "is this a work tree" check.
  printf '%s' "$dir"
}

# run_hook - invokes the hook with the given tool_name
# and file_path, wrapped into the PostToolUse JSON
# shape. Captures exit code into HOOK_EXIT and combined
# stdout+stderr into HOOK_OUT.
run_hook() {
  local tool_name="$1" file_path="$2" stdin_json
  stdin_json=$(jq -n --arg t "$tool_name" --arg f "$file_path" \
    '{tool_name: $t, tool_input: {file_path: $f}}')
  HOOK_OUT=$(printf '%s' "$stdin_json" | "$bash_bin" "$SCRIPT" 2>&1)
  HOOK_EXIT=$?
}

it_should_stay_silent_on_a_clean_markdown_write() {
  local dir
  dir=$(new_repo_fixture)
  cat > "$dir/clean.md" << 'EOF'
Small clean paragraph.

Another small one.
EOF
  run_hook "Write" "$dir/clean.md"
  assert_eq "should exit 0 on a clean markdown write" "0" "$HOOK_EXIT"
  assert_eq "should print nothing on a clean markdown write" "" "$HOOK_OUT"
}

it_should_report_a_wall_of_text_markdown_write() {
  local dir long_line
  dir=$(new_repo_fixture)
  long_line=$(python3 -c "print('word ' * 120)")
  {
    printf '%s\n\n' "$long_line"
    printf '%s\n\n' "$long_line"
    printf '%s\n\n' "$long_line"
  } > "$dir/wall.md"
  run_hook "Write" "$dir/wall.md"
  assert_eq "should exit 2 on a wall-of-text markdown write" "2" "$HOOK_EXIT"
  assert_contains "should name the file in the report" "wall.md" "$HOOK_OUT"
  assert_contains "should report the right violation count" "3 violations" "$HOOK_OUT"

  # The checker's own "== <path>" header line is never a
  # violation - a prior session miscounted by including
  # it, so this pins the count against that regression.
  assert_not_contains "should never count the checker's own header line" "== " "$HOOK_OUT"
}

it_should_use_the_counts_regime_over_the_threshold() {
  local dir long_line i
  dir=$(new_repo_fixture)
  long_line=$(python3 -c "print('word ' * 120)")
  : > "$dir/big.md"
  for ((i = 0; i < 15; i++)); do
    printf '%s\n\n' "$long_line" >> "$dir/big.md"
  done
  run_hook "Write" "$dir/big.md"
  assert_eq "should exit 2 over the threshold" "2" "$HOOK_EXIT"
  assert_contains "should report 15 violations" "15 violations" "$HOOK_OUT"

  # Counts regime: no line-number rows, but does list the
  # checker's own script pointer command.
  if [[ "$HOOK_OUT" =~ L[0-9] ]]; then
    fail_count=$((fail_count + 1))
    printf 'not ok - should not print any L<digits> line-number row over threshold\n  actual:   %s\n' "$HOOK_OUT"
  else
    pass_count=$((pass_count + 1))
    printf 'ok - should not print any L<digits> line-number row over threshold\n'
  fi
  assert_contains "should list the checker's own script pointer over threshold" \
    "check-density.sh   --changed-only big.md" "$HOOK_OUT"
}

it_should_use_the_line_number_regime_under_the_threshold() {
  local dir long_line
  dir=$(new_repo_fixture)
  long_line=$(python3 -c "print('word ' * 120)")
  printf '%s\n' "$long_line" > "$dir/small.md"
  run_hook "Write" "$dir/small.md"
  assert_eq "should exit 2 under the threshold" "2" "$HOOK_EXIT"
  assert_contains "should print the violated line number" "L1" "$HOOK_OUT"
  assert_not_contains "should not list a script pointer under threshold" \
    "doc-standards/scripts/check-density.sh" "$HOOK_OUT"
}

it_should_route_a_shell_file_to_the_comment_checker() {
  local dir
  dir=$(new_repo_fixture)
  {
    printf '#!/bin/bash\n'
    printf '# %s\n' "$(python3 -c "print('word ' * 30)")"
    printf 'echo hi\n'
  } > "$dir/wide.sh"
  run_hook "Write" "$dir/wide.sh"
  assert_eq "should exit 2 on an over-wide shell comment" "2" "$HOOK_EXIT"
  assert_contains "should report the comment-format finding" "width" "$HOOK_OUT"
  assert_not_contains "should not run the density checker on a shell file" "density" "$HOOK_OUT"

  # "hard-wrap" also appears inside the rule block's own prose
  # ("never hard-wrap"), so the label row is what's asserted
  # against, not the bare substring.
  assert_not_contains "should not run the hard-wrap checker on a shell file" "  hard-wrap " "$HOOK_OUT"
}

it_should_stay_silent_on_an_unknown_extension() {
  local dir
  dir=$(new_repo_fixture)
  printf '{"a": 1}' > "$dir/data.json"
  run_hook "Write" "$dir/data.json"
  assert_eq "should exit 0 on an unknown extension" "0" "$HOOK_EXIT"
  assert_eq "should print nothing on an unknown extension" "" "$HOOK_OUT"
}

it_should_fail_open_outside_a_git_repo() {
  local dir long_line
  dir=$(mktemp -d)
  long_line=$(python3 -c "print('word ' * 120)")
  printf '%s\n' "$long_line" > "$dir/wall.md"
  run_hook "Write" "$dir/wall.md"
  assert_eq "should exit 0 outside a git work tree" "0" "$HOOK_EXIT"
  assert_eq "should print nothing outside a git work tree" "" "$HOOK_OUT"
}

it_should_fail_open_on_a_missing_file() {
  run_hook "Write" "$TMPDIR/does-not-exist-xyz.md"
  assert_eq "should exit 0 on a missing file" "0" "$HOOK_EXIT"
  assert_eq "should print nothing on a missing file" "" "$HOOK_OUT"
}

it_should_fail_open_on_a_non_write_edit_payload() {
  local dir
  dir=$(new_repo_fixture)
  cat > "$dir/clean.md" << 'EOF'
Small clean paragraph.
EOF
  run_hook "Read" "$dir/clean.md"
  assert_eq "should exit 0 on a Read payload" "0" "$HOOK_EXIT"
  assert_eq "should print nothing on a Read payload" "" "$HOOK_OUT"
}

it_should_carry_the_rule_block_verbatim_in_every_report() {
  local dir long_line rule1 rule2 rule3
  rule1='Prose: small paragraphs of 1-4 sentences, blank line between each.'
  rule2='Bullets + sub-bullets: 1-2 sentences each.'
  rule3='One paragraph = one physical line — never hard-wrap. Never drop information.'

  dir=$(new_repo_fixture)
  long_line=$(python3 -c "print('word ' * 120)")
  printf '%s\n' "$long_line" > "$dir/small.md"
  run_hook "Write" "$dir/small.md"
  assert_contains "under-threshold report should carry rule line 1 verbatim" "$rule1" "$HOOK_OUT"
  assert_contains "under-threshold report should carry rule line 2 verbatim" "$rule2" "$HOOK_OUT"
  assert_contains "under-threshold report should carry rule line 3 verbatim" "$rule3" "$HOOK_OUT"

  dir=$(new_repo_fixture)
  : > "$dir/big.md"
  for ((i = 0; i < 15; i++)); do
    printf '%s\n\n' "$long_line" >> "$dir/big.md"
  done
  run_hook "Write" "$dir/big.md"
  assert_contains "over-threshold report should carry rule line 1 verbatim" "$rule1" "$HOOK_OUT"
  assert_contains "over-threshold report should carry rule line 2 verbatim" "$rule2" "$HOOK_OUT"
  assert_contains "over-threshold report should carry rule line 3 verbatim" "$rule3" "$HOOK_OUT"
}

it_should_stay_silent_on_a_clean_markdown_write
it_should_report_a_wall_of_text_markdown_write
it_should_use_the_counts_regime_over_the_threshold
it_should_use_the_line_number_regime_under_the_threshold
it_should_route_a_shell_file_to_the_comment_checker
it_should_stay_silent_on_an_unknown_extension
it_should_fail_open_outside_a_git_repo
it_should_fail_open_on_a_missing_file
it_should_fail_open_on_a_non_write_edit_payload
it_should_carry_the_rule_block_verbatim_in_every_report

printf '\n%d passed, %d failed\n' "$pass_count" "$fail_count"
[ "$fail_count" -eq 0 ]
