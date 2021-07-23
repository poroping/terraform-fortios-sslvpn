/**
 * # terraform-fortios-sslvpn
 * 
 * Requires forked version of fortios provider
 * 
 * Will create SSLVPN portal and settings for split and optionally full tunnel.
 * 
 * Firewall policies will need to be created manually.
 * 
 * ## Usage:
 *
 * ### Basic example of 'terraform-fortios-sslvpn' module.
 *
 *
 * ```hcl
 * terraform {
 *   required_version = ">= 1.0.1"
 *   backend "local" {}
 *   required_providers {
 *     fortios = {
 *       source  = "poroping/fortios"
 *       version = "~> 2.0.0"
 *     }
 *   }
 * }
 * 
 * provider "fortios" {
 *   hostname = var.hostname
 *   token    = var.token
 *   vdom     = "root"
 *   insecure = "true"
 *   #   cabundlefile =  "/path/yourCA.crt"
 * }
 * 
 * 
 * data "fortios_system_interface" "wan" {
 *   name = "wan1"
 * }
 * 
 * module "sslvpn" {
 *   source  = "poroping/sslvpn/fortios"
 *   version = "0.2.0"
 * 
 *   ssl_interface    = data.fortios_system_interface.wan
 * }
 * ```
 * 
 * ### Example of 'terraform-fortios-sslvpn' module.
 *
 *
 * ```hcl
 * terraform {
 *   required_version = ">= 1.0.1"
 *   backend "local" {}
 *   required_providers {
 *     fortios = {
 *       source  = "poroping/fortios"
 *       version = "~> 2.0.0"
 *     }
 *   }
 * }
 * 
 * provider "fortios" {
 *   hostname = var.hostname
 *   token    = var.token
 *   vdom     = "root"
 *   insecure = "true"
 *   #   cabundlefile =  "/path/yourCA.crt"
 * }
 * 
 * resource "fortios_system_vdom" "vdom" {
 *   name = "TEST"
 * }
 * 
 * resource "fortios_system_interface" "ext" {
 *   name      = "TF-TEST"
 *   type      = "vlan"
 *   vdom      = fortios_system_vdom.vdom.name
 *   vlanid    = 666
 *   interface = "wan2"
 * }
 * 
 * resource "fortios_system_interface" "loopsmcgee" {
 *   name = "TEST-VPN-LOOP"
 *   type = "loopback"
 *   vdom = fortios_system_vdom.vdom.name
 * }
 * 
 * module "sslvpn" {
 *   source  = "poroping/sslvpn/fortios"
 *   version = "0.2.0"
 * 
 *   prefix           = fortios_system_vdom.vdom.name
 *   ssl_interface    = fortios_system_interface.loopsmcgee
 *   outside_int_name = fortios_system_interface.ext.name
 *   vdom             = fortios_system_vdom.vdom.name
 *   dns_servers      = ["192.168.1.1", "192.168.2.1"]
 *   has_full_tunnel  = true
 *   https_redirect   = "disable"
 *   port             = 9443
 * }
 * ```
 *
 * 
 */


terraform {
  required_providers {
    fortios = {
      source  = "poroping/fortios"
      version = ">= 2.0.2"
    }
  }
}

resource "fortios_firewall_address" "sslvpn_split_user_pool" {
  vdomparam    = var.vdom
  allow_append = true

  name          = "${var.prefix}-SSLVPN-SPLIT-USERS-POOL"
  subnet        = var.split_address_pool
  type          = "ipmask"
  allow_routing = "enable"

  lifecycle {
    create_before_destroy = true
  }
}

resource "fortios_firewall_address" "sslvpn_full_user_pool" {
  count = var.has_full_tunnel ? 1 : 0

  vdomparam    = var.vdom
  allow_append = true

  name          = "${var.prefix}-SSLVPN-FULL-USERS-POOL"
  subnet        = var.full_address_pool
  type          = "ipmask"
  allow_routing = "enable"

  lifecycle {
    create_before_destroy = true
  }
}

resource "fortios_user_group" "sslvpn_users" {
  vdomparam  = var.vdom
  group_type = "firewall"
  name       = "${var.prefix}-SSLVPN-USERS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "fortios_vpnsslweb_portal" "blackhole" {
  vdomparam    = var.vdom
  allow_append = true

  ipv6_tunnel_mode = "disable"
  name             = "${var.prefix}-BLACKHOLE"
  tunnel_mode      = "disable"
  web_mode         = "disable"

  lifecycle {
    create_before_destroy = true
  }
}

resource "fortios_vpnsslweb_portal" "split_tunnel" {
  vdomparam    = var.vdom
  allow_append = true

  forticlient_download = "disable"
  ipv6_tunnel_mode     = "disable"
  name                 = "${var.prefix}-SPLIT-TUNNEL"
  split_tunneling      = "enable"
  tunnel_mode          = "enable"
  web_mode             = "disable"

  keep_alive    = "disable"
  auto_connect  = "disable"
  save_password = "disable"
  # if either keep_alive or auto_connect enabled this needs to be enabled

  ip_pools {
    name = fortios_firewall_address.sslvpn_split_user_pool.name
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "fortios_vpnsslweb_portal" "full_tunnel" {
  count = var.has_full_tunnel ? 1 : 0

  vdomparam    = var.vdom
  allow_append = true

  forticlient_download = "disable"
  ipv6_tunnel_mode     = "disable"
  name                 = "${var.prefix}-FULL-TUNNEL"
  split_tunneling      = "disable"
  tunnel_mode          = "enable"
  web_mode             = "disable"

  keep_alive    = "disable"
  auto_connect  = "disable"
  save_password = "disable"
  # if either keep_alive or auto_connect enabled this needs to be enabled

  ip_pools {
    name = fortios_firewall_address.sslvpn_full_user_pool[0].name
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "fortios_vpnsslweb_realm" "full_tunnel" {
  count = var.has_full_tunnel ? 1 : 0

  vdomparam = var.vdom

  url_path = "full-tunnel"
}

resource "fortios_vpnssl_settings" "settings" {
  dynamic_sort_subtable = true
  vdomparam             = var.vdom

  algorithm           = "high"
  auth_timeout        = 43200
  default_portal      = fortios_vpnsslweb_portal.blackhole.name
  dtls_tunnel         = "enable"
  https_redirect      = var.https_redirect
  idle_timeout        = 300
  login_attempt_limit = 5
  login_block_time    = 90
  login_timeout       = 90
  port                = var.port
  port_precedence     = "enable"
  ssl_min_proto_ver   = "tls1-2"

  servercert  = var.ssl_servercert_name == "" ? null : var.ssl_servercert_name
  dns_server1 = try(var.dns_servers[0], null)
  dns_server2 = try(var.dns_servers[1], null)
  dns_suffix  = join(",", var.dns_suffixes)

  source_address {
    name = "all"
  }

  source_interface {
    name = var.ssl_interface.name
  }

  dynamic "tunnel_ip_pools" {
    for_each = var.has_full_tunnel ? ["1"] : []

    content {
      name = fortios_firewall_address.sslvpn_full_user_pool[0].name
    }
  }

  tunnel_ip_pools {
    name = fortios_firewall_address.sslvpn_split_user_pool.name
  }
}

resource "fortios_vpnssl_settings_authentication_rule" "split" {
  vdomparam = var.vdom

  portal = fortios_vpnsslweb_portal.split_tunnel.name

  groups {
    name = fortios_user_group.sslvpn_users.name
  }

}

resource "fortios_vpnssl_settings_authentication_rule" "full" {
  count = var.has_full_tunnel ? 1 : 0

  vdomparam = var.vdom

  portal = fortios_vpnsslweb_portal.full_tunnel[0].name
  realm  = fortios_vpnsslweb_realm.full_tunnel[0].url_path

  groups {
    name = fortios_user_group.sslvpn_users.name
  }
}

resource "fortios_firewallservice_custom" "custom_sslvpn_port" {
  count = var.port == 443 ? 0 : 1

  vdomparam = var.vdom

  name          = "SSLVPN-HTTPS-CUSTOM"
  category      = "Remote Access"
  protocol      = "TCP/UDP/SCTP"
  tcp_portrange = var.port
  visibility    = "enable"

}

resource "fortios_firewall_policy" "vpn_loopback_in" {
  count = var.ssl_interface.type == "loopback" ? 1 : 0

  vdomparam             = var.vdom

  action     = "accept"
  logtraffic = "utm"
  name       = "Allow access to SSLVPN portal."
  schedule   = "always"

  dstaddr {
    name = "all"
  }

  dstintf {
    name = var.ssl_interface.name
  }

  service {
    name = "PING"
  }

  service {
    name = var.port == 443 ? "HTTPS" : fortios_firewallservice_custom.custom_sslvpn_port[0].name
  }

  dynamic "service" {
    for_each = var.https_redirect == "enable" ? ["1"] : []

    content {
      name = "HTTP"
    }
  }

  srcaddr {
    name = "all"
  }

  srcintf {
    name = var.outside_int_name
  }

}

resource "fortios_firewall_address" "dns_servers" {
  for_each = var.dns_servers

  vdomparam    = var.vdom
  allow_append = true

  name          = "${var.prefix}-SSLVPN-DNS-${each.value}"
  subnet        = "${each.value}/32"
  type          = "ipmask"
  allow_routing = "enable"

  lifecycle {
    create_before_destroy = true
  }
}

data "fortios_json_generic_api" "routecheck" {
  count = length(var.dns_servers) == 0 ? 0 : 1

  path          = "/api/v2/monitor/router/lookup"
  vdomparam     = var.vdom
  specialparams = "destination=${try(var.dns_servers[0], "0.0.0.0")}"
}

resource "fortios_firewall_policy" "sslvpn_access_dns" {
  count = length(var.dns_servers) == 0 ? 0 : 1

  dynamic_sort_subtable = true
  vdomparam             = var.vdom

  action     = "accept"
  logtraffic = "utm"
  name       = "Allow SSL-VPN traffic to DNS."
  schedule   = "always"

  dynamic "dstaddr" {
    for_each = fortios_firewall_address.dns_servers
    content {
      name = dstaddr.value.name
    }
  }

  dstintf {
    name = "any" # try(jsondecode(data.fortios_json_generic_api.routecheck[0].response).results["interface"], "any") #this works but on second apply
  }

  service {
    name = "DNS"
  }

  service {
    name = "PING"
  }

  srcaddr {
    name = fortios_firewall_address.sslvpn_split_user_pool.name
  }

  dynamic "srcaddr" {
    for_each = var.has_full_tunnel ? ["1"] : []

    content {
      name = fortios_firewall_address.sslvpn_full_user_pool[0].name
    }
  }

  groups {
    name = fortios_user_group.sslvpn_users.name
  }

  srcintf {
    name = "ssl.${var.vdom}"
  }

  depends_on = [
    fortios_vpnssl_settings.settings
  ]
}

resource "fortios_router_static" "sslvpn_splitpool_null_route" {
  vdomparam = var.vdom

  blackhole = "enable"
  dstaddr   = fortios_firewall_address.sslvpn_split_user_pool.name
  status    = "enable"
}

resource "fortios_router_static" "sslvpn_fullpool_null_route" {
  count = var.has_full_tunnel ? 1 : 0

  vdomparam = var.vdom

  blackhole = "enable"
  dstaddr   = fortios_firewall_address.sslvpn_full_user_pool[0].name
  status    = "enable"
}