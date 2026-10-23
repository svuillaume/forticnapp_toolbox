#!/usr/bin/env bash
set -euo pipefail

STATE_FILE="${1:-terraform.tfstate}"

for tool in terraform jq column; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    printf 'Error: required command not found: %s\n' "$tool" >&2
    exit 1
  fi
done

if [[ ! -f "$STATE_FILE" ]]; then
  printf 'Error: state file not found: %s\n' "$STATE_FILE" >&2
  exit 1
fi

printf '\n=== TERRAFORM PROVIDERS ===\n'
if ! terraform providers; then
  printf 'Could not inspect project providers; state references appear below.\n' >&2
fi

printf '\n=== TERRAFORM STATE LIST ===\n'
terraform state list -state="$STATE_FILE"

printf '\n=== MODULES, PROVIDERS AND MANAGED RESOURCES ===\n'
jq -r '
  ["MODULE", "PROVIDER", "TYPE", "NAME"],
  (.resources[]
   | select(.mode == "managed")
   | [(.module // "root"), .provider, .type, .name])
  | @tsv
' "$STATE_FILE" | column -t -s $'\t'
