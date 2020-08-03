variable "project_name" {
  type = string
}

variable "default_location" {
  type = string
}

variable "main_vnet_address_space" {
  type = string
}

variable "wap_dmz_prefix" {
  type = string
}

variable "dmz_prefix" {
  type = string
}

variable "dmz_subnet_address_space" {
  type = string
}

variable "internal_prefix" {
  type = string
}

variable "adfs_internal_prefix" {
  type = string
}

variable "adds_internal_prefix" {
  type = string
}

variable "internal_subnet_address_space" {
  type = string
}

variable "bastion_subnet_address_space" {
  type = string
}

variable "wap_server_count" {
  type = number
}

variable "adds_server_count" {
  type = number
}

variable "adfs_server_count" {
  type = number
}