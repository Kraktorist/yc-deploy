variable "env_folder" {
  type        = string
  default     = ""
  description = "Path to yaml file which describes infrastructure"
}

variable "env_config_filename" {
  type        = string
  default     = "config.yaml"
  description = "Name of yaml file which describes infrastructure"
}