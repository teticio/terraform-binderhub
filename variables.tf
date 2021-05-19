variable "tag" {
  type    = string
  default = "Binderhub"
}

variable "region" {
  type    = string
  default = "eu-west-2"
}

variable "ami" {
  type    = string
  default = "ami-0194c3e07668a7e36"
}

variable "key_name" {
  type = string
}

variable "key_path" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t2.large"
}

variable "volume_size" {
  type    = string
  default = "30"
}

variable "dockerhub_username" {
  type = string
}

variable "dockerhub_password" {
  type = string
}

variable "binderhub_helm_version" {
  type    = string
  default = "0.2.0-n557.h46ddaac"
}

variable "jupyterhub_port" {
  type    = string
  default = "30123"
}