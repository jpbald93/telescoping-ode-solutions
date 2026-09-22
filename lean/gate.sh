#!/bin/bash
# Gate for the telescoping-ODE Lean development.
# Requires: clean build; no sorry/admit/axiom/native_decide; only the three
# standard axioms; and at least EXPECTED_MIN audited theorems in Check.lean.
export PATH="$HOME/.elan/bin:$PATH"
cd "$(dirname "$0")" || exit 1

if grep -rqn "sorry\|admit\b\|^axiom \|native_decide" ExpODE/*.lean; then
  echo "FAIL: sorry/admit/axiom/native_decide present"; exit 1; fi

out=$(lake build 2>&1)
echo "$out" | grep -q "Build completed successfully" \
  || { echo "FAIL: build"; echo "$out" | grep -E "error:" | head; exit 1; }

# Axiom report lines come from Check.lean's #print axioms.
lines=$(echo "$out" | grep "depends on axioms")
n=$(echo "$lines" | grep -c "depends on axioms")
EXPECTED_MIN=12
if [ "$n" -lt "$EXPECTED_MIN" ]; then
  echo "FAIL: only $n audited, expected >= $EXPECTED_MIN"; exit 1; fi

bad=$(echo "$lines" | sed 's/.*depends on axioms: \[//; s/\].*//' | tr ',' '\n' \
  | sed 's/^ *//;s/ *$//' | grep -v '^$' | sort -u \
  | grep -vE '^(propext|Classical\.choice|Quot\.sound)$')
[ -n "$bad" ] && { echo "FAIL: nonstandard axioms: $bad"; exit 1; }

echo "PASS ($n theorems, standard axioms only)"
