# Basic Azure DMZ Example
# This example demonstrates a simple DMZ configuration with minimal customization

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

# Basic DMZ Module
module "dmz" {
  source = "../../"

  # Basic configuration
  location            = "East US"
  environment         = "dev"
  resource_group_name = "rg-dmz-basic-example"
  
  # Virtual network
  vnet_name           = "vnet-dmz-basic"
  vnet_address_space  = ["10.0.0.0/16"]
  
  # Enable Azure Firewall
  enable_azure_firewall = true
  
  # Tags
  tags = {
    Environment = "development"
    Project     = "dmz-basic-example"
    Owner       = "network-team"
    CostCenter  = "IT-001"
  }
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

output "firewall_id" {
  description = "ID of the Azure Firewall"
  value       = module.dmz.firewall_id
}

output "network_summary" {
  description = "Summary of the DMZ network configuration"
  value       = module.dmz.network_summary
} 