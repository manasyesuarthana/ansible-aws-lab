variable "region" {
  default = "us-east-1"
}

variable "availability_zone" {
  default = "us-east-1a"
}

variable "amiID" {
  type = map(any)
  default = {
    controller = "ami-0b6d9d3d33ba97d99"
    web        = "ami-0e0416d387552f0b1"
    db         = "ami-0e0416d387552f0b1"
  }
}

