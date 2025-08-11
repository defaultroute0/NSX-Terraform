# Dump files for tf-web
#./get-segment.sh tf-web
# (Edit segment-tf-web.update.json as needed, e.g. change "description", or remove advanced attributes)
# Push the full document back
#./update-segment.sh tf-web
#################################

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

command -v jq >/dev/null 2>&1 || { echo "jq is required"; exit 2; }

# 1) Find the segment path & id by exact display_name
SEARCH_JSON="$(curl -sk -u "$U:$P" -G "https://${NSX}/policy/api/v1/search" \
  --data-urlencode "query=resource_type:Segment AND display_name:${SEG_NAME}")"

SEG_PATH="$(jq -r --arg n "$SEG_NAME" \
  '.results | map(select(.display_name==$n)) | (.[0].path // empty)' <<<"$SEARCH_JSON")"
SEG_ID="$(jq -r --arg n "$SEG_NAME" \
  '.results | map(select(.display_name==$n)) | (.[0].id // empty)' <<<"$SEARCH_JSON")"

if [[ -z "$SEG_PATH" ]]; then
  echo "Segment '$SEG_NAME' not found on $NSX" >&2
  exit 3
fi

echo "$SEG_PATH" > "segment-${SEG_NAME}.path"
echo "$SEG_ID"   > "segment-${SEG_NAME}.id"

# 2) GET the full object (pretty JSON)
curl -sk -u "$U:$P" "https://${NSX}/policy/api/v1${SEG_PATH}" \
  | jq . > "segment-${SEG_NAME}.get.json"

# 3) Build an editable UPDATE file (strip read-only/system fields)
jq 'del(
      .path,
      .parent_path,
      .relative_path,
      .unique_id,
      .realization_id,
      .system_metadata,
      .marked_for_delete,
      .overridden,
      .create_time,
      .last_modified_time,
      .last_modified_by,
      ._create_time,
      ._last_modified_time,
      ._system_owned,
      ._revision,
      ._links,
      .children
    )' "segment-${SEG_NAME}.get.json" > "segment-${SEG_NAME}.update.json"

echo "Wrote:"
echo "  segment-${SEG_NAME}.get.json     (raw GET)"
echo "  segment-${SEG_NAME}.update.json  (editable for PATCH)"
echo "  segment-${SEG_NAME}.path         (policy path)"
echo "  segment-${SEG_NAME}.id           (object id)"
