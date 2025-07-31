# Advanced Azure DMZ Example
# This example demonstrates a comprehensive DMZ configuration with all features enabled

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
}

# Advanced DMZ Module
module "dmz" {
  source = "../../"

  # Resource group
  create_resource_group = true
  resource_group_name   = "rg-dmz-advanced-example"
  location              = "East US"
  environment           = "prod"

  # Virtual network with DDoS protection
  vnet_name                    = "vnet-dmz-advanced"
  vnet_address_space           = ["10.0.0.0/16"]
  enable_ddos_protection       = true
  ddos_protection_plan_id      = var.ddos_protection_plan_id

  # Custom subnets with service endpoints
  public_subnet_address_prefixes  = ["10.0.1.0/24"]
  public_subnet_service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]

  private_subnets = {
    web = {
      name             = "snet-web"
      address_prefixes = ["10.0.2.0/24"]
      service_endpoints = ["Microsoft.KeyVault"]
    }
    app = {
      name             = "snet-app"
      address_prefixes = ["10.0.3.0/24"]
      service_endpoints = ["Microsoft.KeyVault", "Microsoft.Sql"]
    }
    data = {
      name             = "snet-data"
      address_prefixes = ["10.0.4.0/24"]
      service_endpoints = ["Microsoft.KeyVault", "Microsoft.Sql", "Microsoft.Storage"]
    }
  }

  # NVA subnets
  nva_subnets = {
    nva1 = {
      name             = "snet-nva-1"
      address_prefixes = ["10.0.5.0/24"]
    }
    nva2 = {
      name             = "snet-nva-2"
      address_prefixes = ["10.0.6.0/24"]
    }
  }

  # Azure Firewall configuration
  enable_azure_firewall = true
  firewall_sku_tier     = "Premium"
  firewall_threat_intel_mode = "Deny"

  # Custom NSG rules for public subnet
  public_nsg_rules = [
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
      name                       = "AllowSSH"
      priority                   = 120
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "10.0.0.0/8"
      destination_address_prefix = "*"
      description                = "Allow SSH from internal networks"
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
      description                = "Deny all other inbound traffic"
    }
  ]

  # Private NSGs
  private_nsgs = {
    web = {
      name = "nsg-web"
      security_rules = [
        {
          name                       = "AllowWebTraffic"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "80,443"
          source_address_prefix      = "10.0.1.0/24"
          destination_address_prefix = "*"
          description                = "Allow web traffic from DMZ"
        },
        {
          name                       = "AllowSSH"
          priority                   = 110
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "22"
          source_address_prefix      = "10.0.0.0/8"
          destination_address_prefix = "*"
          description                = "Allow SSH from internal networks"
        }
      ]
    }
    app = {
      name = "nsg-app"
      security_rules = [
        {
          name                       = "AllowAppTraffic"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "8080,8443"
          source_address_prefix      = "10.0.2.0/24"
          destination_address_prefix = "*"
          description                = "Allow app traffic from web tier"
        }
      ]
    }
  }

  # Route tables
  public_route_table_routes = [
    {
      name                   = "ToFirewall"
      address_prefix         = "0.0.0.0/0"
      next_hop_type         = "VirtualAppliance"
      next_hop_in_ip_address = "10.0.0.4" # Firewall private IP
    }
  ]

  private_route_tables = {
    web = {
      name = "rt-web"
      routes = [
        {
          name                   = "ToFirewall"
          address_prefix         = "0.0.0.0/0"
          next_hop_type         = "VirtualAppliance"
          next_hop_in_ip_address = "10.0.0.4"
        }
      ]
    }
    app = {
      name = "rt-app"
      routes = [
        {
          name                   = "ToFirewall"
          address_prefix         = "0.0.0.0/0"
          next_hop_type         = "VirtualAppliance"
          next_hop_in_ip_address = "10.0.0.4"
        }
      ]
    }
  }

  # NVA instances
  nva_instances = {
    nva1 = {
      vm_name                = "nva-01"
      vm_size                = "Standard_D2s_v3"
      admin_username         = "adminuser"
      admin_ssh_public_key   = var.ssh_public_key
      network_interface_name = "nic-nva-01"
      network_interface_ids  = ["nic-nva-01"]
      ip_configurations = [
        {
          name      = "ipconfig1"
          subnet_id = "snet-nva-1"
          primary   = true
        }
      ]
      source_image_reference = {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
      }
      enable_ip_forwarding = true
    }
    nva2 = {
      vm_name                = "nva-02"
      vm_size                = "Standard_D2s_v3"
      admin_username         = "adminuser"
      admin_ssh_public_key   = var.ssh_public_key
      network_interface_name = "nic-nva-02"
      network_interface_ids  = ["nic-nva-02"]
      ip_configurations = [
        {
          name      = "ipconfig1"
          subnet_id = "snet-nva-2"
          primary   = true
        }
      ]
      source_image_reference = {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
      }
      enable_ip_forwarding = true
    }
  }

  # NVA public IPs
  nva_public_ips = {
    nva1_pip = {
      name = "pip-nva-01"
    }
    nva2_pip = {
      name = "pip-nva-02"
    }
  }

  # Application Security Groups
  application_security_groups = {
    web_servers = {
      name = "asg-web-servers"
    }
    app_servers = {
      name = "asg-app-servers"
    }
    database_servers = {
      name = "asg-database-servers"
    }
  }

  # Network Watcher with flow logs
  enable_network_watcher = true
  network_watcher_flow_logs = {
    public_flow_log = {
      name = "flow-log-public"
      network_security_group_id = "nsg-public-dmz"
      storage_account_id        = var.storage_account_id
      enabled                   = true
      version                   = 2
      retention_policy = {
        enabled = true
        days    = 30
      }
      traffic_analytics = {
        enabled               = true
        workspace_id          = var.log_analytics_workspace_id
        workspace_region      = "East US"
        workspace_resource_id = var.log_analytics_workspace_resource_id
        interval_in_minutes   = 10
      }
    }
  }

  # Tags
  tags = {
    Environment = "production"
    Project     = "dmz-advanced-example"
    Owner       = "network-team"
    CostCenter  = "IT-001"
    Compliance  = "PCI-DSS"
  }
}

# Variables
variable "ddos_protection_plan_id" {
  description = "ID of the DDoS protection plan"
  type        = string
  default     = null
}

variable "ssh_public_key" {
  description = "SSH public key for NVA instances"
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC..."
}

variable "storage_account_id" {
  description = "Storage account ID for Network Watcher flow logs"
  type        = string
  default     = null
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for traffic analytics"
  type        = string
  default     = null
}

variable "log_analytics_workspace_resource_id" {
  description = "Log Analytics workspace resource ID for traffic analytics"
  type        = string
  default     = null
}

# Outputs
output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.dmz.resource_group_name
}

output "virtual_network_id" {
  description = "ID of the virtual network"
  value       = module.dmz.virtual_network_id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = module.dmz.public_subnet_id
}

output "private_subnets" {
  description = "Map of private subnets"
  value       = module.dmz.private_subnets
}

output "firewall_id" {
  description = "ID of the Azure Firewall"
  value       = module.dmz.firewall_id
}

output "firewall_private_ip" {
  description = "Private IP address of the Azure Firewall"
  value       = module.dmz.firewall_private_ip
}

output "nva_instances" {
  description = "Map of NVA instances"
  value       = module.dmz.nva_instances
}

output "network_summary" {
  description = "Summary of the DMZ network configuration"
  value       = module.dmz.network_summary
}

output "security_summary" {
  description = "Security configuration summary"
  value       = module.dmz.security_summary
}

output "connectivity_info" {
  description = "Network connectivity information"
  value       = module.dmz.connectivity_info
} 