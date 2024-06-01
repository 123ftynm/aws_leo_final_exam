variable "region_name" {
  type    = string
  default = "ca-central-1"
}

variable "bucket_name" {
  type    = string
  default = "leobucketexam"
}

variable "iamrole_name" {
  type    = string
  default = "leorole"
}

variable "vpc_cidr" {
  type    = string
  default = "10.50.0.0/16"
}
variable "subnet_cidr" {
  type    = string
  default = "10.50.1.0/24"
}

variable "subnet2_cidr" {
  type    = string
  default = "10.50.2.0/24"
}
variable "subnet3_cidr" {
  type    = string
  default = "10.50.3.0/24"
}

variable "subnet1_cidr" {
  type    = string
  default = "10.50.4.0/24"
}

variable "az1" {
  type    = string
  default = "ca-central-1a"
}
variable "az2" {
  type    = string
  default = "ca-central-1b"
}

variable "kms_key" {
  type    = string
  default = "d8eba667-a661-467e-aa70-12b750d7d882"
}

variable "dbPort" {
  type    = number
  default = 3306
}

variable "instanceTypeParameter" {
  type    = string
  default = "t2.micro"
}

variable "dbnstanceID" {
  type    = string
  default = "dbinstanceid"
}

variable "dbName" {
  type    = string
  default = "leords"
}

variable "amiID" {
  type    = string
  default = "ami-05e5688f9ac7ade41"
  }

variable "dbInstanceClass" {
  type    = string
  default = "db.t3.micro"
}

variable "dbAllocatedStorage" {
  type    = string
  default = "gp2"
}

variable "dbEngine" {
  type    = string
  default = "MySQL"
}

variable "engineVersion" {
  type    = string
  default = "8.0.33"
}

variable "dbUsername" {
  type    = string
  default = "admin"
}

variable "dbPassword" {
  type    = string
  default = "Leodejesus12345"
}

variable "storage" {
  type    = number
  default = 20
}

variable "role_arn" {
  type    = string
  default = 20
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}


  