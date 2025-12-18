/**
 * # Fortigate Policy Objects configuration module
 *
 * This terraform module configures Policy Objects on a firewall
 */
terraform {
  required_version = ">= 1.11.0"
  required_providers {
    fortios = {
      source  = "fortinetdev/fortios"
      version = ">= 1.22.0"
    }
  }
}
locals {
  vdom_objects_yaml = {
    for vdom in var.vdoms : vdom => yamldecode(file("${var.config_path}/${vdom}/objects.yaml")) if fileexists("${var.config_path}/${vdom}/objects.yaml")
  }

  global_objects_yaml = fileexists("${var.config_path}/objects.yaml") ? yamldecode(file("${var.config_path}/objects.yaml")) : null

  multi_v4 = flatten([
    [
      for vdom in var.vdoms : [
        for multi in try(local.vdom_objects_yaml[vdom].multis, []) : [
          for v4 in try(multi.v4, []) : {
            name        = var.dual_stack ? substr(v4.name, -3, 3) == "_v4" ? v4.name : "${multi.name}-${index(multi.v4, v4)}_v4" : "${multi.name}-${index(multi.v4, v4)}"
            v4          = v4
            description = try(multi.description, null)
            colour      = try(multi.colour, 0)
            vdomparam   = vdom
          }
        ]
      ]
    ],
    [
      for multi in try(local.global_objects_yaml.multis, []) : [
        for vdom in var.vdoms : [
          for v4 in try(multi.v4, []) : {
            name        = var.dual_stack ? substr(v4.name, -3, 3) == "_v4" ? v4.name : "${multi.name}-${index(multi.v4, v4)}_v4" : "${multi.name}-${index(multi.v4, v4)}"
            v4          = v4
            description = try(multi.description, null)
            colour      = try(multi.colour, 0)
            vdomparam   = vdom
          }
        ]
      ]
    ]
  ])
  multi_v6 = var.dual_stack ? flatten([
    [
      for vdom in var.vdoms : [
        for multi in try(local.vdom_objects_yaml[vdom].multis, []) : [
          for v6 in try(multi.v6, []) : {
            name        = "${multi.name}-${index(multi.v6, v6)}_v6"
            v6          = v6
            description = try(multi.description, null)
            colour      = try(multi.colour, 0)
            vdomparam   = "root"
          }
        ]
      ]
    ],
    [
      for multi in try(local.global_objects_yaml.multis, []) : [
        for vdom in var.vdoms : [
          for v6 in try(multi.v6, []) : {
            name        = "${multi.name}-${index(multi.v6, v6)}_v6"
            v6          = v6
            description = try(multi.description, null)
            colour      = try(multi.colour, 0)
            vdomparam   = vdom
          }
        ]
      ]
    ]
  ]) : []
  groups_v4 = flatten([
    [
      for vdom in var.vdoms : [
        for group in try(local.vdom_objects_yaml[vdom].groups, []) : [merge(group, { vdomparam = vdom, name = group.name })] if can(group.v4)
      ]
    ],
    [
      for group in try(local.global_objects_yaml.groups, []) : [
        for vdom in var.vdoms : [merge(group, { vdomparam = vdom, name = group.name })]
      ] if can(group.v4)
    ],
    [
      for multi in try(local.global_objects_yaml.multis, []) : [
        for vdom in var.vdoms : {
          name        = "${multi.name}_v4"
          v4          = [for v4 in multi.v4 : var.dual_stack ? substr(v4.name, -3, 3) == "_v4" ? v4.name : "${multi.name}-${index(multi.v4, v4)}_v4" : "${multi.name}-${index(multi.v4, v4)}"]
          colour      = try(multi.colour, 0)
          description = try(multi.description, null)
          vdomparam   = vdom
        }
      ] if can(multi.v4)
    ],
    [
      for vdom in var.vdoms : [
        for multi in try(local.vdom_objects_yaml[vdom].multis, []) : [
          for vdom in var.vdoms : {
            name        = var.dual_stack ? "${multi.name}_v4" : multi.name
            v4          = [for v4 in multi.v4 : var.dual_stack ? substr(v4.name, -3, 3) == "_v4" ? v4.name : "${multi.name}-${index(multi.v4, v4)}_v4" : "${multi.name}-${index(multi.v4, v4)}"]
            colour      = try(multi.colour, 0)
            description = try(multi.description, null)
            vdomparam   = vdom
          }
        ] if can(multi.v4)
      ]
    ]
  ])

  groups_v6 = var.dual_stack ? flatten([
    [
      for vdom in var.vdoms : [
        for group in try(local.vdom_objects_yaml[vdom].groups, []) : [merge(group, { vdomparam = vdom, name = group.name })] if can(group.v6)
      ]
    ],
    [
      for group in try(local.global_objects_yaml.groups, []) : [
        for vdom in var.vdoms : [merge(group, { vdomparam = vdom, name = group.name })]
      ] if can(group.v6)
    ],
    [
      for multi in try(local.global_objects_yaml.multis, []) : [
        for vdom in var.vdoms : {
          name        = "${multi.name}_v6"
          v6          = [for v6 in multi.v6 : "${multi.name}-${index(multi.v6, v6)}_v6"]
          colour      = try(multi.colour, 0)
          description = try(multi.description, null)
          vdomparam   = vdom
        }
      ] if can(multi.v6)
    ]
  ]) : []

  objects_v4 = flatten([
    local.multi_v4,
    [
      for vdom in var.vdoms : [
        for network in try(local.vdom_objects_yaml[vdom].networks, []) : merge(network, { vdomparam = vdom, name = network.name }) if can(network.v4)
      ]
    ],
    [
      for network in try(local.global_objects_yaml.networks, []) : [
        for vdom in var.vdoms : [merge(network, { vdomparam = vdom, name = network.name })]
      ] if can(network.v4)
    ]
  ])
  objects_v6 = var.dual_stack ? flatten([
    local.multi_v6,
    [
      for vdom in var.vdoms : [
        for network in try(local.vdom_objects_yaml[vdom].networks, []) : merge(network, { vdomparam = vdom, name = network.name }) if can(network.v6)
      ]
    ],
    [
      for network in try(local.global_objects_yaml.networks, []) : [
        for vdom in var.vdoms : [merge(network, { vdomparam = vdom, name = network.name })]
      ] if can(network.v6)
    ]
  ]) : []
  services = flatten([
    [
      for vdom in var.vdoms : [
        for service in try(local.vdom_objects_yaml[vdom].services, []) : merge(service, { vdomparam = vdom })
      ]
    ],
    [
      for service in try(local.global_objects_yaml.services, []) : [
        for vdom in var.vdoms : [merge(service, { vdomparam = vdom })]
      ]
    ]
  ])
  categories = flatten([
    [
      for category in try(local.global_objects_yaml.service_categories, []) : [
        for vdom in var.vdoms : [merge(category, { vdomparam = vdom })]
      ]
    ]
  ])
}

resource "fortios_firewall_address" "address" {
  for_each = { for network in local.objects_v4 : network.name => network }

  subnet    = each.value.v4
  name      = var.dual_stack ? substr(each.value.name, -3, 3) == "_v4" ? each.value.name : "${each.value.name}_v4" : each.value.name
  comment   = try(each.value.description, null)
  color     = try(each.value.colour, 1)
  vdomparam = each.value.vdomparam
}

resource "fortios_firewall_address6" "address" {
  for_each = { for network in local.objects_v6 : network.name => network }

  ip6       = each.value.v6
  name      = substr(each.value.name, -3, 3) == "_v6" ? each.value.name : "${each.value.name}_v6"
  comment   = try(each.value.description, null)
  color     = try(each.value.colour, 1)
  vdomparam = each.value.vdomparam
}

resource "fortios_firewall_addrgrp" "group" {
  for_each   = { for group in local.groups_v4 : group.name => group }
  depends_on = [fortios_firewall_address.address]

  name    = var.dual_stack ? substr(each.value.name, -3, 3) == "_v4" ? each.value.name : "${each.value.name}_v4" : each.value.name
  comment = try(each.value.description, null)
  color   = try(each.value.colour, 1)
  dynamic "member" {
    for_each = { for member in each.value.v4 : member => member }
    content {
      name = member.value
    }
  }
  vdomparam = each.value.vdomparam
}

resource "fortios_firewall_addrgrp6" "group" {
  for_each   = { for group in local.groups_v6 : group.name => group }
  depends_on = [fortios_firewall_address6.address]

  name    = substr(each.value.name, -3, 3) == "_v6" ? each.value.name : "${each.value.name}_v6"
  comment = try(each.value.description, null)
  color   = try(each.value.colour, 1)
  dynamic "member" {
    for_each = { for member in each.value.v6 : member => member }
    content {
      name = member.value
    }
  }
  vdomparam = each.value.vdomparam
}

resource "fortios_firewallservice_category" "categories" {
  for_each  = { for category in local.categories : category.name => category }
  name      = each.key
  vdomparam = each.value.vdomparam
}

resource "fortios_firewallservice_custom" "services" {
  for_each   = { for service in local.services : service.name => service }
  depends_on = [fortios_firewallservice_category.categories]

  name          = each.value.name
  category      = try(each.value.category, null)
  protocol      = each.value.protocol
  tcp_portrange = try(each.value.tport, null)
  udp_portrange = try(each.value.uport, null)
  vdomparam     = each.value.vdomparam
}
