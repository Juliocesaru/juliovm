provider "azurerm" {
  features {}
}

variable "config_file" {
  description = "Path to the YAML configuration file"
  default     = "config.yaml"
}

locals {
  config = yamldecode(file(var.config_file))
}

resource "azurerm_resource_group" "example" {
  name     = local.config.resource_group_name
  location = local.config.location
}
