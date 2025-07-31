# Azure DMZ Module Variables
# This file contains all variable definitions for the Azure DMZ (Perimeter Network) module

# Resource Group Variables
variable "create_resource_group" {
  description = "Whether to create a new resource group or use existing one"
  type        = bool
  default     = true
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-dmz-network"
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "East US"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    "Module" = "azure-dmz"
    "ManagedBy" = "terraform"
  }
}

# Virtual Network Variables
variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
  default     = "vnet-dmz"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "dns_servers" {
  description = "Custom DNS servers for the virtual network"
  type        = list(string)
  default     = null
}

variable "enable_ddos_protection" {
  description = "Whether to enable DDoS protection"
  type        = bool
  default     = false
}

variable "ddos_protection_plan_id" {
  description = "ID of the DDoS protection plan"
  type        = string
  default     = null
}

# Public Subnet Variables
variable "public_subnet_name" {
  description = "Name of the public subnet (DMZ)"
  type        = string
  default     = "snet-public-dmz"
}

variable "public_subnet_address_prefixes" {
  description = "Address prefixes for the public subnet"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "public_subnet_service_endpoints" {
  description = "Service endpoints to enable on the public subnet"
  type        = list(string)
  default     = []
}

variable "public_subnet_private_link_service_network_policies_enabled" {
  description = "Whether to enable private link service network policies on the public subnet"
  type        = bool
  default     = true
}

variable "public_subnet_private_endpoint_network_policies_enabled" {
  description = "Whether to enable private endpoint network policies on the public subnet"
  type        = bool
  default     = true
}

# Private Subnets Variables
variable "private_subnets" {
  description = "Map of private subnets to create"
  type = map(object({
    name                                            = string
    address_prefixes                                = list(string)
    service_endpoints                               = optional(list(string), [])
    private_link_service_network_policies_enabled   = optional(bool, true)
    private_endpoint_network_policies_enabled       = optional(bool, true)
    delegation = optional(object({
      name = string
      service_delegation = object({
        name    = string
        actions = list(string)
      })
    }))
  }))
  default = {
    private1 = {
      name             = "snet-private-1"
      address_prefixes = ["10.0.2.0/24"]
    }
    private2 = {
      name             = "snet-private-2"
      address_prefixes = ["10.0.3.0/24"]
    }
  }
}

# Azure Firewall Variables
variable "enable_azure_firewall" {
  description = "Whether to create Azure Firewall"
  type        = bool
  default     = true
}

variable "firewall_subnet_name" {
  description = "Name of the firewall subnet"
  type        = string
  default     = "AzureFirewallSubnet"
}

variable "firewall_subnet_address_prefixes" {
  description = "Address prefixes for the firewall subnet (must be /26 or larger)"
  type        = list(string)
  default     = ["10.0.0.0/26"]
}

variable "firewall_name" {
  description = "Name of the Azure Firewall"
  type        = string
  default     = "fw-dmz"
}

variable "firewall_sku_name" {
  description = "SKU name for Azure Firewall"
  type        = string
  default     = "AZFW_VNet"
  validation {
    condition     = contains(["AZFW_VNet", "AZFW_Hub"], var.firewall_sku_name)
    error_message = "Firewall SKU must be either AZFW_VNet or AZFW_Hub."
  }
}

variable "firewall_sku_tier" {
  description = "SKU tier for Azure Firewall"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Standard", "Premium"], var.firewall_sku_tier)
    error_message = "Firewall tier must be either Standard or Premium."
  }
}

variable "firewall_policy_id" {
  description = "ID of the firewall policy to associate"
  type        = string
  default     = null
}

variable "firewall_threat_intel_mode" {
  description = "Threat intelligence mode for Azure Firewall"
  type        = string
  default     = "Alert"
  validation {
    condition     = contains(["Alert", "Deny", "Off"], var.firewall_threat_intel_mode)
    error_message = "Threat intelligence mode must be Alert, Deny, or Off."
  }
}

variable "firewall_dns_servers" {
  description = "DNS servers for Azure Firewall"
  type        = list(string)
  default     = null
}

variable "firewall_private_ip_ranges" {
  description = "Private IP ranges for Azure Firewall"
  type        = list(string)
  default     = null
}

variable "firewall_additional_ip_configurations" {
  description = "Additional IP configurations for Azure Firewall"
  type = list(object({
    name                 = string
    subnet_id            = string
    public_ip_address_id = string
  }))
  default = []
}

variable "firewall_public_ip_name" {
  description = "Name of the public IP for Azure Firewall"
  type        = string
  default     = "pip-fw-dmz"
}

variable "firewall_public_ip_allocation_method" {
  description = "Allocation method for firewall public IP"
  type        = string
  default     = "Static"
  validation {
    condition     = contains(["Static", "Dynamic"], var.firewall_public_ip_allocation_method)
    error_message = "Allocation method must be either Static or Dynamic."
  }
}

variable "firewall_public_ip_sku" {
  description = "SKU for firewall public IP"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Basic", "Standard"], var.firewall_public_ip_sku)
    error_message = "Public IP SKU must be either Basic or Standard."
  }
}

# NVA Subnets Variables
variable "nva_subnets" {
  description = "Map of NVA subnets to create"
  type = map(object({
    name             = string
    address_prefixes = list(string)
    service_endpoints = optional(list(string), [])
  }))
  default = {
    nva1 = {
      name             = "snet-nva-1"
      address_prefixes = ["10.0.4.0/24"]
    }
    nva2 = {
      name             = "snet-nva-2"
      address_prefixes = ["10.0.5.0/24"]
    }
  }
}

# NVA Instances Variables
variable "nva_instances" {
  description = "Map of NVA instances to create"
  type = map(object({
    vm_name                    = string
    vm_size                    = string
    admin_username             = string
    admin_ssh_public_key       = string
    network_interface_name     = string
    network_interface_ids      = list(string)
    ip_configurations          = list(object({
      name                          = string
      subnet_id                     = string
      private_ip_address_allocation = optional(string, "Dynamic")
      private_ip_address            = optional(string)
      public_ip_address_id          = optional(string)
      primary                       = optional(bool, false)
    }))
    enable_ip_forwarding           = optional(bool, true)
    enable_accelerated_networking  = optional(bool, false)
    os_disk_caching                = optional(string, "ReadWrite")
    os_disk_storage_account_type   = optional(string, "Standard_LRS")
    os_disk_size_gb                = optional(number, 30)
    source_image_reference = object({
      publisher = string
      offer     = string
      sku       = string
      version   = optional(string, "latest")
    })
    custom_data                    = optional(string)
    availability_set_id            = optional(string)
    proximity_placement_group_id   = optional(string)
    identity = optional(object({
      type         = string
      identity_ids = optional(list(string))
    }))
    boot_diagnostics = optional(object({
      storage_account_uri = optional(string)
    }))
  }))
  default = {}
}

variable "nva_public_ips" {
  description = "Map of public IPs for NVAs"
  type = map(object({
    name             = string
    allocation_method = optional(string, "Static")
    sku              = optional(string, "Standard")
  }))
  default = {}
}

# Network Security Groups Variables
variable "public_nsg_name" {
  description = "Name of the public NSG"
  type        = string
  default     = "nsg-public-dmz"
}

variable "public_nsg_rules" {
  description = "Security rules for the public NSG"
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = optional(string, "*")
    destination_port_range     = optional(string, "*")
    source_address_prefix      = optional(string, "*")
    destination_address_prefix = optional(string, "*")
    description                = optional(string)
  }))
  default = [
    {
      name                       = "AllowHTTPS"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      description                = "Allow HTTPS traffic"
    },
    {
      name                       = "AllowHTTP"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      description                = "Allow HTTP traffic"
    },
    {
      name                       = "DenyAllInbound"
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      description                = "Deny all inbound traffic"
    }
  ]
}

variable "private_nsgs" {
  description = "Map of private NSGs to create"
  type = map(object({
    name = string
    security_rules = list(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = optional(string, "*")
      destination_port_range     = optional(string, "*")
      source_address_prefix      = optional(string, "*")
      destination_address_prefix = optional(string, "*")
      description                = optional(string)
    }))
  }))
  default = {}
}

# Route Tables Variables
variable "public_route_table_name" {
  description = "Name of the public route table"
  type        = string
  default     = "rt-public-dmz"
}

variable "public_route_table_disable_bgp_route_propagation" {
  description = "Whether to disable BGP route propagation on public route table"
  type        = bool
  default     = false
}

variable "public_route_table_routes" {
  description = "Routes for the public route table"
  type = list(object({
    name                   = string
    address_prefix         = string
    next_hop_type         = string
    next_hop_in_ip_address = optional(string)
  }))
  default = []
}

variable "private_route_tables" {
  description = "Map of private route tables to create"
  type = map(object({
    name = string
    disable_bgp_route_propagation = optional(bool, false)
    routes = list(object({
      name                   = string
      address_prefix         = string
      next_hop_type         = string
      next_hop_in_ip_address = optional(string)
    }))
  }))
  default = {}
}

# Application Security Groups Variables
variable "application_security_groups" {
  description = "Map of application security groups to create"
  type = map(object({
    name = string
  }))
  default = {}
}

# Network Watcher Variables
variable "enable_network_watcher" {
  description = "Whether to create Network Watcher"
  type        = bool
  default     = true
}

variable "network_watcher_name" {
  description = "Name of the Network Watcher"
  type        = string
  default     = "NetworkWatcher_eastus"
}

variable "network_watcher_flow_logs" {
  description = "Map of Network Watcher flow logs to create"
  type = map(object({
    name = string
    network_security_group_id = string
    storage_account_id        = string
    enabled                   = optional(bool, true)
    version                   = optional(number, 2)
    retention_policy = optional(object({
      enabled = bool
      days    = number
    }))
    traffic_analytics = optional(object({
      enabled               = bool
      workspace_id          = string
      workspace_region      = string
      workspace_resource_id = string
      interval_in_minutes   = optional(number, 10)
    }))
  }))
  default = {}
} 