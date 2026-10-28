variable "subscription_id" {
  type = string
}

variable "project" {
  type    = string
  default = "demo"
}

variable "resource_group_name" {
  type = string
}

variable "service_plan_name" {
  type = string
}

variable "sql_server_name" {
  type = string
}

variable "sql_database_name" {
  type = string
}

variable "sql_admin_password" {
  type      = string
  sensitive = true
}
variable "allowed_ips" {
  type = list(string)
}
variable "enable_custom_domain" {
  type    = bool
  default = false
}

variable "custom_domain" {
  type    = string
  default = ""
}
