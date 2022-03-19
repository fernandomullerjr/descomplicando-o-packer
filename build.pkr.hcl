locals {
<<<<<<< HEAD
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

    source_ami_filter {
        filters = {
        name = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-arm64-server-*"
        root-device-type = "ebs"
        virtualization-type = "hvm"
        }
        owners = ["099720109477"]
        most_recent = true
    }

    build {
    sources = ["source.amazon-ebs.example"]
    provisioner "shell" {
        inline = [
            "echo Connected via SSM at '${build.User}@${build.Host}:${build.Port}'",
            "echo provisioning all the things",
            "echo 'foo' > /tmp/teste",
        ]
    }
    }
=======
  release  = var.release != "" ? var.release : formatdate("YYYYMMDDhhmmss", timestamp())
  ami_name = replace("base-${local.release}", ".", "-")
}

source "amazon-ebs" "example" {
  # argument

  ssh_username  = "ubuntu"
  instance_type = "t3.micro"
  region        = "us-east-1"
  ami_name      = local.ami_name
  tags = {
    OS_Version    = "Ubuntu"
    Release       = "${local.release}"
    Base_AMI_Name = "{{ .SourceAMIName }}"
    Extra         = "{{ .SourceAMITags.TagName }}"
    Product       = "Base"
  }

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["099720109477"]
    most_recent = true
  }
}

build {
  sources = ["amazon-ebs.example"]

  provisioner "shell" {
    inline = [
      #"echo Connected via SSM at '${build.User}@${build.Host}:${build.Port}'",
      "echo provisioning all the things",
      "echo 'foo' > /tmp/teste"
    ]
  }
>>>>>>> build-final
}

