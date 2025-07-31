# Azure DMZ (Perimeter Network) Terraform Module

This Terraform module creates a comprehensive Azure DMZ (Perimeter Network) architecture with Azure Firewall, Network Virtual Appliances (NVAs), and proper network segmentation for enhanced security.

## Architecture Overview

The module creates a secure DMZ architecture with the following components:

- **Virtual Network** with customizable address space
- **Public Subnet (DMZ)** for internet-facing resources
- **Private Subnets** for internal resources
- **Azure Firewall** for centralized network security
- **Network Virtual Appliances (NVAs)** for additional security controls
- **Network Security Groups (NSGs)** for subnet-level security
- **Route Tables** for traffic control and routing
- **Application Security Groups** for micro-segmentation
- **Network Watcher** for monitoring and diagnostics

## Features

- ✅ **Modular Design**: Highly customizable with extensive variable options
- ✅ **Security-First**: Implements defense-in-depth security principles
- ✅ **Scalable**: Supports multiple subnets, NVAs, and security groups
- ✅ **Monitoring**: Integrated Network Watcher with flow logs
- ✅ **Best Practices**: Follows Azure networking and security best practices
- ✅ **Flexible**: Optional resource creation with conditional logic

## Usage

### Basic Example

```hcl
module "dmz" {
  source = "./tfm-azure-dmz"

  # Basic configuration
  location            = "East US"
  environment         = "prod"
  resource_group_name = "rg-dmz-network"
  
  # Virtual network
  vnet_name           = "vnet-dmz"
  vnet_address_space  = ["10.0.0.0/16"]
  
  # Enable Azure Firewall
  enable_azure_firewall = true
  
  # Tags
  tags = {
    Environment = "production"
    Project     = "dmz-network"
    Owner       = "network-team"
  }
}
```

### Advanced Example with Custom Configuration

```hcl
module "dmz" {
  source = "./tfm-azure-dmz"

  # Resource group
  create_resource_group = true
  resource_group_name   = "rg-dmz-network"
  location              = "East US"
  environment           = "prod"

  # Virtual network with DDoS protection
  vnet_name                    = "vnet-dmz"
  vnet_address_space           = ["10.0.0.0/16"]
  enable_ddos_protection       = true
  ddos_protection_plan_id      = "/subscriptions/.../ddosProtectionPlans/ddos-plan"

  # Custom subnets
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
  }

  # NVA instances
  nva_instances = {
    nva1 = {
      vm_name                = "nva-01"
      vm_size                = "Standard_D2s_v3"
      admin_username         = "adminuser"
      admin_ssh_public_key   = file("~/.ssh/id_rsa.pub")
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
  }

  # Network Watcher with flow logs
  enable_network_watcher = true
  network_watcher_flow_logs = {
    public_flow_log = {
      name = "flow-log-public"
      network_security_group_id = "nsg-public-dmz"
      storage_account_id        = "/subscriptions/.../storageAccounts/staccount"
      enabled                   = true
      version                   = 2
      retention_policy = {
        enabled = true
        days    = 30
      }
    }
  }

  # Tags
  tags = {
    Environment = "production"
    Project     = "dmz-network"
    Owner       = "network-team"
    CostCenter  = "IT-001"
  }
}
```

## Inputs

### Resource Group Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| create_resource_group | Whether to create a new resource group or use existing one | `bool` | `true` | no |
| resource_group_name | Name of the resource group | `string` | `"rg-dmz-network"` | no |
| location | Azure region for all resources | `string` | `"East US"` | no |
| environment | Environment name (e.g., dev, staging, prod) | `string` | `"dev"` | no |
| tags | Tags to apply to all resources | `map(string)` | `{"Module" = "azure-dmz", "ManagedBy" = "terraform"}` | no |

### Virtual Network Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| vnet_name | Name of the virtual network | `string` | `"vnet-dmz"` | no |
| vnet_address_space | Address space for the virtual network | `list(string)` | `["10.0.0.0/16"]` | no |
| dns_servers | Custom DNS servers for the virtual network | `list(string)` | `null` | no |
| enable_ddos_protection | Whether to enable DDoS protection | `bool` | `false` | no |
| ddos_protection_plan_id | ID of the DDoS protection plan | `string` | `null` | no |

### Subnet Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| public_subnet_name | Name of the public subnet (DMZ) | `string` | `"snet-public-dmz"` | no |
| public_subnet_address_prefixes | Address prefixes for the public subnet | `list(string)` | `["10.0.1.0/24"]` | no |
| public_subnet_service_endpoints | Service endpoints to enable on the public subnet | `list(string)` | `[]` | no |
| private_subnets | Map of private subnets to create | `map(object)` | See variables.tf | no |
| nva_subnets | Map of NVA subnets to create | `map(object)` | See variables.tf | no |

### Azure Firewall Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enable_azure_firewall | Whether to create Azure Firewall | `bool` | `true` | no |
| firewall_name | Name of the Azure Firewall | `string` | `"fw-dmz"` | no |
| firewall_sku_name | SKU name for Azure Firewall | `string` | `"AZFW_VNet"` | no |
| firewall_sku_tier | SKU tier for Azure Firewall | `string` | `"Standard"` | no |
| firewall_threat_intel_mode | Threat intelligence mode for Azure Firewall | `string` | `"Alert"` | no |

### Network Security Groups Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| public_nsg_name | Name of the public NSG | `string` | `"nsg-public-dmz"` | no |
| public_nsg_rules | Security rules for the public NSG | `list(object)` | See variables.tf | no |
| private_nsgs | Map of private NSGs to create | `map(object)` | `{}` | no |

### Route Tables Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| public_route_table_name | Name of the public route table | `string` | `"rt-public-dmz"` | no |
| public_route_table_routes | Routes for the public route table | `list(object)` | `[]` | no |
| private_route_tables | Map of private route tables to create | `map(object)` | `{}` | no |

### NVA Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| nva_instances | Map of NVA instances to create | `map(object)` | `{}` | no |
| nva_public_ips | Map of public IPs for NVAs | `map(object)` | `{}` | no |

### Network Watcher Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enable_network_watcher | Whether to create Network Watcher | `bool` | `true` | no |
| network_watcher_name | Name of the Network Watcher | `string` | `"NetworkWatcher_eastus"` | no |
| network_watcher_flow_logs | Map of Network Watcher flow logs to create | `map(object)` | `{}` | no |

## Outputs

### Resource Information

| Name | Description |
|------|-------------|
| resource_group_id | ID of the resource group |
| virtual_network_id | ID of the virtual network |
| public_subnet_id | ID of the public subnet |
| private_subnets | Map of private subnets |
| firewall_id | ID of the Azure Firewall |
| nva_instances | Map of NVA instances |

### Security Information

| Name | Description |
|------|-------------|
| public_nsg_id | ID of the public NSG |
| private_nsgs | Map of private NSGs |
| application_security_groups | Map of application security groups |

### Network Information

| Name | Description |
|------|-------------|
| public_route_table_id | ID of the public route table |
| private_route_tables | Map of private route tables |
| network_summary | Summary of the DMZ network configuration |
| security_summary | Security configuration summary |
| connectivity_info | Network connectivity information |

## Architecture Diagram

```
Internet
    │
    ▼
┌─────────────────┐
│   Azure Load    │
│   Balancer      │
└─────────────────┘
    │
    ▼
┌─────────────────┐    ┌─────────────────┐
│   Public Subnet │    │  Azure Firewall │
│   (DMZ)         │◄──►│                 │
│   10.0.1.0/24   │    │  10.0.0.0/26   │
└─────────────────┘    └─────────────────┘
    │                        │
    ▼                        ▼
┌─────────────────┐    ┌─────────────────┐
│   NVA Subnets   │    │  Private        │
│   10.0.4.0/24   │    │  Subnets        │
│   10.0.5.0/24   │    │  10.0.2.0/24   │
└─────────────────┘    │  10.0.3.0/24   │
    │                  └─────────────────┘
    ▼
┌─────────────────┐
│   Private       │
│   Subnets       │
│   10.0.2.0/24   │
│   10.0.3.0/24   │
└─────────────────┘
```

## Security Best Practices

This module implements several security best practices:

1. **Network Segmentation**: Separate public (DMZ) and private subnets
2. **Defense in Depth**: Multiple layers of security (NSGs, Firewall, NVAs)
3. **Least Privilege**: Restrictive NSG rules with explicit allow/deny
4. **Monitoring**: Network Watcher with flow logs for traffic analysis
5. **Threat Protection**: Azure Firewall with threat intelligence
6. **Micro-segmentation**: Application Security Groups for fine-grained control

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| azurerm | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | ~> 3.0 |

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This module is licensed under the MIT License. See LICENSE file for details.

## Support

For issues and questions:
- Create an issue in the repository
- Contact the network team
- Review Azure documentation for specific resource configurations