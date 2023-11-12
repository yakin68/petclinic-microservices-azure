variable "region" {
  default     = "northeurope"
  description = "chose to want location"
}

variable "instance_type" {
  default     = "Standard_DS2_v2"
  description = "chose to want instance-type"
}

variable "sec-gr-mutual-ports" {
  type        = list(number)
  description = "sec-gr-mutual-ports"
}

variable "sec-gr-k8s-master-ports" {
  type        = list(number)
  description = "sec-gr-k8s-master-ports"
}

variable "sec-gr-k8s-worker-ports" {
  type        = list(number)
  description = "sec-gr-k8s-worker-ports"
}

