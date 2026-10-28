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