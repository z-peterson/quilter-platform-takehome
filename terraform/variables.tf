variable "app_version" {
  description = "Application version to deploy"
  type        = string
  default     = "latest"
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "quilter-demo"
}

variable "replicas" {
  description = "Number of pod replicas"
  type        = number
  default     = 2
}

variable "image" {
  description = "Container image name"
  type        = string
  default     = "quilter-api"
}

variable "kubeconfig" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}
