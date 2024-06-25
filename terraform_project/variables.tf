variable "cloud_id" {
  description = "The ID of the cloud under which to deploy the resources"
  type        = string
}

variable "folder_id" {
  description = "The ID of the folder under which to deploy the resources"
  type        = string
}

variable "default_zone" {
  description = "The default zone where resources will be deployed"
  type        = string
}

variable "image_id" {
  description = "The ID of the image to be used for the instances"
  type        = string
  default     = "fd8idq8k33m9hlj0huli"
}
