# Azure DMZ (Perimeter Network) Module
# This module creates a comprehensive DMZ architecture with Azure Firewall, NVAs, and proper network segmentation

# Resource Group
resource "azurerm_resource_group" "dmz" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Virtual Network
resource "azurerm_virtual_network" "dmz" {
  name                = var.vnet_name
  resource_group_name = var.create_resource_group ? azurerm_resource_group.dmz[0].name : var.resource_group_name
  location            = var.create_resource_group ? azurerm_resource_group.dmz[0].location : var.location
  address_space       = var.vnet_address_space
  dns_servers         = var.dns_servers
  tags                = merge(var.tags, {
    "Purpose" = "DMZ Network"
    "Environment" = var.environment
  })

  dynamic "ddos_protection_plan" {
    for_each = var.enable_ddos_protection ? [1] : []
    content {
      id     = var.ddos_protection_plan_id
      enable = true
    }
  }
}

# Public Subnet (DMZ)
resource "azurerm_subnet" "public" {
  name                 = var.public_subnet_name
  resource_group_name  = azurerm_virtual_network.dmz.resource_group_name
  virtual_network_name = azurerm_virtual_network.dmz.name
  address_prefixes     = var.public_subnet_address_prefixes

  # Service endpoints for enhanced security
  dynamic "service_endpoints" {
    for_each = var.public_subnet_service_endpoints
    content {
      service = service_endpoints.value
    }
  }

  # Private link service network policies
  private_link_service_network_policies_enabled = var.public_subnet_private_link_service_network_policies_enabled
}

# Private Subnets
resource "azurerm_subnet" "private" {
  for_each = var.private_subnets

  name                 = each.value.name
  resource_group_name  = azurerm_virtual_network.dmz.resource_group_name
  virtual_network_name = azurerm_virtual_network.dmz.name
  address_prefixes     = each.value.address_prefixes

  # Service endpoints
  dynamic "service_endpoints" {
    for_each = lookup(each.value, "service_endpoints", [])
    content {
      service = service_endpoints.value
    }
  }

  # Private link service network policies
  private_link_service_network_policies_enabled = lookup(each.value, "private_link_service_network_policies_enabled", true)

  # Network security group association
  dynamic "delegation" {
    for_each = lookup(each.value, "delegation", null) != null ? [each.value.delegation] : []
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = delegation.value.service_delegation.actions
      }
    }
  }
}

# Azure Firewall Subnet (requires /26 or larger)
resource "azurerm_subnet" "firewall" {
  count = var.enable_azure_firewall ? 1 : 0

  name                 = var.firewall_subnet_name
  resource_group_name  = azurerm_virtual_network.dmz.resource_group_name
  virtual_network_name = azurerm_virtual_network.dmz.name
  address_prefixes     = var.firewall_subnet_address_prefixes
}

# Network Virtual Appliance Subnets
resource "azurerm_subnet" "nva" {
  for_each = var.nva_subnets

  name                 = each.value.name
  resource_group_name  = azurerm_virtual_network.dmz.resource_group_name
  virtual_network_name = azurerm_virtual_network.dmz.name
  address_prefixes     = each.value.address_prefixes

  # Service endpoints
  dynamic "service_endpoints" {
    for_each = lookup(each.value, "service_endpoints", [])
    content {
      service = service_endpoints.value
    }
  }
}

# Network Security Groups
resource "azurerm_network_security_group" "public" {
  name                = var.public_nsg_name
  location            = azurerm_virtual_network.dmz.location
  resource_group_name = azurerm_virtual_network.dmz.resource_group_name
  tags                = merge(var.tags, { "Purpose" = "Public DMZ NSG" })

  dynamic "security_rule" {
    for_each = var.public_nsg_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = lookup(security_rule.value, "source_port_range", "*")
      destination_port_range     = lookup(security_rule.value, "destination_port_range", "*")
      source_address_prefix      = lookup(security_rule.value, "source_address_prefix", "*")
      destination_address_prefix = lookup(security_rule.value, "destination_address_prefix", "*")
      description                = lookup(security_rule.value, "description", null)
    }
  }
}

resource "azurerm_network_security_group" "private" {
  for_each = var.private_nsgs

  name                = each.value.name
  location            = azurerm_virtual_network.dmz.location
  resource_group_name = azurerm_virtual_network.dmz.resource_group_name
  tags                = merge(var.tags, { "Purpose" = "Private NSG" })

  dynamic "security_rule" {
    for_each = lookup(each.value, "security_rules", [])
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = lookup(security_rule.value, "source_port_range", "*")
      destination_port_range     = lookup(security_rule.value, "destination_port_range", "*")
      source_address_prefix      = lookup(security_rule.value, "source_address_prefix", "*")
      destination_address_prefix = lookup(security_rule.value, "destination_address_prefix", "*")
      description                = lookup(security_rule.value, "description", null)
    }
  }
}

# NSG Associations
resource "azurerm_subnet_network_security_group_association" "public" {
  subnet_id                 = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.public.id
}

resource "azurerm_subnet_network_security_group_association" "private" {
  for_each = var.private_nsgs

  subnet_id                 = azurerm_subnet.private[each.key].id
  network_security_group_id = azurerm_network_security_group.private[each.key].id
}

# Route Tables
resource "azurerm_route_table" "public" {
  name                = var.public_route_table_name
  location            = azurerm_virtual_network.dmz.location
  resource_group_name = azurerm_virtual_network.dmz.resource_group_name
  tags                = merge(var.tags, { "Purpose" = "Public Route Table" })

  dynamic "route" {
    for_each = var.public_route_table_routes
    content {
      name                   = route.value.name
      address_prefix         = route.value.address_prefix
      next_hop_type         = route.value.next_hop_type
      next_hop_in_ip_address = lookup(route.value, "next_hop_in_ip_address", null)
    }
  }
}

resource "azurerm_route_table" "private" {
  for_each = var.private_route_tables

  name                = each.value.name
  location            = azurerm_virtual_network.dmz.location
  resource_group_name = azurerm_virtual_network.dmz.resource_group_name
  tags                = merge(var.tags, { "Purpose" = "Private Route Table" })

  dynamic "route" {
    for_each = lookup(each.value, "routes", [])
    content {
      name                   = route.value.name
      address_prefix         = route.value.address_prefix
      next_hop_type         = route.value.next_hop_type
      next_hop_in_ip_address = lookup(route.value, "next_hop_in_ip_address", null)
    }
  }
}

# Route Table Associations
resource "azurerm_subnet_route_table_association" "public" {
  subnet_id      = azurerm_subnet.public.id
  route_table_id = azurerm_route_table.public.id
}

resource "azurerm_subnet_route_table_association" "private" {
  for_each = var.private_route_tables

  subnet_id      = azurerm_subnet.private[each.key].id
  route_table_id = azurerm_route_table.private[each.key].id
}

# Azure Firewall
resource "azurerm_firewall" "dmz" {
  count = var.enable_azure_firewall ? 1 : 0

  name                = var.firewall_name
  resource_group_name = azurerm_virtual_network.dmz.resource_group_name
  location            = azurerm_virtual_network.dmz.location
  sku_name            = var.firewall_sku_name
  sku_tier            = var.firewall_sku_tier
  tags                = merge(var.tags, { "Purpose" = "DMZ Firewall" })

  ip_configuration {
    name                 = "firewall-ip-config"
    subnet_id            = azurerm_subnet.firewall[0].id
    public_ip_address_id = azurerm_public_ip.firewall[0].id
  }

  dynamic "ip_configuration" {
    for_each = var.firewall_additional_ip_configurations
    content {
      name                 = ip_configuration.value.name
      subnet_id            = ip_configuration.value.subnet_id
      public_ip_address_id = ip_configuration.value.public_ip_address_id
    }
  }

  # Firewall Policy
  dynamic "firewall_policy_id" {
    for_each = var.firewall_policy_id != null ? [var.firewall_policy_id] : []
    content {
      firewall_policy_id = firewall_policy_id.value
    }
  }

  # Threat Intelligence Mode
  threat_intel_mode = var.firewall_threat_intel_mode

  # DNS Settings
  dynamic "dns_servers" {
    for_each = var.firewall_dns_servers != null ? [var.firewall_dns_servers] : []
    content {
      servers = dns_servers.value
    }
  }

  # Private IP Ranges
  dynamic "private_ip_ranges" {
    for_each = var.firewall_private_ip_ranges != null ? [var.firewall_private_ip_ranges] : []
    content {
      private_ip_ranges = private_ip_ranges.value
    }
  }
}

# Public IP for Azure Firewall
resource "azurerm_public_ip" "firewall" {
  count = var.enable_azure_firewall ? 1 : 0

  name                = var.firewall_public_ip_name
  resource_group_name = azurerm_virtual_network.dmz.resource_group_name
  location            = azurerm_virtual_network.dmz.location
  allocation_method   = var.firewall_public_ip_allocation_method
  sku                 = var.firewall_public_ip_sku
  tags                = merge(var.tags, { "Purpose" = "Firewall Public IP" })
}

# Network Virtual Appliances (NVAs)
resource "azurerm_network_interface" "nva" {
  for_each = var.nva_instances

  name                = each.value.network_interface_name
  location            = azurerm_virtual_network.dmz.location
  resource_group_name = azurerm_virtual_network.dmz.resource_group_name
  tags                = merge(var.tags, { "Purpose" = "NVA Network Interface" })

  dynamic "ip_configuration" {
    for_each = each.value.ip_configurations
    content {
      name                          = ip_configuration.value.name
      subnet_id                     = ip_configuration.value.subnet_id
      private_ip_address_allocation = lookup(ip_configuration.value, "private_ip_address_allocation", "Dynamic")
      private_ip_address            = lookup(ip_configuration.value, "private_ip_address", null)
      public_ip_address_id          = lookup(ip_configuration.value, "public_ip_address_id", null)
      primary                       = lookup(ip_configuration.value, "primary", false)
    }
  }

  # Enable IP forwarding for NVA
  enable_ip_forwarding = lookup(each.value, "enable_ip_forwarding", true)
}

# Public IPs for NVAs (if needed)
resource "azurerm_public_ip" "nva" {
  for_each = var.nva_public_ips

  name                = each.value.name
  resource_group_name = azurerm_virtual_network.dmz.resource_group_name
  location            = azurerm_virtual_network.dmz.location
  allocation_method   = lookup(each.value, "allocation_method", "Static")
  sku                 = lookup(each.value, "sku", "Standard")
  tags                = merge(var.tags, { "Purpose" = "NVA Public IP" })
}

# Virtual Machines for NVAs
resource "azurerm_linux_virtual_machine" "nva" {
  for_each = var.nva_instances

  name                = each.value.vm_name
  resource_group_name = azurerm_virtual_network.dmz.resource_group_name
  location            = azurerm_virtual_network.dmz.location
  size                = each.value.vm_size
  admin_username      = each.value.admin_username
  tags                = merge(var.tags, { "Purpose" = "NVA Virtual Machine" })

  # Network interfaces
  network_interface_ids = each.value.network_interface_ids

  # Admin SSH key
  admin_ssh_key {
    username   = each.value.admin_username
    public_key = each.value.admin_ssh_public_key
  }

  # OS Disk
  os_disk {
    caching              = lookup(each.value, "os_disk_caching", "ReadWrite")
    storage_account_type = lookup(each.value, "os_disk_storage_account_type", "Standard_LRS")
    disk_size_gb         = lookup(each.value, "os_disk_size_gb", 30)
  }

  # Source Image
  source_image_reference {
    publisher = each.value.source_image_reference.publisher
    offer     = each.value.source_image_reference.offer
    sku       = each.value.source_image_reference.sku
    version   = lookup(each.value.source_image_reference, "version", "latest")
  }

  # Disable password authentication
  disable_password_authentication = true

  # Custom data for initialization scripts
  custom_data = lookup(each.value, "custom_data", null)

  # Availability set
  dynamic "availability_set_id" {
    for_each = lookup(each.value, "availability_set_id", null) != null ? [each.value.availability_set_id] : []
    content {
      availability_set_id = availability_set_id.value
    }
  }

  # Proximity placement group
  dynamic "proximity_placement_group_id" {
    for_each = lookup(each.value, "proximity_placement_group_id", null) != null ? [each.value.proximity_placement_group_id] : []
    content {
      proximity_placement_group_id = proximity_placement_group_id.value
    }
  }

  # Identity
  dynamic "identity" {
    for_each = lookup(each.value, "identity", null) != null ? [each.value.identity] : []
    content {
      type = identity.value.type
      identity_ids = lookup(identity.value, "identity_ids", null)
    }
  }

  # Boot diagnostics
  dynamic "boot_diagnostics" {
    for_each = lookup(each.value, "boot_diagnostics", null) != null ? [each.value.boot_diagnostics] : []
    content {
      storage_account_uri = lookup(boot_diagnostics.value, "storage_account_uri", null)
    }
  }
}

# Application Security Groups
resource "azurerm_application_security_group" "dmz" {
  for_each = var.application_security_groups

  name                = each.value.name
  location            = azurerm_virtual_network.dmz.location
  resource_group_name = azurerm_virtual_network.dmz.resource_group_name
  tags                = merge(var.tags, { "Purpose" = "Application Security Group" })
}

# Network Watcher (for monitoring and diagnostics)
resource "azurerm_network_watcher" "dmz" {
  count = var.enable_network_watcher ? 1 : 0

  name                = var.network_watcher_name
  location            = azurerm_virtual_network.dmz.location
  resource_group_name = azurerm_virtual_network.dmz.resource_group_name
  tags                = merge(var.tags, { "Purpose" = "Network Watcher" })
}

# Network Watcher Flow Logs
resource "azurerm_network_watcher_flow_log" "dmz" {
  for_each = var.network_watcher_flow_logs

  network_watcher_name = azurerm_network_watcher.dmz[0].name
  resource_group_name  = azurerm_virtual_network.dmz.resource_group_name
  name                 = each.value.name
  network_security_group_id = each.value.network_security_group_id
  storage_account_id        = each.value.storage_account_id
  enabled                   = lookup(each.value, "enabled", true)
  version                   = lookup(each.value, "version", 2)

  dynamic "retention_policy" {
    for_each = lookup(each.value, "retention_policy", null) != null ? [each.value.retention_policy] : []
    content {
      enabled = retention_policy.value.enabled
      days    = retention_policy.value.days
    }
  }

  dynamic "traffic_analytics" {
    for_each = lookup(each.value, "traffic_analytics", null) != null ? [each.value.traffic_analytics] : []
    content {
      enabled               = traffic_analytics.value.enabled
      workspace_id          = traffic_analytics.value.workspace_id
      workspace_region      = traffic_analytics.value.workspace_region
      workspace_resource_id = traffic_analytics.value.workspace_resource_id
      interval_in_minutes   = lookup(traffic_analytics.value, "interval_in_minutes", 10)
    }
  }
} 