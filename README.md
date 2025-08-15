<!-- BEGIN_TF_DOCS -->
# Fortigate Policy Objects configuration module

This terraform module configures Policy Objects on a firewall

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_fortios"></a> [fortios](#provider\_fortios) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [fortios_firewall_address.address](https://registry.terraform.io/providers/fortinetdev/fortios/latest/docs/resources/firewall_address) | resource |
| [fortios_firewall_address6.address](https://registry.terraform.io/providers/fortinetdev/fortios/latest/docs/resources/firewall_address6) | resource |
| [fortios_firewall_addrgrp.group](https://registry.terraform.io/providers/fortinetdev/fortios/latest/docs/resources/firewall_addrgrp) | resource |
| [fortios_firewall_addrgrp6.group](https://registry.terraform.io/providers/fortinetdev/fortios/latest/docs/resources/firewall_addrgrp6) | resource |
| [fortios_firewallservice_category.categories](https://registry.terraform.io/providers/fortinetdev/fortios/latest/docs/resources/firewallservice_category) | resource |
| [fortios_firewallservice_custom.services](https://registry.terraform.io/providers/fortinetdev/fortios/latest/docs/resources/firewallservice_custom) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_config_path"></a> [config\_path](#input\_config\_path) | Path to base configuration directory | `string` | n/a | yes |
| <a name="input_vdoms"></a> [vdoms](#input\_vdoms) | List of VDOMs from which to pull in configuration | `list(string)` | `[]` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->