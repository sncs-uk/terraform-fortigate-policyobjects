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
            name        = var.dual_stack ? substr(multi.name, -3, 3) == "_v4" ? multi.name : "${multi.name}-${index(multi.v4, v4)}_v4" : "${multi.name}-${index(multi.v4, v4)}"
            v4          = v4
            description = try(multi.description, null)
            colour      = try(multi.colour, null)
            vdomparam   = vdom
          }
        ]
      ]
    ],
    [
      for multi in try(local.global_objects_yaml.multis, []) : [
        for vdom in var.vdoms : [
          for v4 in try(multi.v4, []) : {
            name        = var.dual_stack ? substr(multi.name, -3, 3) == "_v4" ? multi.name : "${multi.name}-${index(multi.v4, v4)}_v4" : "${multi.name}-${index(multi.v4, v4)}"
            v4          = v4
            description = try(multi.description, null)
            colour      = try(multi.colour, null)
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
            colour      = try(multi.colour, null)
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
            colour      = try(multi.colour, null)
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
          v4          = [for v4 in multi.v4 : var.dual_stack ? substr(multi.name, -3, 3) == "_v4" ? multi.name : "${multi.name}-${index(multi.v4, v4)}_v4" : "${multi.name}-${index(multi.v4, v4)}"]
          colour      = try(multi.colour, null)
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
            v4          = [for v4 in multi.v4 : var.dual_stack ? substr(multi.name, -3, 3) == "_v4" ? multi.name : "${multi.name}-${index(multi.v4, v4)}_v4" : "${multi.name}-${index(multi.v4, v4)}"]
            colour      = try(multi.colour, null)
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
          colour      = try(multi.colour, null)
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
      for vdom in var.vdoms : [
        for obj in try(local.vdom_objects_yaml[vdom].dynamic, []) : merge(obj, { vdomparam = vdom, name = obj.name, type = "dynamic" })
      ]
    ],
    [
      for network in try(local.global_objects_yaml.networks, []) : [
        for vdom in var.vdoms : [merge(network, { vdomparam = vdom, name = network.name })]
      ] if can(network.v4)
    ],
    [
      for obj in try(local.global_objects_yaml.dynamic, []) : [
        for vdom in var.vdoms : [merge(obj, { vdomparam = vdom, name = obj.name, type = "dynamic" })]
      ]
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
      for vdom in var.vdoms : [
        for obj in try(local.vdom_objects_yaml[vdom].dynamic, []) : merge(obj, { vdomparam = vdom, name = obj.name, type = "dynamic" })
      ]
    ],
    [
      for network in try(local.global_objects_yaml.networks, []) : [
        for vdom in var.vdoms : [merge(network, { vdomparam = vdom, name = network.name })]
      ] if can(network.v6)
    ],
    [
      for obj in try(local.global_objects_yaml.dynamic, []) : [
        for vdom in var.vdoms : [merge(obj, { vdomparam = vdom, name = obj.name, type = "dynamic" })]
      ]
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

  name                  = var.dual_stack ? substr(each.value.name, -3, 3) == "_v4" ? each.value.name : "${each.value.name}_v4" : each.value.name
  uuid                  = try(each.value.uuid, null)
  subnet                = try(each.value.v4, null)
  type                  = try(each.value.type, null)
  route_tag             = try(each.value.route_tag, null)
  sub_type              = try(each.value.sub_type, null)
  clearpass_spt         = try(each.value.clearpass_spt, null)
  start_mac             = try(each.value.start_mac, null)
  end_mac               = try(each.value.end_mac, null)
  start_ip              = try(each.value.start_ip, null)
  end_ip                = try(each.value.end_ip, null)
  fqdn                  = try(each.value.fqdn, null)
  country               = try(each.value.country, null)
  wildcard_fqdn         = try(each.value.wildcard_fqdn, null)
  cache_ttl             = try(each.value.cache_ttl, null)
  wildcard              = try(each.value.wildcard, null)
  sdn                   = try(each.value.sdn, null)
  interface             = try(each.value.interface, null)
  tenant                = try(each.value.tenant, null)
  organization          = try(each.value.organization, null)
  epg_name              = try(each.value.epg_name, null)
  subnet_name           = try(each.value.subnet_name, null)
  sdn_tag               = try(each.value.sdn_tag, null)
  policy_group          = try(each.value.policy_group, null)
  obj_tag               = try(each.value.obj_tag, null)
  obj_type              = try(each.value.obj_type, null)
  tag_detection_level   = try(each.value.tag_detection_level, null)
  tag_type              = try(each.value.tag_type, null)
  hw_vendor             = try(each.value.hw_vendor, null)
  hw_model              = try(each.value.hw_model, null)
  os                    = try(each.value.os, null)
  sw_version            = try(each.value.sw_version, null)
  comment               = try(each.value.comment, try(each.value.description, null))
  visibility            = try(each.value.visibility, null)
  associated_interface  = try(each.value.associated_interface, null)
  color                 = try(each.value.colour, null)
  filter                = try(each.value.filter, null)
  sdn_addr_type         = try(each.value.sdn_addr_type, null)
  node_ip_only          = try(each.value.node_ip_only, null)
  obj_id                = try(each.value.obj_id, null)
  allow_routing         = try(each.value.allow_routing, null)
  passive_fqdn_learning = try(each.value.passive_fqdn_learning, null)
  fabric_object         = try(each.value.fabric_object, null)
  vdomparam             = try(each.value.vdomparam, null)
  update_if_exist       = try(each.value.update_if_exist, null)

  dynamic "macaddr" {
    for_each = { for macaddr in try(each.value.macaddr, []) : macaddr => macaddr }
    content {
      macaddr = macaddr.value
    }
  }

  dynamic "fsso_group" {
    for_each = { for fsso_group in try(each.value.fsso_group, []) : fsso_group => fsso_group }
    content {
      name = fsso_group.value
    }
  }

  dynamic "sso_attribute_value" {
    for_each = { for sso_attribute_value in try(each.value.sso_attribute_value, []) : sso_attribute_value => sso_attribute_value }
    content {
      name = sso_attribute_value.value
    }
  }

  dynamic "list" {
    for_each = { for list in try(each.value.list, []) : list => list }
    content {
      ip = list.value
    }
  }

  dynamic "tagging" {
    for_each = { for tagging in try(each.value.tagging, []) : index(each.value.tagging, tagging) => tagging }
    content {
      name     = try(tagging.value.name, null)
      category = try(tagging.value.category, null)
      dynamic "tags" {
        for_each = { for tag in try(tagging.value.tags, []) : tag => tag }
        content {
          name = tag.value
        }
      }
    }
  }
}

resource "fortios_firewall_address6" "address" {
  for_each = { for network in local.objects_v6 : network.name => network }

  name                  = var.dual_stack ? substr(each.value.name, -3, 3) == "_v6" ? each.value.name : "${each.value.name}_v6" : each.value.name
  uuid                  = try(each.value.uuid, null)
  type                  = try(each.value.type, null)
  route_tag             = try(each.value.route_tag, null)
  start_mac             = try(each.value.start_mac, null)
  end_mac               = try(each.value.end_mac, null)
  sdn                   = try(each.value.sdn, null)
  ip6                   = try(each.value.v6, null)
  wildcard              = try(each.value.wildcard, null)
  start_ip              = try(each.value.start_ip, null)
  end_ip                = try(each.value.end_ip, null)
  fqdn                  = try(each.value.fqdn, null)
  country               = try(each.value.country, null)
  cache_ttl             = try(each.value.cache_ttl, null)
  visibility            = try(each.value.visibility, null)
  color                 = try(each.value.colour, null)
  obj_id                = try(each.value.obj_id, null)
  comment               = try(each.value.description, try(each.value.comment, null))
  template              = try(each.value.template, null)
  host_type             = try(each.value.host_type, null)
  host                  = try(each.value.host, null)
  tenant                = try(each.value.tenant, null)
  epg_name              = try(each.value.epg_name, null)
  sdn_tag               = try(each.value.sdn_tag, null)
  filter                = try(each.value.filter, null)
  sdn_addr_type         = try(each.value.sdn_addr_type, null)
  passive_fqdn_learning = try(each.value.passive_fqdn_learning, null)
  fabric_object         = try(each.value.fabric_object, null)
  vdomparam             = try(each.value.vdomparam, null)
  update_if_exist       = try(each.value.update_if_exist, null)

  dynamic "macaddr" {
    for_each = { for macaddr in try(each.value.macaddr, []) : macaddr => macaddr }
    content {
      macaddr = macaddr.value
    }
  }

  dynamic "list" {
    for_each = { for list in try(each.value.list, []) : list => list }
    content {
      ip = list.value
    }
  }

  dynamic "tagging" {
    for_each = { for tagging in try(each.value.tagging, []) : index(each.value.tagging, tagging) => tagging }
    content {
      name     = try(tagging.value.name, null)
      category = try(tagging.value.category, null)
      dynamic "tags" {
        for_each = { for tag in try(tagging.value.tags, []) : tag => tag }
        content {
          name = tag.value
        }
      }
    }
  }

  dynamic "subnet_segment" {
    for_each = { for subnet_segment in try(each.value.subnet_segment, []) : index(each.value.subnet_segment, subnet_segment) => subnet_segment }
    content {
      name  = try(subnet_segment.value.name, null)
      type  = try(subnet_segment.value.type, null)
      value = try(subnet_segment.value.value, null)
    }
  }

}

resource "fortios_firewall_addrgrp" "group" {
  for_each   = { for group in local.groups_v4 : group.name => group }
  depends_on = [fortios_firewall_address.address]

  name          = var.dual_stack ? substr(each.value.name, -3, 3) == "_v4" ? each.value.name : "${each.value.name}_v4" : each.value.name
  type          = try(each.value.type, null)
  category      = try(each.value.category, null)
  uuid          = try(each.value.uuid, null)
  comment       = try(each.value.comment, null)
  exclude       = try(each.value.exclude, null)
  visibility    = try(each.value.visibility, null)
  color         = try(each.value.colour, null)
  allow_routing = try(each.value.allow_routing, null)
  fabric_object = try(each.value.fabric_object, null)
  vdomparam     = try(each.value.vdomparam, null)

  dynamic "member" {
    for_each = { for member in each.value.v4 : member => member }
    content {
      name = member.value
    }
  }

  dynamic "exclude_member" {
    for_each = { for exclude_member in each.value.exclude_v4 : exclude_member => exclude_member }
    content {
      name = exclude_member.value
    }
  }

  dynamic "tagging" {
    for_each = { for tagging in try(each.value.tagging, []) : index(each.value.tagging, tagging) => tagging }
    content {
      name     = try(tagging.value.name, null)
      category = try(tagging.value.category, null)
      dynamic "tags" {
        for_each = { for tag in try(tagging.value.tags, []) : tag => tag }
        content {
          name = tag.value
        }
      }
    }
  }
}

resource "fortios_firewall_addrgrp6" "group" {
  for_each   = { for group in local.groups_v6 : group.name => group }
  depends_on = [fortios_firewall_address6.address]

  name          = substr(each.value.name, -3, 3) == "_v6" ? each.value.name : "${each.value.name}_v6"
  uuid          = try(each.value.uuid, null)
  visibility    = try(each.value.visibility, null)
  color         = try(each.value.color, null)
  comment       = try(each.value.comment, null)
  exclude       = try(each.value.exclude, null)
  fabric_object = try(each.value.fabric_object, null)
  vdomparam     = try(each.value.vdomparam, null)

  dynamic "member" {
    for_each = { for member in each.value.v6 : member => member }
    content {
      name = member.value
    }
  }

  dynamic "exclude_member" {
    for_each = { for exclude_member in each.value.exclude_v6 : exclude_member => exclude_member }
    content {
      name = exclude_member.value
    }
  }

  dynamic "tagging" {
    for_each = { for tagging in try(each.value.tagging, []) : index(each.value.tagging, tagging) => tagging }
    content {
      name     = try(tagging.value.name, null)
      category = try(tagging.value.category, null)
      dynamic "tags" {
        for_each = { for tag in try(tagging.value.tags, []) : tag => tag }
        content {
          name = tag.value
        }
      }
    }
  }
}

resource "fortios_firewallservice_category" "categories" {
  for_each      = { for category in local.categories : category.name => category }
  name          = each.value.name
  uuid          = try(each.value.uuid, null)
  comment       = try(each.value.comment, null)
  fabric_object = try(each.value.fabric_object, null)
  vdomparam     = try(each.value.vdomparam, null)
}

resource "fortios_firewallservice_custom" "services" {
  for_each   = { for service in local.services : service.name => service }
  depends_on = [fortios_firewallservice_category.categories]

  name                = try(each.value.name, null)
  uuid                = try(each.value.uuid, null)
  proxy               = try(each.value.proxy, null)
  category            = try(each.value.category, null)
  protocol            = try(each.value.protocol, null)
  helper              = try(each.value.helper, null)
  iprange             = try(each.value.iprange, null)
  fqdn                = try(each.value.fqdn, null)
  protocol_number     = try(each.value.protocol_number, null)
  icmptype            = try(each.value.icmptype, null)
  icmpcode            = try(each.value.icmpcode, null)
  tcp_portrange       = try(each.value.tcp_portrange, try(each.value.tport, null))
  udp_portrange       = try(each.value.udp_portrange, try(each.value.uport, null))
  udplite_portrange   = try(each.value.udplite_portrange, null)
  sctp_portrange      = try(each.value.sctp_portrange, null)
  tcp_halfclose_timer = try(each.value.tcp_halfclose_timer, null)
  tcp_halfopen_timer  = try(each.value.tcp_halfopen_timer, null)
  tcp_timewait_timer  = try(each.value.tcp_timewait_timer, null)
  tcp_rst_timer       = try(each.value.tcp_rst_timer, null)
  udp_idle_timer      = try(each.value.udp_idle_timer, null)
  session_ttl         = try(each.value.session_ttl, null)
  check_reset_range   = try(each.value.check_reset_range, null)
  comment             = try(each.value.comment, null)
  color               = try(each.value.colour, null)
  visibility          = try(each.value.visibility, null)
  app_service_type    = try(each.value.app_service_type, null)
  fabric_object       = try(each.value.fabric_object, null)
  vdomparam           = try(each.value.vdomparam, null)


  dynamic "app_category" {
    for_each = { for app_category in each.value.app_category : app_category => app_category }
    content {
      id = app_category.value
    }
  }

  dynamic "application" {
    for_each = { for application in each.value.application : application => application }
    content {
      id = application.value
    }
  }
}
