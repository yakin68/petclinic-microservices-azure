variable "region" {}
variable "instance_type" {}
variable "dev-server-ports" {
  type        = list(number)
  description = "dev-server-sec-gr-inbound-rules"
}


