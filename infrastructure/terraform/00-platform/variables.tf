variable "subscription_id" {
  type = string
}

variable "location" {
  type    = string
  default = "swedencentral"
}

variable "project" {
  type    = string
  default = "demo"
}

variable "sql_admin_login" {
  type    = string
  default = "sqladmin"
}

variable "sql_admin_password" {
  type      = string
  sensitive = true
}

variable "deployer_sp_object_id" {
  type        = string
  description = "Object ID of the GitHub Actions service principal"
}

