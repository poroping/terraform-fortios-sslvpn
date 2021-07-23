variable "dns_servers" {
  description = "Set of IPv4 DNS servers. Only two will be used."
  type        = set(string)
  default     = []
}

variable "dns_suffixes" {
  description = "Set of DNS suffixes."
  type        = set(string)
  default     = []
}

variable "has_full_tunnel" {
  description = "Setup an second realm with full tunnel enabled."
  type        = bool
  default     = false
}

variable "https_redirect" {
  description = "Redirect of port 80 to SSL-VPN port."
  type        = string
  default     = "enable"
}

variable "full_address_pool" {
  description = "IPv4 address pool for full tunnel."
  type        = string
  default     = "10.255.255.128/25"
}

variable "outside_int_name" {
  type        = string
  description = "Name of outside interface if SSLVPN portal not facing internet, ex. enabled on a Loopback."
  default     = ""
}

variable "port" {
  description = "SSLVPN portal port."
  type        = number
  default     = 443
}

variable "prefix" {
  description = "Used to prefix all object names."
  type        = string
  default     = "TF"
}

variable "split_address_pool" {
  description = "IPv4 address pool for split tunnel."
  type        = string
  default     = "10.255.255.0/25"
}

variable "ssl_interface" {
  description = "Interface object of interface to enable SSLVPN portal."
  type = object({
    type = string,
    name = string
  })
}

variable "ssl_servercert_name" {
  description = "Name of certificate object to use on interface."
  type        = string
  default     = ""
}

variable "vdom" {
  description = "Name of VDOM."
  type        = string
  default     = "root"
}