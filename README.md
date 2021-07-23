<!-- BEGIN_TF_DOCS -->
# terraform-fortios-sslvpn

Requires forked version of fortios provider

Will create SSLVPN portal and settings for split and optionally full tunnel.

Firewall policies will need to be created manually.

## Usage:

### Basic example of 'terraform-fortios-sslvpn' module.

```hcl
terraform {
  required_version = ">= 1.0.1"
  backend "local" {}
  required_providers {
    fortios = {
      source  = "poroping/fortios"
      version = "~> 2.0.0"
    }
  }
}

provider "fortios" {
  hostname = var.hostname
  token    = var.token
  vdom     = "root"
  insecure = "true"
  #   cabundlefile =  "/path/yourCA.crt"
}

data "fortios_system_interface" "wan" {
  name = "wan1"
}

module "sslvpn" {
  source  = "poroping/sslvpn/fortios"
  version = "0.2.0"

  ssl_interface    = data.fortios_system_interface.wan
}
```

### Example of 'terraform-fortios-sslvpn' module.

```hcl
terraform {
  required_version = ">= 1.0.1"
  backend "local" {}
  required_providers {
    fortios = {
      source  = "poroping/fortios"
      version = "~> 2.0.0"
    }
  }
}

provider "fortios" {
  hostname = var.hostname
  token    = var.token
  vdom     = "root"
  insecure = "true"
  #   cabundlefile =  "/path/yourCA.crt"
}

resource "fortios_system_vdom" "vdom" {
  name = "TEST"
}

resource "fortios_system_interface" "ext" {
  name      = "TF-TEST"
  type      = "vlan"
  vdom      = fortios_system_vdom.vdom.name
  vlanid    = 666
  interface = "wan2"
}

resource "fortios_system_interface" "loopsmcgee" {
  name = "TEST-VPN-LOOP"
  type = "loopback"
  vdom = fortios_system_vdom.vdom.name
}

module "sslvpn" {
  source  = "poroping/sslvpn/fortios"
  version = "0.2.0"

  prefix           = fortios_system_vdom.vdom.name
  ssl_interface    = fortios_system_interface.loopsmcgee
  outside_int_name = fortios_system_interface.ext.name
  vdom             = fortios_system_vdom.vdom.name
  dns_servers      = ["192.168.1.1", "192.168.2.1"]
  has_full_tunnel  = true
  https_redirect   = "disable"
  port             = 9443
}
```

## Providers

| Name | Version |
|------|---------|
| <a name="provider_fortios"></a> [fortios](#provider\_fortios) | >= 2.0.2 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ssl_interface"></a> [ssl\_interface](#input\_ssl\_interface) | Interface object of interface to enable SSLVPN portal. | <pre>object({<br>    type = string,<br>    name = string<br>  })</pre> | n/a | yes |
| <a name="input_dns_servers"></a> [dns\_servers](#input\_dns\_servers) | Set of IPv4 DNS servers. Only two will be used. | `set(string)` | `[]` | no |
| <a name="input_dns_suffixes"></a> [dns\_suffixes](#input\_dns\_suffixes) | Set of DNS suffixes. | `set(string)` | `[]` | no |
| <a name="input_full_address_pool"></a> [full\_address\_pool](#input\_full\_address\_pool) | IPv4 address pool for full tunnel. | `string` | `"10.255.255.128/25"` | no |
| <a name="input_has_full_tunnel"></a> [has\_full\_tunnel](#input\_has\_full\_tunnel) | Setup an second realm with full tunnel enabled. | `bool` | `false` | no |
| <a name="input_https_redirect"></a> [https\_redirect](#input\_https\_redirect) | Redirect of port 80 to SSL-VPN port. | `string` | `"enable"` | no |
| <a name="input_outside_int_name"></a> [outside\_int\_name](#input\_outside\_int\_name) | Name of outside interface if SSLVPN portal not facing internet, ex. enabled on a Loopback. | `string` | `""` | no |
| <a name="input_port"></a> [port](#input\_port) | SSLVPN portal port. | `number` | `443` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Used to prefix all object names. | `string` | `"TF"` | no |
| <a name="input_split_address_pool"></a> [split\_address\_pool](#input\_split\_address\_pool) | IPv4 address pool for split tunnel. | `string` | `"10.255.255.0/25"` | no |
| <a name="input_ssl_servercert_name"></a> [ssl\_servercert\_name](#input\_ssl\_servercert\_name) | Name of certificate object to use on interface. | `string` | `""` | no |
| <a name="input_vdom"></a> [vdom](#input\_vdom) | Name of VDOM. | `string` | `"root"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->