/**
 * # terraform-fortios-sslvpn
 * 
 * ## Usage:
 *
 * ### Example of 'terraform-fortios-sslvpn' module.
 *
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
 *   source = "github.com/poroping/terraform-fortios-sslvpn"
 * 
 *   prefix           = fortios_system_vdom.vdom.name
 *   ssl_interface    = fortios_system_interface.loopsmcgee
 *   outside_int_name = fortios_system_interface.ext.name
 *   vdom             = fortios_system_vdom.vdom.name
 *   dns_servers      = ["192.168.1.1", "192.168.2.1"]
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
    name = fortios_firewall_address.sslvpn_full_user_pool.name
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "fortios_vpnsslweb_realm" "full_tunnel" {
  vdomparam = var.vdom

  url_path = "full-tunnel"
}

resource "fortios_vpnssl_settings" "settings" {
  vdomparam = var.vdom

  algorithm           = "high"
  auth_timeout        = 43200
  default_portal      = fortios_vpnsslweb_portal.blackhole.name
  https_redirect      = "enable"
  idle_timeout        = 300
  login_attempt_limit = 5
  login_block_time    = 90
  login_timeout       = 90
  port                = 443
  port_precedence     = "enable"
  ssl_min_proto_ver   = "tls1-2"

  servercert  = var.ssl_servercert_name == null ? null : var.ssl_servercert_name
  dns_server1 = try(var.dns_servers[0], null)
  dns_server2 = try(var.dns_servers[1], null)
  dns_suffix  = join(",", var.dns_suffixes)

  source_address {
    name = "all"
  }

  source_interface {
    name = var.ssl_interface.name
  }

  tunnel_ip_pools {
    name = fortios_firewall_address.sslvpn_full_user_pool.name
  }

  tunnel_ip_pools {
    name = fortios_firewall_address.sslvpn_split_user_pool.name
  }

  authentication_rule {
    id     = 1
    portal = fortios_vpnsslweb_portal.split_tunnel.name

    groups {
      name = fortios_user_group.sslvpn_users.name
    }
  }

  authentication_rule {
    id     = 2
    portal = fortios_vpnsslweb_portal.full_tunnel.name
    realm  = fortios_vpnsslweb_realm.full_tunnel.url_path

    groups {
      name = fortios_user_group.sslvpn_users.name
    }
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
  vdomparam = var.vdom
  portal    = fortios_vpnsslweb_portal.full_tunnel.name
  realm     = fortios_vpnsslweb_realm.full_tunnel.url_path

  groups {
    name = fortios_user_group.sslvpn_users.name
  }
}

resource "fortios_firewall_policy" "vpn_loopback_in" {
  vdomparam = var.vdom
  count     = var.ssl_interface.type == "loopback" ? 1 : 0

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
    name = "HTTP"
  }

  service {
    name = "HTTPS"
  }

  service {
    name = "PING"
  }

  srcaddr {
    name = "all"
  }

  srcintf {
    name = var.outside_int_name
  }
}

resource "fortios_firewall_address" "dns_servers" {
  for_each     = var.dns_servers
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

resource "fortios_firewall_policy" "sslvpn_access_dns" {
  vdomparam = var.vdom
  count     = length(var.dns_servers) == 0 ? 0 : 1

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
    name = "any" # do a lookup
  }

  service {
    name = "DNS"
  }

  service {
    name = "PING"
  }

  srcaddr {
    name = fortios_firewall_address.sslvpn_full_user_pool.name
  }

  srcaddr {
    name = fortios_firewall_address.sslvpn_split_user_pool.name
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
  vdomparam = var.vdom

  blackhole = "enable"
  dstaddr   = fortios_firewall_address.sslvpn_full_user_pool.name
  status    = "enable"
}