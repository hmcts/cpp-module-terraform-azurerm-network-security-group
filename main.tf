data "azurerm_resource_group" "nsg" {
  name = var.resource_group_name
}

resource "azurerm_network_security_group" "nsg" {
  name                = var.security_group_name
  location            = var.location != "" ? var.location : data.azurerm_resource_group.nsg.location
  resource_group_name = data.azurerm_resource_group.nsg.name
  tags                = var.tags
  lifecycle {
    ignore_changes = [tags["created_by"], tags["created_time"]]
  }
}

#############################
#   Simple security rules   #
#############################

resource "azurerm_network_security_rule" "predefined_rules" {
  for_each                                   = { for idx, rule in var.predefined_rules : lookup(rule, "name", "rule_${idx}") => merge(rule, { _index = idx }) }
  name                                       = lookup(each.value, "name")
  priority                                   = lookup(each.value, "priority", 4096 - length(var.predefined_rules) + each.value._index)
  direction                                  = element(var.rules[lookup(each.value, "name")], 0)
  access                                     = element(var.rules[lookup(each.value, "name")], 1)
  protocol                                   = element(var.rules[lookup(each.value, "name")], 2)
  source_port_range                          = lookup(each.value, "source_port_range", "*") == "*" ? "*" : null
  source_port_ranges                         = lookup(each.value, "source_port_range", "*") == "*" ? null : split(",", each.value.source_port_range)
  destination_port_range                     = element(var.rules[lookup(each.value, "name")], 4)
  description                                = element(var.rules[lookup(each.value, "name")], 5)
  source_address_prefix                      = lookup(each.value, "source_application_security_group_ids", null) == null && var.source_address_prefixes == null ? join(",", var.source_address_prefix) : null
  source_address_prefixes                    = lookup(each.value, "source_application_security_group_ids", null) == null ? var.source_address_prefixes : null
  destination_address_prefix                 = lookup(each.value, "destination_application_security_group_ids", null) == null && var.destination_address_prefixes == null ? join(",", var.destination_address_prefix) : null
  destination_address_prefixes               = lookup(each.value, "destination_application_security_group_ids", null) == null ? var.destination_address_prefixes : null
  resource_group_name                        = data.azurerm_resource_group.nsg.name
  network_security_group_name                = azurerm_network_security_group.nsg.name
  source_application_security_group_ids      = lookup(each.value, "source_application_security_group_ids", null)
  destination_application_security_group_ids = lookup(each.value, "destination_application_security_group_ids", null)
}

#############################
#  Detailed security rules  #
#############################

resource "azurerm_network_security_rule" "custom_rules" {
  for_each                                   = { for idx, rule in var.custom_rules : lookup(rule, "name", "custom_rule_${idx}") => rule }
  name                                       = lookup(each.value, "name", "default_rule_name")
  priority                                   = lookup(each.value, "priority")
  direction                                  = lookup(each.value, "direction", "Any")
  access                                     = lookup(each.value, "access", "Allow")
  protocol                                   = lookup(each.value, "protocol", "*")
  source_port_range                          = lookup(each.value, "source_port_range", "*") == "*" ? "*" : null
  source_port_ranges                         = lookup(each.value, "source_port_range", "*") == "*" ? null : split(",", each.value.source_port_range)
  destination_port_ranges                    = split(",", replace(lookup(each.value, "destination_port_range", "*"), "*", "0-65535"))
  source_address_prefix                      = lookup(each.value, "source_application_security_group_ids", null) == null && lookup(each.value, "source_address_prefixes", null) == null ? lookup(each.value, "source_address_prefix", "*") : null
  source_address_prefixes                    = lookup(each.value, "source_application_security_group_ids", null) == null ? lookup(each.value, "source_address_prefixes", null) : null
  destination_address_prefix                 = lookup(each.value, "destination_application_security_group_ids", null) == null && lookup(each.value, "destination_address_prefixes", null) == null ? lookup(each.value, "destination_address_prefix", "*") : null
  destination_address_prefixes               = lookup(each.value, "destination_application_security_group_ids", null) == null ? lookup(each.value, "destination_address_prefixes", null) : null
  description                                = lookup(each.value, "description", "Security rule for ${lookup(each.value, "name", "default_rule_name")}")
  resource_group_name                        = data.azurerm_resource_group.nsg.name
  network_security_group_name                = azurerm_network_security_group.nsg.name
  source_application_security_group_ids      = lookup(each.value, "source_application_security_group_ids", null)
  destination_application_security_group_ids = lookup(each.value, "destination_application_security_group_ids", null)
}
