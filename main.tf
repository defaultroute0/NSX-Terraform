terraform {
  required_providers {
    nsxt = {
      source  = "vmware/nsxt"
      version = ">= 3.8.0"
    }
  }
}

provider "nsxt" {
  username             = "admin"
  password             = "XXXX"
  host                 = "nsx-wld01-a.site-a.vcf.lab"
  allow_unverified_ssl = true
}
