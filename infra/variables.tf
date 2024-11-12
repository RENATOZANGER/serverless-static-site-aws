variable "table_name" {
  type    = string
  default = "studentData"
}

variable "function_name" {
  type    = string
  default = "Lambda_and_dynamodb"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "stage_name" {
  type    = string
  default = "dev"
}

variable "api_resource" {
  type    = string
  default = "students"
}

variable "limit_quota" {
  type    = number
  default = 20
}
