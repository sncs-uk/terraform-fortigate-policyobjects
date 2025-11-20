variable vdoms {
  description = "List of VDOMs from which to pull in configuration"
  type        = list(string)
  default     = []
}

variable config_path {
  description = "Path to base configuration directory"
  type        = string
}

variable dual_stack {
  description = "Whether or not to suffix hosts with _v4 and _v6 for dual stack"
  type        = bool
  default     = true
}
