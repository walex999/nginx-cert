variable "project_id" {
  type        = string
  description = "Project ID for the resources."
  sensitive   = true
}


variable "region" {
  type        = string
  default     = "fr-par"
  description = "Region for the resources, defaults to fr-par."
}
variable "zone" {
  type        = string
  default     = "fr-par-1"
  description = "Zone for the resources, defaults to fr-par-1."
}

variable "access_key" {
  type        = string
  description = "Access key."
  sensitive   = true
}

variable "secret_key" {
  type        = string
  description = "Secret key."
  sensitive   = true
}
