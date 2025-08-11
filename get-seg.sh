# Example Usage:     ./get-seg.sh tf-web 
NSX="nsx-manager.yourdomain"
U="admin"
P='your-password'
SEG_NAME="$1"

# 1) Find the segment by display_name; capture its UUID (id) and full policy path
read SEG_ID SEG_PATH <<EOF
$(curl -sk -u "$U:$P" "https://$NSX/policy/api/v1/search?query=resource_type:Segment%20AND%20display_name:$SEG_NAME" \
 | jq -r '.results[0] | "\(.id) \(.path)"')
EOF

echo "Segment name: $SEG_NAME"
echo "UUID (id):   $SEG_ID"
echo "Path:        $SEG_PATH"

# 2) Use the returned path to GET the object and print multicast
curl -sk -u "$U:$P" "https://$NSX/policy/api/v1${SEG_PATH}" \
| jq '{id, display_name, path, multicast: .advanced_config.multicast}'
