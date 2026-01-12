# Cloud Router Module - Creates Cloud Router for Cloud NAT and BGP
# Per Carrier LLD v1.0 - ASN 16550 for Transit VPC

resource "google_compute_router" "router" {
  name    = var.name
  project = var.project_id
  region  = var.region
  network = var.network

  bgp {
    asn               = var.asn
    advertise_mode    = var.advertise_mode
    advertised_groups = var.advertised_groups

    dynamic "advertised_ip_ranges" {
      for_each = var.advertised_ip_ranges
      content {
        range       = advertised_ip_ranges.value.range
        description = advertised_ip_ranges.value.description
      }
    }
  }

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}
