locals {
    release      =    var.release != "" ? var.release : formatdate("YYYYMMDDhhmmss", timestamp())
    ami_name     =    replace("base-${local.release}", ".", "-")
}


source "amazon-ebs" "example" {
  # argument

    ssh_username    =   "ubuntu"
    instance_type   =   "t3.medium"
    region          =   "us-east-1"
    ami_name        =   local.ami_name
    tags = {
        OS_Version  =   "Ubuntu"
        Release     =   "${local.release}"
        Base_AMI_Name   =   "{{ .SourceAMIName }}"
        Extra   =   "{{ .SourceAMITags.TagName }}"
        Product = "Base"
    }
}