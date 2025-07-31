# Azure DMZ Module Outputs
# This file contains all output definitions for the Azure DMZ (Perimeter Network) module

# Resource Group Outputs
output "resource_group_id" {
  description = "ID of the resource group"
  value       = var.create_resource_group ? azurerm_resource_group.dmz[0].id : null
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = var.create_resource_group ? azurerm_resource_group.dmz[0].name : var.resource_group_name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = var.create_resource_group ? azurerm_resource_group.dmz[0].location : var.location
}

# Virtual Network Outputs
output "virtual_network_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.dmz.id
}

output "virtual_network_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.dmz.name
}

output "virtual_network_address_space" {
  description = "Address space of the virtual network"
  value       = azurerm_virtual_network.dmz.address_space
}

output "virtual_network_dns_servers" {
  description = "DNS servers of the virtual network"
  value       = azurerm_virtual_network.dmz.dns_servers
}

# Public Subnet Outputs
output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = azurerm_subnet.public.id
}

output "public_subnet_name" {
  description = "Name of the public subnet"
  value       = azurerm_subnet.public.name
}

output "public_subnet_address_prefixes" {
  description = "Address prefixes of the public subnet"
  value       = azurerm_subnet.public.address_prefixes
}

# Private Subnets Outputs
output "private_subnets" {
  description = "Map of private subnets"
  value = {
    for k, v in azurerm_subnet.private : k => {
      id                = v.id
      name              = v.name
      address_prefixes  = v.address_prefixes
      service_endpoints = v.service_endpoints
    }
  }
}

output "private_subnet_ids" {
  description = "IDs of all private subnets"
  value       = values(azurerm_subnet.private)[*].id
}

output "private_subnet_names" {
  description = "Names of all private subnets"
  value       = values(azurerm_subnet.private)[*].name
}

# Azure Firewall Outputs
output "firewall_id" {
  description = "ID of the Azure Firewall"
  value       = var.enable_azure_firewall ? azurerm_firewall.dmz[0].id : null
}

output "firewall_name" {
  description = "Name of the Azure Firewall"
  value       = var.enable_azure_firewall ? azurerm_firewall.dmz[0].name : null
}

output "firewall_private_ip" {
  description = "Private IP address of the Azure Firewall"
  value       = var.enable_azure_firewall ? azurerm_firewall.dmz[0].ip_configuration[0].private_ip_address : null
}

output "firewall_public_ip" {
  description = "Public IP address of the Azure Firewall"
  value       = var.enable_azure_firewall ? azurerm_public_ip.firewall[0].ip_address : null
}

output "firewall_public_ip_id" {
  description = "ID of the public IP for Azure Firewall"
  value       = var.enable_azure_firewall ? azurerm_public_ip.firewall[0].id : null
}

output "firewall_subnet_id" {
  description = "ID of the firewall subnet"
  value       = var.enable_azure_firewall ? azurerm_subnet.firewall[0].id : null
}

# NVA Subnets Outputs
output "nva_subnets" {
  description = "Map of NVA subnets"
  value = {
    for k, v in azurerm_subnet.nva : k => {
      id               = v.id
      name             = v.name
      address_prefixes = v.address_prefixes
    }
  }
}

output "nva_subnet_ids" {
  description = "IDs of all NVA subnets"
  value       = values(azurerm_subnet.nva)[*].id
}

# NVA Instances Outputs
output "nva_instances" {
  description = "Map of NVA instances"
  value = {
    for k, v in azurerm_linux_virtual_machine.nva : k => {
      id                = v.id
      name              = v.name
      private_ip_address = v.private_ip_address
      public_ip_address  = v.public_ip_address
      vm_size           = v.size
    }
  }
}

output "nva_network_interfaces" {
  description = "Map of NVA network interfaces"
  value = {
    for k, v in azurerm_network_interface.nva : k => {
      id                = v.id
      name              = v.name
      private_ip_address = v.private_ip_address
      mac_address       = v.mac_address
    }
  }
}

output "nva_public_ips" {
  description = "Map of NVA public IPs"
  value = {
    for k, v in azurerm_public_ip.nva : k => {
      id          = v.id
      name        = v.name
      ip_address  = v.ip_address
      fqdn        = v.fqdn
    }
  }
}

# Network Security Groups Outputs
output "public_nsg_id" {
  description = "ID of the public NSG"
  value       = azurerm_network_security_group.public.id
}

output "public_nsg_name" {
  description = "Name of the public NSG"
  value       = azurerm_network_security_group.public.name
}

output "private_nsgs" {
  description = "Map of private NSGs"
  value = {
    for k, v in azurerm_network_security_group.private : k => {
      id   = v.id
      name = v.name
    }
  }
}

output "private_nsg_ids" {
  description = "IDs of all private NSGs"
  value       = values(azurerm_network_security_group.private)[*].id
}

# Route Tables Outputs
output "public_route_table_id" {
  description = "ID of the public route table"
  value       = azurerm_route_table.public.id
}

output "public_route_table_name" {
  description = "Name of the public route table"
  value       = azurerm_route_table.public.name
}

output "private_route_tables" {
  description = "Map of private route tables"
  value = {
    for k, v in azurerm_route_table.private : k => {
      id   = v.id
      name = v.name
    }
  }
}

output "private_route_table_ids" {
  description = "IDs of all private route tables"
  value       = values(azurerm_route_table.private)[*].id
}

# Application Security Groups Outputs
output "application_security_groups" {
  description = "Map of application security groups"
  value = {
    for k, v in azurerm_application_security_group.dmz : k => {
      id   = v.id
      name = v.name
    }
  }
}

output "application_security_group_ids" {
  description = "IDs of all application security groups"
  value       = values(azurerm_application_security_group.dmz)[*].id
}

# Network Watcher Outputs
output "network_watcher_id" {
  description = "ID of the Network Watcher"
  value       = var.enable_network_watcher ? azurerm_network_watcher.dmz[0].id : null
}

output "network_watcher_name" {
  description = "Name of the Network Watcher"
  value       = var.enable_network_watcher ? azurerm_network_watcher.dmz[0].name : null
}

output "network_watcher_flow_logs" {
  description = "Map of Network Watcher flow logs"
  value = {
    for k, v in azurerm_network_watcher_flow_log.dmz : k => {
      id   = v.id
      name = v.name
    }
  }
}

# Comprehensive Network Information
output "network_summary" {
  description = "Summary of the DMZ network configuration"
  value = {
    virtual_network = {
      id             = azurerm_virtual_network.dmz.id
      name           = azurerm_virtual_network.dmz.name
      address_space  = azurerm_virtual_network.dmz.address_space
      location       = azurerm_virtual_network.dmz.location
    }
    subnets = {
      public_count  = 1
      private_count = length(azurerm_subnet.private)
      nva_count     = length(azurerm_subnet.nva)
      firewall_count = var.enable_azure_firewall ? 1 : 0
    }
    security = {
      public_nsg_id  = azurerm_network_security_group.public.id
      private_nsg_count = length(azurerm_network_security_group.private)
      asg_count = length(azurerm_application_security_group.dmz)
    }
    routing = {
      public_route_table_id = azurerm_route_table.public.id
      private_route_table_count = length(azurerm_route_table.private)
    }
    firewall = var.enable_azure_firewall ? {
      id = azurerm_firewall.dmz[0].id
      name = azurerm_firewall.dmz[0].name
      private_ip = azurerm_firewall.dmz[0].ip_configuration[0].private_ip_address
      public_ip = azurerm_public_ip.firewall[0].ip_address
    } : null
    nva_instances = {
      count = length(azurerm_linux_virtual_machine.nva)
      instances = {
        for k, v in azurerm_linux_virtual_machine.nva : k => {
          name = v.name
          private_ip = v.private_ip_address
          public_ip = v.public_ip_address
        }
      }
    }
  }
}

# Security Information
output "security_summary" {
  description = "Security configuration summary"
  value = {
    public_nsg_rules_count = length(var.public_nsg_rules)
    private_nsgs = {
      for k, v in var.private_nsgs : k => length(v.security_rules)
    }
    ddos_protection_enabled = var.enable_ddos_protection
    firewall_enabled = var.enable_azure_firewall
    network_watcher_enabled = var.enable_network_watcher
  }
}

# Connectivity Information
output "connectivity_info" {
  description = "Network connectivity information"
  value = {
    public_subnet_cidr = azurerm_subnet.public.address_prefixes[0]
    private_subnet_cidrs = {
      for k, v in azurerm_subnet.private : k => v.address_prefixes[0]
    }
    nva_subnet_cidrs = {
      for k, v in azurerm_subnet.nva : k => v.address_prefixes[0]
    }
    firewall_subnet_cidr = var.enable_azure_firewall ? azurerm_subnet.firewall[0].address_prefixes[0] : null
  }
} 