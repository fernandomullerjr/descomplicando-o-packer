data "aws_ami" "ubuntu" {
  most_recent      = true

  filter {
    name   = "tag:Release"
    values = ["v*"]
  }

  filter {
    name   = "tag:Product"
    values = ["Base"]
  }

  owners           = ["self"] # minha conta, no caso posso usar o self ou o id da conta na AWS
}


resource "aws_instance" "main" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name = "terraform-aws"
  tags = {
    Name = var.hostname
  }


  lifecycle {
    ignore_changes = [
      ami,
    ]
  }

  user_data = <<EOF
#!/bin/bash
sudo hostnamectl set-hostname ${var.hostname}
EOD
EOF
}
