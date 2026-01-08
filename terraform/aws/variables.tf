variable "region" {
  type        = string
  default     = "eu-west-3"
  description = "Region for the resources, defaults to eu-west-3."
}

variable "access_key" {
  type        = string
  default     = null
  nullable    = true
  sensitive   = true
  description = "Access Key to the AWS tenant."
}

variable "secret_key" {
  type        = string
  default     = null
  nullable    = true
  sensitive   = true
  description = "Secret Key to the AWS tenant."
}

variable "owner" {
  sensitive   = true
  nullable    = false
  description = "Value for I_Owner tag"
}

variable "source_ip" {
  sensitive   = true
  nullable    = false
  description = "Source value for SSH access."
}
