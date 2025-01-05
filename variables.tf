variable "cluster_name" {
  type = string
  default = "demo-eks-cluster"
}

variable "cluster_version" {
  type = number
  default = 1.27
}

variable "region" {
  type = string
  default = "us-east-1"
}

variable "availability_zones" {
  type = list
  default = ["us-east-1a", "us-east-1b"]
}



variable "addons" {
  type = list(object({
    name    = string
    version = string
  }))

  default = [
    {
      name    = "kube-proxy"
      version = "v1.27.16-eksbuild.14"  
    },
    {
      name    = "vpc-cni"
      version = "v1.19.2-eksbuild.1"   
    },
    {
      name    = "coredns"
      version = "v1.10.1-eksbuild.17"  
    },
    {
      name    = "aws-ebs-csi-driver"
      version = "v1.38.1-eksbuild.1"  
    }
  ]
}
