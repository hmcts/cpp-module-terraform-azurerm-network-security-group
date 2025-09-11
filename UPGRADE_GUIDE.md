# Upgrade Guide: Count to For_Each Migration

## Overview

This module has been updated to use `for_each` instead of `count` for creating NSG rules. This change provides several benefits:

- **No resource recreation when rule order changes**: Rules are now keyed by their name instead of array index
- **Better state management**: Each rule has a unique identifier in Terraform state
- **Easier troubleshooting**: Rule names are visible in Terraform plan/apply output

## Breaking Changes

### Resource Addressing
With `count`, rules were addressed as:
```
azurerm_network_security_rule.predefined_rules[0]
azurerm_network_security_rule.custom_rules[1]
```

With `for_each`, rules are now addressed as:
```
azurerm_network_security_rule.predefined_rules["SSH"]
azurerm_network_security_rule.custom_rules["custom_rule_0"]
```

## Migration Steps

### 1. Backup your state
```bash
terraform state pull > backup.tfstate
```

### 2. For existing deployments, you'll need to import resources with new addresses

List current resources:
```bash
terraform state list | grep azurerm_network_security_rule
```

Move each resource to the new for_each key format:
```bash
# Example for predefined rules
terraform state mv 'azurerm_network_security_rule.predefined_rules[0]' 'azurerm_network_security_rule.predefined_rules["SSH"]'

# Example for custom rules  
terraform state mv 'azurerm_network_security_rule.custom_rules[0]' 'azurerm_network_security_rule.custom_rules["custom_rule_0"]'
```

### 3. Ensure your rule names are unique
Make sure each rule in your `predefined_rules` and `custom_rules` has a unique `name` field.

## Usage Examples

### Predefined Rules
```hcl
module "network_security_group" {
  source = "./path/to/module"
  
  resource_group_name  = "my-rg"
  security_group_name  = "my-nsg"
  
  predefined_rules = [
    {
      name     = "SSH"
      priority = 100
    },
    {
      name     = "HTTP" 
      priority = 110
    }
  ]
}
```

### Custom Rules
```hcl
module "network_security_group" {
  source = "./path/to/module"
  
  resource_group_name  = "my-rg"
  security_group_name  = "my-nsg"
  
  custom_rules = [
    {
      name                       = "AllowCustomApp"
      priority                   = 200
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "8080"
      source_address_prefix      = "10.0.0.0/16"
      destination_address_prefix = "*"
      description                = "Allow custom application traffic"
    }
  ]
}
```

## Benefits

1. **Order Independence**: You can reorder rules in your configuration without triggering resource recreation
2. **Clearer Identification**: Rules are identified by name in Terraform output and state
3. **Partial Updates**: Only modified rules are updated, not all rules
4. **Better Error Messages**: Terraform errors reference rule names instead of array indices

## Troubleshooting

If you encounter issues during migration:

1. Check that all rules have unique names
2. Verify the state moves were successful with `terraform plan`
3. If needed, you can remove resources from state and re-import them:
   ```bash
   terraform state rm 'azurerm_network_security_rule.predefined_rules["rule_name"]'
   terraform import 'azurerm_network_security_rule.predefined_rules["rule_name"]' /subscriptions/.../resourceGroups/.../providers/Microsoft.Network/networkSecurityGroups/.../securityRules/rule_name
   ```
