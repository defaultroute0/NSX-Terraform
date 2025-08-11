# ---------- variables ----------
variable "nsxt_logical_tier1_router_name" { default = "terraformdemo-t1" }
variable "logicalswitch1_name"            { default = "tf-web" }
variable "logicalswitch2_name"            { default = "tf-app" }
variable "logicalswitch3_name"            { default = "tf-db"  }
variable "logicalswitch1_gw"              { default = "192.168.80.1/24" }
variable "logicalswitch2_gw"              { default = "192.168.81.1/24" }
variable "logicalswitch3_gw"              { default = "192.168.82.1/24" }

# ---------- lookups (display_name must match NSX Manager) ----------
data "nsxt_policy_transport_zone" "overlay_tz_nsx_wld01_a" {
  display_name = "overlay-tz-nsx-wld01-a"
}

data "nsxt_policy_tier0_gateway" "t0_wld_a" {
  display_name = "t0-wld-a"
}

data "nsxt_policy_edge_cluster" "edgecl_wld_a" {
  display_name = "edgecl-wld-a"
}

# ---------- Tier-1 ----------
resource "nsxt_policy_tier1_gateway" "t1" {
  display_name      = var.nsxt_logical_tier1_router_name
  tier0_path        = data.nsxt_policy_tier0_gateway.t0_wld_a.path
  edge_cluster_path = data.nsxt_policy_edge_cluster.edgecl_wld_a.path

  route_advertisement_types = [
    "TIER1_CONNECTED",
    "TIER1_STATIC_ROUTES",
    "TIER1_NAT"
  ]

  tag {
    scope = "app"
    tag   = "terraformdemo"
  }
}

# ---------- Segments (each subnet adds the T1 interface) ----------
resource "nsxt_policy_segment" "web" {
  display_name        = var.logicalswitch1_name
  description         = "web segment created by TF - Ryan"
  transport_zone_path = data.nsxt_policy_transport_zone.overlay_tz_nsx_wld01_a.path
  connectivity_path   = nsxt_policy_tier1_gateway.t1.path

  subnet { cidr = var.logicalswitch1_gw }
  advanced_config { connectivity = "ON" }

  tag {
    scope = "app"
    tag   = "terraformdemo"
  }
}

resource "nsxt_policy_segment" "app" {
  display_name        = var.logicalswitch2_name
  transport_zone_path = data.nsxt_policy_transport_zone.overlay_tz_nsx_wld01_a.path
  connectivity_path   = nsxt_policy_tier1_gateway.t1.path

  subnet { cidr = var.logicalswitch2_gw }
  advanced_config { connectivity = "ON" }

  tag {
    scope = "app"
    tag   = "terraformdemo"
  }
}

resource "nsxt_policy_segment" "db" {
  display_name        = var.logicalswitch3_name
  transport_zone_path = data.nsxt_policy_transport_zone.overlay_tz_nsx_wld01_a.path
  connectivity_path   = nsxt_policy_tier1_gateway.t1.path

  subnet { cidr = var.logicalswitch3_gw }
  advanced_config { connectivity = "ON" }

  tag {
    scope = "app"
    tag   = "terraformdemo"
  }
}

# ---------- Groups (use member_paths) ----------
resource "nsxt_policy_group" "grp_web" {
  display_name = "grp-seg-web"
  criteria {
    path_expression { member_paths = [nsxt_policy_segment.web.path] }
  }
}

resource "nsxt_policy_group" "grp_app" {
  display_name = "grp-seg-app"
  criteria {
    path_expression { member_paths = [nsxt_policy_segment.app.path] }
  }
}

# ---------- Custom L4 Service ----------
resource "nsxt_policy_service" "svc_web_to_app" {
  display_name = "web_to_app_tcp_443_22"

  l4_port_set_entry {
    display_name      = "tcp-443-22"
    protocol          = "TCP"
    destination_ports = ["443", "22"]
  }

  tag {
    scope = "app"
    tag   = "terraformdemo"
  }
}

# ---------- DFW Policy ----------
resource "nsxt_policy_security_policy" "web_app" {
  display_name = "Web-App"
  category     = "Application"

  rule {
    display_name       = "Web_to_App_TCP"
    source_groups      = [nsxt_policy_group.grp_web.path]
    destination_groups = [nsxt_policy_group.grp_app.path]
    services           = [nsxt_policy_service.svc_web_to_app.path]
    scope              = [nsxt_policy_group.grp_web.path, nsxt_policy_group.grp_app.path]
    action             = "ALLOW"
    logged             = true
  }

  tag {
    scope = "app"
    tag   = "terraformdemo"
  }
}

# ---------- outputs ----------
output "tier0_path"   { value = data.nsxt_policy_tier0_gateway.t0_wld_a.path }
output "tier1_path"   { value = nsxt_policy_tier1_gateway.t1.path }
output "web_seg_path" { value = nsxt_policy_segment.web.path }
