#!/usr/bin/env bash
set -euo pipefail

# Defaults (override by exporting NSX/U/P or editing here)
NSX="${NSX:-nsx-wld01-a.site-a.vcf.lab}"
U="${U:-admin}"
P="${P:-VMware123!VMware123!}"

SEG_NAME="${1:-}"
if [[ -z "$SEG_NAME" ]]; then
  echo "Usage: NSX=<fqdn> U=<user> P=<pass> $0 <SEG_NAME>" >&2
  exit 1
fi

UPDATE_FILE="segment-${SEG_NAME}.update.json"
PATH_FILE="segment-${SEG_NAME}.path"

[[ -f "$UPDATE_FILE" ]] || { echo "Missing $UPDATE_FILE (run get-segment.sh first)"; exit 2; }
[[ -f "$PATH_FILE"   ]] || { echo "Missing $PATH_FILE (run get-segment.sh first)"; exit 2; }

SEG_PATH="$(cat "$PATH_FILE")"
if [[ -z "$SEG_PATH" ]]; then
  echo "Empty path in $PATH_FILE" >&2
  exit 3
fi

# PATCH the full document back
curl -sk -u "$U:$P" -X PATCH "https://${NSX}/policy/api/v1${SEG_PATH}" \
  -H "Content-Type: application/json" \
  --data-binary "@${UPDATE_FILE}"

echo "Patched ${SEG_NAME} from ${UPDATE_FILE} to ${SEG_PATH}"
