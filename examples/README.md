# Azure DMZ Module Examples

This directory contains example configurations for the Azure DMZ (Perimeter Network) Terraform module.

## Examples Overview

### Basic Example (`basic/`)

A simple DMZ configuration with minimal customization that demonstrates the core functionality of the module.

**Features:**
- Basic virtual network with default subnets
- Azure Firewall enabled
- Default NSG rules
- Minimal configuration required

**Use Case:** Quick deployment for testing or development environments.

### Advanced Example (`advanced/`)

A comprehensive DMZ configuration with all features enabled and extensive customization options.

**Features:**
- Custom subnets with service endpoints
- Multiple private subnets (web, app, data tiers)
- NVA subnets and instances
- Custom NSG rules for each subnet
- Route tables with firewall routing
- Application Security Groups
- Network Watcher with flow logs and traffic analytics
- DDoS protection
- Premium Azure Firewall

**Use Case:** Production environments requiring high security and comprehensive monitoring.

## Getting Started

### Prerequisites

1. **Azure CLI**: Install and authenticate with Azure
   ```bash
   az login
   az account set --subscription "your-subscription-id"
   ```

2. **Terraform**: Install Terraform (version >= 1.0)
   ```bash
   # Download from https://www.terraform.io/downloads.html
   # or use package manager
   ```

3. **SSH Key Pair**: Generate SSH key for NVA instances (for advanced example)
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/azure_dmz_key
   ```

### Running the Basic Example

1. Navigate to the basic example directory:
   ```bash
   cd examples/basic
   ```

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Review the plan:
   ```bash
   terraform plan
   ```

4. Apply the configuration:
   ```bash
   terraform apply
   ```

### Running the Advanced Example

1. Navigate to the advanced example directory:
   ```bash
   cd examples/advanced
   ```

2. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. Edit `terraform.tfvars` with your specific values:
   ```hcl
   # Update these values according to your environment
   ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC..."
   
   # Optional: Add DDoS protection plan ID
   # ddos_protection_plan_id = "/subscriptions/..."
   
   # Optional: Add storage account for flow logs
   # storage_account_id = "/subscriptions/..."
   ```

4. Initialize Terraform:
   ```bash
   terraform init
   ```

5. Review the plan:
   ```bash
   terraform plan
   ```

6. Apply the configuration:
   ```bash
   terraform apply
   ```

## Configuration Options

### Basic Example Customization

The basic example can be customized by modifying the `main.tf` file:

```hcl
module "dmz" {
  source = "../../"

  # Change location
  location = "West US 2"
  
  # Change resource group name
  resource_group_name = "rg-my-dmz"
  
  # Change virtual network address space
  vnet_address_space = ["172.16.0.0/16"]
  
  # Add custom tags
  tags = {
    Environment = "development"
    Project     = "my-project"
    Owner       = "my-team"
  }
}
```

### Advanced Example Customization

The advanced example offers extensive customization options:

#### Subnet Configuration
```hcl
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
}
```

#### NSG Rules
```hcl
public_nsg_rules = [
  {
    name                       = "AllowHTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
]
```

#### Route Tables
```hcl
public_route_table_routes = [
  {
    name                   = "ToFirewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type         = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.0.4"
  }
]
```

## Outputs

After successful deployment, you can view the outputs:

```bash
terraform output
```

Key outputs include:
- `resource_group_name`: Name of the created resource group
- `virtual_network_id`: ID of the virtual network
- `public_subnet_id`: ID of the public subnet
- `firewall_id`: ID of the Azure Firewall
- `network_summary`: Comprehensive network configuration summary
- `security_summary`: Security configuration summary
- `connectivity_info`: Network connectivity information

## Cleanup

To destroy the infrastructure:

```bash
terraform destroy
```

**Warning**: This will delete all resources created by the module. Make sure you have backups of any important data.

## Troubleshooting

### Common Issues

1. **Provider Version Conflicts**
   - Ensure you're using the correct Azure provider version
   - Update the provider version in `versions.tf` if needed

2. **SSH Key Issues**
   - Ensure the SSH public key is properly formatted
   - Verify the key doesn't contain extra characters or line breaks

3. **Resource Name Conflicts**
   - Azure resource names must be unique globally
   - Add random suffixes or use different naming conventions

4. **Permission Issues**
   - Ensure your Azure account has sufficient permissions
   - Check if you can create resources in the target subscription

### Getting Help

- Review the main module README for detailed documentation
- Check Azure documentation for specific resource configurations
- Use `terraform plan` to preview changes before applying
- Enable Terraform debug logging: `export TF_LOG=DEBUG`

## Security Considerations

- **SSH Keys**: Store SSH private keys securely and never commit them to version control
- **Secrets**: Use Azure Key Vault for storing sensitive information
- **Access Control**: Implement proper RBAC for Azure resources
- **Monitoring**: Enable Network Watcher and flow logs for security monitoring
- **Compliance**: Review and adjust configurations for your compliance requirements 