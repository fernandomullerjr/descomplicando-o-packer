


# Aula - Descomplicando o Packer

# Instalando o Packer
~~~bash
sudo apt-get update
sudo apt-get -y install packer
~~~


- A idéia é termos o nosso próprio repositório para imagens, para evitar a quebra do Pipeline por motivos externos.


- Processador:
Possibilita a execução de pós processos, como webhooks, entre outros.
É o que roda depois da sua imagem ser triggada.


- Source:
Contem a origem da imagem.
Define como vai ser o Build da imagem.


- Local:

- Variável:

Variavel e local são inputs usados no Packer.



O Packer utiliza a extensão pkr.hcl para os arquivos hcl dele.
No nosso caso vamos criar um arquivo chamado:
    build.pkr.hcl



locals {
    release = var.release != "" ? var.release : formatdate("YYYYMMDDhhmmss", timestamp())
}


var.release != ""   [se a variável release for diferente de 0 ou nulo]
? var.release       [você vai considerar o valor que estiver na variável release]
 : formatdate("YYYYMMDDhhmmss", timestamp())        [se a variável estiver zerada, ao invés de pegar o valor dela, vai ser colocado o timestamp]




- Página com exemplos, que podem ajudar:
    https://www.packer.io/plugins/builders/amazon/ebs

- Script descomplicando-o-packer/build.pkr.hcl:
~~~hcl
locals {
    release = var.release != "" ? var.release : formatdate("YYYYMMDDhhmmss", timestamp())
}

source "amazon-ebs" "example" {
  # argument

    ssh_username    =   "ubuntu"
    instance_type   =   "t3.medium"
    region          =   "us-east-1"
    ami_name        =   replace("base-${local.image_id}", ".", "-")
    tags = {
        OS_Version  =   "Ubuntu"
        Release     =   "${local.image_id}"
        Base_AMI_Name   =   "{{ .SourceAMIName }}"
        Extra   =   "{{ .SourceAMITags.TagName }}"
        Product = "Base"
    }
}
~~~




# Explicação do replace

~~~hcl
ami_name     =    replace("base-${local.release}", ".", "-")
~~~

https://www.packer.io/docs/templates/hcl_templates/functions/string/replace
É como se fosse um set.
Ele vai pegar o dado de uma string e substituir por outro.
Pegando o valor da variável release, que é a saída da condicional dela.
Trocando tudo que tiver ponto por traço.
Se não tiver ponto, o replace não faz nada, não efetua nenhuma troca.
Isto é feito porque a AMI não pode ter ponto.

Observação:
    ami name não pode ter ponto

Normalmente as releases tem um ponto no nome, então este replace é muito útil.




- Continua em 30:27m


# Dia 19/03/2022

- Continuando em 31:05m


# Definindo o source_ami_filter

- O "source_ami_filter" ajuda a buscar a imagem mais recente, sem precisar estar passando o id da ami, que é trabalhoso de estar procurando.

- Nosso bloco de código do "source_ami_filter" ficará assim:

    source_ami_filter {
        filters = {
        name = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-arm64-server-*"
        root-device-type = "ebs"
        virtualization-type = "hvm"
        }
        owners = ["099720109477"]
        most_recent = true
    }


- No Owners o valor "099720109477" refere-se ao valor da Canonical, indicando confiança a imagem escolhida.


- Ownership Verification
User’s can verify that an AMI was published by Canonical by ensuring the OwnerId field of an image is 099720109477. This ID is stored in SSM and is discoverable by running:
    aws ssm get-parameters --names /aws/service/canonical/meta/publisher-id

~~~bash
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer$ aws ssm get-parameters --names /aws/service/canonical/meta/publisher-id
{
    "Parameters": [
        {
            "Name": "/aws/service/canonical/meta/publisher-id",
            "Type": "String",
            "Value": "099720109477",
            "Version": 2,
            "LastModifiedDate": "2020-06-12T11:17:35.729000-03:00",
            "ARN": "arn:aws:ssm:us-east-1::parameter/aws/service/canonical/meta/publisher-id",
            "DataType": "text"
        }
    ],
    "InvalidParameters": []
}
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer$
~~~




# Definindo o build

- No bloco do build apontamos para o source que iremos usar.
- Definimos um provisioner(pode ser Shell, Ansible, etc)
- Os provisionadores rodam na ordem que são declarados.
~~~hcl
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
~~~





# Variaveis

- Criar um arquivo chamado "variables.pkr.hcl"
- É possível adicionar o parametro "sensitive = true", para deixar a variável "escondida" e não aparecer o valor secreto dela durante o build.
- Não vamos definir um valor para a variável "release", pois é interessante que ele seja sempre informado via Pipeline, caso contrário, o Pipeline não deve avançar/deve quebrar.
~~~hcl
variable "release" {
  type = string
  #default = "v0.7.1" 
  # não é o ideal fixar a versão na variável release, pois ela sempre precisa ser informada.
}
~~~

- Executar o comando "packer init ." para iniciar o projeto:
packer init .
~~~bash
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer$ packer init .
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer$
~~~



- Executando o "packer validate .", para 
~~~bash
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer$ packer validate .
Error: Unset variable "release"

A used variable must be set or have a default value; see
https://packer.io/docs/templates/hcl_templates/syntax for details.


fernando@debian10x64:~/cursos/packer/descomplicando-o-packer$
~~~


- Como não definimos a variável release com um valor default, precisamos informar via parametro no comando:
packer validate -var 'key=value' .
packer validate -var 'release=v0.7.1' .

~~~bash
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer$ packer validate -var 'release=v0.7.1' .
The configuration is valid.
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer$
~~~



- Para buildar, basta usar o comando "packer build -var 'release=v0.7.1' .":
packer build -var 'release=v0.7.1' .
~~~bash
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer$ packer build -var 'release=v0.7.1' .

==> Wait completed after 5 microseconds

==> Builds finished but no artifacts were created.
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer$
~~~

- Neste caso o build não ocorreu, conforme a mensagem "Builds finished but no artifacts were created".
- Reforçando, necessário ter as variáveis de ambiente para as chaves da AWS no local ou na cloud(No repositório onde vai rodar o Pipeline).


- Debugando o packer usando o "PACKER_LOG=1":
PACKER_LOG=1 packer build -var 'release=v0.7.1' .

~~~bash
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer$ PACKER_LOG=1 packer build -var 'release=v0.7.1' .
2022/03/19 13:00:53 [INFO] Packer version: 1.8.0 [go1.17.8 linux amd64]
2022/03/19 13:00:53 [TRACE] discovering plugins in /usr/bin
2022/03/19 13:00:53 [TRACE] discovering plugins in /home/fernando/.config/packer/plugins
2022/03/19 13:00:53 [TRACE] discovering plugins in .
2022/03/19 13:00:53 [INFO] PACKER_CONFIG env var not set; checking the default config file path
2022/03/19 13:00:53 [INFO] PACKER_CONFIG env var set; attempting to open config file: /home/fernando/.packerconfig
2022/03/19 13:00:53 [WARN] Config file doesn t exist: /home/fernando/.packerconfig
2022/03/19 13:00:53 [INFO] Setting cache directory: /home/fernando/.cache/packer
2022/03/19 13:00:53 [TRACE] validateValue: not active for release, so skipping

2022/03/19 13:00:53 Build debug mode: false
2022/03/19 13:00:53 Force build: false
2022/03/19 13:00:53 On error:
2022/03/19 13:00:53 Waiting on builds to complete...
==> Wait completed after 4 microseconds
==> Builds finished but no artifacts were created.
2022/03/19 13:00:53 [INFO] (telemetry) Finalizing.
==> Wait completed after 4 microseconds

==> Builds finished but no artifacts were created.
2022/03/19 13:00:54 waiting for all plugin processes to complete...
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer$
~~~







- Nova tentativa de build:
packer validate -var 'release=v0.7.1' .
packer build -var 'release=v0.7.1' .

Sem sucesso.



- Criado novo script de build, usando exemplo do site:
    https://notificare.com/blog/2021/04/09/building-amis-with-packer/
~~~hcl
locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

# We're creating an image backed by amazon ebs
source "amazon-ebs" "mongodb" {

  ami_name      = "mongodb-packer-image-${local.timestamp}" # This will be the AMI name in AWS
  instance_type = "t3.micro"
  region        = "us-east-1"

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-x86_64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"
}

# a build block invokes sources and runs provisioning steps on them.
build {
  sources = ["source.amazon-ebs.mongodb"]

  provisioner "shell" {
    script = "./scripts/apt_upgrade.sh"
  }

  provisioner "shell" {
    script = "./scripts/install_mongo.sh"
  }
}
~~~

packer validate build.pkr.hcl
packer build build.pkr.hcl

- OCORRERAM ERROS, PT1:
~~~bash
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer$ packer build build.pkr.hcl
amazon-ebs.mongodb: output will be in this color.

==> amazon-ebs.mongodb: Prevalidating any provided VPC information
==> amazon-ebs.mongodb: Prevalidating AMI Name: mongodb-packer-image-20220319161625
    amazon-ebs.mongodb: Found Image ID: ami-04c5f4bf5cfd49669
==> amazon-ebs.mongodb: Creating temporary keypair: packer_623601d9-6c91-7aae-d3a3-bed811ad5f25
==> amazon-ebs.mongodb: Creating temporary security group for this instance: packer_623601de-eeba-76ca-b2d8-f27f5aaee014
==> amazon-ebs.mongodb: Authorizing access to port 22 from [0.0.0.0/0] in the temporary security groups...
==> amazon-ebs.mongodb: Launching a source AWS instance...
==> amazon-ebs.mongodb: Adding tags to source instance
    amazon-ebs.mongodb: Adding tag: "Name": "Packer Builder"
==> amazon-ebs.mongodb: Error launching source instance: InvalidParameterValue: The architecture 'x86_64' of the specified instance type does not match the architecture 'arm64' of the specified AMI. Specify an instance type and an AMI that have matching architectures, and try again. You can use 'describe-instance-types' or 'describe-images' to discover the architecture of the instance type or AMI.
==> amazon-ebs.mongodb:         status code: 400, request id: ab8db650-fa21-426b-8a3c-14469aaa07d7
==> amazon-ebs.mongodb: No volumes to clean up, skipping
==> amazon-ebs.mongodb: Deleting temporary security group...
==> amazon-ebs.mongodb: Deleting temporary keypair...
Build 'amazon-ebs.mongodb' errored after 11 seconds 447 milliseconds: Error launching source instance: InvalidParameterValue: The architecture 'x86_64' of the specified instance type does not match the architecture 'arm64' of the specified AMI. Specify an instance type and an AMI that have matching architectures, and try again. You can use 'describe-instance-types' or 'describe-images' to discover the architecture of the instance type or AMI.
        status code: 400, request id: ab8db650-fa21-426b-8a3c-14469aaa07d7

==> Wait completed after 11 seconds 447 milliseconds

==> Some builds didn t complete successfully and had errors:
--> amazon-ebs.mongodb: Error launching source instance: InvalidParameterValue: The architecture 'x86_64' of the specified instance type does not match the architecture 'arm64' of the specified AMI. Specify an instance type and an AMI that have matching architectures, and try again. You can use 'describe-instance-types' or 'describe-images' to discover the architecture of the instance type or AMI.
        status code: 400, request id: ab8db650-fa21-426b-8a3c-14469aaa07d7

==> Builds finished but no artifacts were created.
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer$
~~~



- Erro devido arquitetura da imagem.
- Alterado arquivo "descomplicando-o-packer/build.pkr.hcl":
    de:
    name                = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-x86_64-server-*"
    para:
    name                = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"


- Novo script:
~~~hcl
locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

# We're creating an image backed by amazon ebs
source "amazon-ebs" "mongodb" {

  ami_name      = "mongodb-packer-image-${local.timestamp}" # This will be the AMI name in AWS
  instance_type = "t3.micro"
  region        = "us-east-1"

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"
}

# a build block invokes sources and runs provisioning steps on them.
build {
  sources = ["source.amazon-ebs.mongodb"]

  provisioner "shell" {
    script = "./scripts/apt_upgrade.sh"
  }

  provisioner "shell" {
    script = "./scripts/install_mongo.sh"
  }
}
~~~

- OCORRERAM ERROS, PT2:
~~~bash
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer$ packer build build.pkr.hcl
amazon-ebs.mongodb: output will be in this color.

==> amazon-ebs.mongodb: Prevalidating any provided VPC information
==> amazon-ebs.mongodb: Prevalidating AMI Name: mongodb-packer-image-20220319161738
    amazon-ebs.mongodb: Found Image ID: ami-01896de1f162f0ab7
==> amazon-ebs.mongodb: Creating temporary keypair: packer_62360222-600f-5d40-3852-9a7544623eb0
==> amazon-ebs.mongodb: Creating temporary security group for this instance: packer_62360226-18ba-14ae-4494-f1e9e0f7cb58
==> amazon-ebs.mongodb: Authorizing access to port 22 from [0.0.0.0/0] in the temporary security groups...
==> amazon-ebs.mongodb: Launching a source AWS instance...
==> amazon-ebs.mongodb: Adding tags to source instance
    amazon-ebs.mongodb: Adding tag: "Name": "Packer Builder"
==> amazon-ebs.mongodb: Error launching source instance: UnauthorizedOperation: You are not authorized to perform this operation. Encoded authorization failure message: CHSvpWgAlLv5Y5jhlobMgrybrcBTeDx5O7-Ff-98k-vybEv5dOqRWY2UutZa-P-ey9Q8MR4p-PGrtaEUPHPsZWZEFbzeE4uTsVX7lf7zhFG7OPO5it6FUHzvVUMdvcB8f8chBMiUckoY5OlM2F9jqEoAB_Izk5dGhX1j8oZbrVNKUkePxYz6E4KLOzy6JN2m5mBODy2_xdQlP3v8L0okJbIRlUMdU4uAo3HLpdcQJrpZ3yDEOrppBpNleG4R4M_CVDV-A8sDlq_So5p668V-TP_D_mfzBp2tpH-mnfeHPANi4shGK6raX1xrzOJlGvaLC5HZgzdf4J-Pnn70zB9F4XpqCiOyhsavYh0Lbn9yW2FJ5sUCN0kgrAthvQDGpDCwt0FpvbBEX0Tuc1kAZGh_AaZ3Z7q7hNG00Pmq1DAf6ObM_IvUjDAGt03JOAz2X_h7gbwgIULO1TZnag-JIQOb_DVyIFNCnFOjLIg96I2YF2CRc41KibRw-ocNM0VtQ-nsQU05IIkENdNiOb957hSpIML_e3zJgxXnTBitUvZ94e6vbGJ4ITUYd6fDJlAKGkRlgrf3OMydikSWLSTFJrSaxFmx-t3Kp1gbP_mK-z-tkuHiK4xum6xGe0vzLB0T0FpMTweKxrXDsPVbPR9B_qIZ6hyz8GZGdaHczsryKMfY0AbDCUkp-iAM-svkA6SCVemWzpU5oeVTOFUOnN-Fv9xXaHE60mb8FfQQsS_6WAGLgpLHEHCR2Slq011adQZdFLQHpuTAyfq4hWFqW5fb5zqS7ZwFGxQ6QK3YKurTv4V7VYvFy9FR2yxVLXv-esNAgKpY7N5xpi9mOYXUqHlDtKeblvNSt_dt-mRU3-6HcPL4UJMkkib8yDWr7lzhStFw_CKFKJKzbVYQfKgc50bV6zpAAsBpD67cyQM_v0KwtlzPbvIrxf_4sVpZelJK_QYDzMj-pnreZD2ws5fW6g8k2W8Gw1_FHUpIVtwb9RD-ZdEppzUkEwwLDVugxhzpEd0V27KjzLdI4-zFLNmawvx0gkhkFpnig9YAuXU0bxE69q_4VE7ZZdghPKGb6Yq9wToNbcWz_usJnslj3tcglFBPGCWydMXsNxzJKGUmsXAcVFvH-ekpx7i5BRYFzDEqre3NWoyemxqqXb62ziDDF5PxhslbXOc1EmpOGLEf6VxmOtYqFFiRbfnmTwmomejbkSKYkpM8xJK_0nNf5jX1pVUVmUKzmsNpBfVZc0f2FKgFeJVbpUG-F3g3WWHQOA9fU4wA8ug9Q072xKPN0TNoX6lBGUw-SjBzg0czMmbciy9NtsYOiZagREhwhcCbteZrk3y4gDMzmg-jkb0kNVNwm0bsMaH9SpAgce9A-6uk-HQwjVJgs1BD7MTNsv-8mRtVdvzQ-yVUhTwKmlKIZ1pk
==> amazon-ebs.mongodb:         status code: 403, request id: 88d96115-1d0e-4371-a404-5bb324fa272d
==> amazon-ebs.mongodb: No volumes to clean up, skipping
==> amazon-ebs.mongodb: Deleting temporary security group...
==> amazon-ebs.mongodb: Deleting temporary keypair...
Build 'amazon-ebs.mongodb' errored after 11 seconds 166 milliseconds: Error launching source instance: UnauthorizedOperation: You are not authorized to perform this operation. Encoded authorization failure message: CHSvpWgAlLv5Y5jhlobMgrybrcBTeDx5O7-Ff-98k-vybEv5dOqRWY2UutZa-P-ey9Q8MR4p-PGrtaEUPHPsZWZEFbzeE4uTsVX7lf7zhFG7OPO5it6FUHzvVUMdvcB8f8chBMiUckoY5OlM2F9jqEoAB_Izk5dGhX1j8oZbrVNKUkePxYz6E4KLOzy6JN2m5mBODy2_xdQlP3v8L0okJbIRlUMdU4uAo3HLpdcQJrpZ3yDEOrppBpNleG4R4M_CVDV-A8sDlq_So5p668V-TP_D_mfzBp2tpH-mnfeHPANi4shGK6raX1xrzOJlGvaLC5HZgzdf4J-Pnn70zB9F4XpqCiOyhsavYh0Lbn9yW2FJ5sUCN0kgrAthvQDGpDCwt0FpvbBEX0Tuc1kAZGh_AaZ3Z7q7hNG00Pmq1DAf6ObM_IvUjDAGt03JOAz2X_h7gbwgIULO1TZnag-JIQOb_DVyIFNCnFOjLIg96I2YF2CRc41KibRw-ocNM0VtQ-nsQU05IIkENdNiOb957hSpIML_e3zJgxXnTBitUvZ94e6vbGJ4ITUYd6fDJlAKGkRlgrf3OMydikSWLSTFJrSaxFmx-t3Kp1gbP_mK-z-tkuHiK4xum6xGe0vzLB0T0FpMTweKxrXDsPVbPR9B_qIZ6hyz8GZGdaHczsryKMfY0AbDCUkp-iAM-svkA6SCVemWzpU5oeVTOFUOnN-Fv9xXaHE60mb8FfQQsS_6WAGLgpLHEHCR2Slq011adQZdFLQHpuTAyfq4hWFqW5fb5zqS7ZwFGxQ6QK3YKurTv4V7VYvFy9FR2yxVLXv-esNAgKpY7N5xpi9mOYXUqHlDtKeblvNSt_dt-mRU3-6HcPL4UJMkkib8yDWr7lzhStFw_CKFKJKzbVYQfKgc50bV6zpAAsBpD67cyQM_v0KwtlzPbvIrxf_4sVpZelJK_QYDzMj-pnreZD2ws5fW6g8k2W8Gw1_FHUpIVtwb9RD-ZdEppzUkEwwLDVugxhzpEd0V27KjzLdI4-zFLNmawvx0gkhkFpnig9YAuXU0bxE69q_4VE7ZZdghPKGb6Yq9wToNbcWz_usJnslj3tcglFBPGCWydMXsNxzJKGUmsXAcVFvH-ekpx7i5BRYFzDEqre3NWoyemxqqXb62ziDDF5PxhslbXOc1EmpOGLEf6VxmOtYqFFiRbfnmTwmomejbkSKYkpM8xJK_0nNf5jX1pVUVmUKzmsNpBfVZc0f2FKgFeJVbpUG-F3g3WWHQOA9fU4wA8ug9Q072xKPN0TNoX6lBGUw-SjBzg0czMmbciy9NtsYOiZagREhwhcCbteZrk3y4gDMzmg-jkb0kNVNwm0bsMaH9SpAgce9A-6uk-HQwjVJgs1BD7MTNsv-8mRtVdvzQ-yVUhTwKmlKIZ1pk
        status code: 403, request id: 88d96115-1d0e-4371-a404-5bb324fa272d

==> Wait completed after 11 seconds 166 milliseconds

==> Some builds didn t complete successfully and had errors:
--> amazon-ebs.mongodb: Error launching source instance: UnauthorizedOperation: You are not authorized to perform this operation. Encoded authorization failure message: CHSvpWgAlLv5Y5jhlobMgrybrcBTeDx5O7-Ff-98k-vybEv5dOqRWY2UutZa-P-ey9Q8MR4p-PGrtaEUPHPsZWZEFbzeE4uTsVX7lf7zhFG7OPO5it6FUHzvVUMdvcB8f8chBMiUckoY5OlM2F9jqEoAB_Izk5dGhX1j8oZbrVNKUkePxYz6E4KLOzy6JN2m5mBODy2_xdQlP3v8L0okJbIRlUMdU4uAo3HLpdcQJrpZ3yDEOrppBpNleG4R4M_CVDV-A8sDlq_So5p668V-TP_D_mfzBp2tpH-mnfeHPANi4shGK6raX1xrzOJlGvaLC5HZgzdf4J-Pnn70zB9F4XpqCiOyhsavYh0Lbn9yW2FJ5sUCN0kgrAthvQDGpDCwt0FpvbBEX0Tuc1kAZGh_AaZ3Z7q7hNG00Pmq1DAf6ObM_IvUjDAGt03JOAz2X_h7gbwgIULO1TZnag-JIQOb_DVyIFNCnFOjLIg96I2YF2CRc41KibRw-ocNM0VtQ-nsQU05IIkENdNiOb957hSpIML_e3zJgxXnTBitUvZ94e6vbGJ4ITUYd6fDJlAKGkRlgrf3OMydikSWLSTFJrSaxFmx-t3Kp1gbP_mK-z-tkuHiK4xum6xGe0vzLB0T0FpMTweKxrXDsPVbPR9B_qIZ6hyz8GZGdaHczsryKMfY0AbDCUkp-iAM-svkA6SCVemWzpU5oeVTOFUOnN-Fv9xXaHE60mb8FfQQsS_6WAGLgpLHEHCR2Slq011adQZdFLQHpuTAyfq4hWFqW5fb5zqS7ZwFGxQ6QK3YKurTv4V7VYvFy9FR2yxVLXv-esNAgKpY7N5xpi9mOYXUqHlDtKeblvNSt_dt-mRU3-6HcPL4UJMkkib8yDWr7lzhStFw_CKFKJKzbVYQfKgc50bV6zpAAsBpD67cyQM_v0KwtlzPbvIrxf_4sVpZelJK_QYDzMj-pnreZD2ws5fW6g8k2W8Gw1_FHUpIVtwb9RD-ZdEppzUkEwwLDVugxhzpEd0V27KjzLdI4-zFLNmawvx0gkhkFpnig9YAuXU0bxE69q_4VE7ZZdghPKGb6Yq9wToNbcWz_usJnslj3tcglFBPGCWydMXsNxzJKGUmsXAcVFvH-ekpx7i5BRYFzDEqre3NWoyemxqqXb62ziDDF5PxhslbXOc1EmpOGLEf6VxmOtYqFFiRbfnmTwmomejbkSKYkpM8xJK_0nNf5jX1pVUVmUKzmsNpBfVZc0f2FKgFeJVbpUG-F3g3WWHQOA9fU4wA8ug9Q072xKPN0TNoX6lBGUw-SjBzg0czMmbciy9NtsYOiZagREhwhcCbteZrk3y4gDMzmg-jkb0kNVNwm0bsMaH9SpAgce9A-6uk-HQwjVJgs1BD7MTNsv-8mRtVdvzQ-yVUhTwKmlKIZ1pk
        status code: 403, request id: 88d96115-1d0e-4371-a404-5bb324fa272d

==> Builds finished but no artifacts were created.
~~~






- Verificado que havia algum problema com as chaves da AWS:
~~~bash
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer$ aws s3 ls

An error occurred (AccessDenied) when calling the ListBuckets operation: Access Denied
~~~

- Ajustando a profile da AWS na AWS CLI do Debian:
~~~bash
export AWS_PROFILE=fernandomuller
echo $AWS_PROFILE
aws sts get-caller-identity
~~~

~~~bash
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer$ aws sts get-caller-identity
{
    "UserId": "AIDA34JOWZ7JIKVYU7Q6F",
    "Account": "816678621138",
    "Arn": "arn:aws:iam::816678621138:user/fernando.muller"
}
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer$
~~~




- Executando nova tentativa de build da imagem do MongoDB:
packer build build.pkr.hcl

~~~bash
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer$ packer build build.pkr.hcl
amazon-ebs.mongodb: output will be in this color.

==> amazon-ebs.mongodb: Prevalidating any provided VPC information
==> amazon-ebs.mongodb: Prevalidating AMI Name: mongodb-packer-image-20220319163907
    amazon-ebs.mongodb: Found Image ID: ami-01896de1f162f0ab7
==> amazon-ebs.mongodb: Creating temporary keypair: packer_6236072b-3cc4-2e55-377a-f6a9dcb8e0e1
==> amazon-ebs.mongodb: Creating temporary security group for this instance: packer_62360732-c64c-d521-8892-d59a04c4abeb
==> amazon-ebs.mongodb: Authorizing access to port 22 from [0.0.0.0/0] in the temporary security groups...
==> amazon-ebs.mongodb: Launching a source AWS instance...
==> amazon-ebs.mongodb: Adding tags to source instance
    amazon-ebs.mongodb: Adding tag: "Name": "Packer Builder"
    amazon-ebs.mongodb: Instance ID: i-03b3656240d285c60
==> amazon-ebs.mongodb: Waiting for instance (i-03b3656240d285c60) to become ready...
==> amazon-ebs.mongodb: Using SSH communicator to connect: 3.94.82.176
==> amazon-ebs.mongodb: Waiting for SSH to become available...
==> amazon-ebs.mongodb: Connected to SSH!
==> amazon-ebs.mongodb: Provisioning with shell script: ./scripts/apt_upgrade.sh
==> amazon-ebs.mongodb:
==> amazon-ebs.mongodb: WARNING: apt does not have a stable CLI interface. Use with caution in scripts.
==> amazon-ebs.mongodb:
    amazon-ebs.mongodb: Hit:1 http://us-east-1.ec2.archive.ubuntu.com/ubuntu focal InRelease
    amazon-ebs.mongodb: Get:2 http://us-east-1.ec2.archive.ubuntu.com/ubuntu focal-updates InRelease [114 kB]
    amazon-ebs.mongodb: Get:3 http://us-east-1.ec2.archive.ubuntu.com/ubuntu focal-backports InRelease [108 kB]
    amazon-ebs.mongodb: Get:4 http://security.ubuntu.com/ubuntu focal-security InRelease [114 kB]
==> amazon-ebs.mongodb: Warning: apt-key output should not be parsed (stdout is not a terminal)
==> amazon-ebs.mongodb: debconf: unable to initialize frontend: Dialog
==> amazon-ebs.mongodb: debconf: (Dialog frontend will not work on a dumb terminal, an emacs shell buffer, or without a controlling terminal.)
==> amazon-ebs.mongodb: debconf: falling back to frontend: Readline
==> amazon-ebs.mongodb: debconf: unable to initialize frontend: Readline
==> amazon-ebs.mongodb: debconf: (This frontend requires a controlling tty.)
==> amazon-ebs.mongodb: debconf: falling back to frontend: Teletype
==> amazon-ebs.mongodb: dpkg-preconfigure: unable to re-open stdin:
    amazon-ebs.mongodb: Processing triggers for man-db (2.9.1-1) ...
==> amazon-ebs.mongodb: chown: changing ownership of '/data': Operation not permitted
==> amazon-ebs.mongodb: Provisioning step had errors: Running the cleanup provisioner, if present...
==> amazon-ebs.mongodb: Terminating the source AWS instance...
==> amazon-ebs.mongodb: Cleaning up any extra volumes...
==> amazon-ebs.mongodb: No volumes to clean up, skipping
==> amazon-ebs.mongodb: Deleting temporary security group...
==> amazon-ebs.mongodb: Deleting temporary keypair...
Build 'amazon-ebs.mongodb' errored after 2 minutes 2 seconds: Script exited with non-zero exit status: 1.Allowed exit codes are: [0]

==> Wait completed after 2 minutes 2 seconds

==> Some builds didn t complete successfully and had errors:
--> amazon-ebs.mongodb: Script exited with non-zero exit status: 1.Allowed exit codes are: [0]

==> Builds finished but no artifacts were created.
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer$
~~~

- Ocorreram erros, devido permissão de uso do chown, precisa estar como root.



- Ajustado o script "descomplicando-o-packer/scripts/install_mongo.sh", adicionando o sudo no inicio:
        DE:
        chown mongodb:mongodb -R /data
        PARA:
        sudo chown mongodb:mongodb -R /data

- Executado o build novamente
packer build build.pkr.hcl

~~~bash
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer$ packer build build.pkr.hcl
amazon-ebs.mongodb: output will be in this color.
==> amazon-ebs.mongodb: Prevalidating any provided VPC information
==> amazon-ebs.mongodb: Prevalidating AMI Name: mongodb-packer-image-20220319164311
    amazon-ebs.mongodb: Found Image ID: ami-01896de1f162f0ab7
==> amazon-ebs.mongodb: Creating temporary keypair: packer_6236081f-f93e-278e-7339-f61cc6d98c62
==> amazon-ebs.mongodb: Creating temporary security group for this instance: packer_62360823-c5e5-d64b-9291-8dd8dce2d84d
==> amazon-ebs.mongodb: Authorizing access to port 22 from [0.0.0.0/0] in the temporary security groups...
==> amazon-ebs.mongodb: Launching a source AWS instance...
==> amazon-ebs.mongodb: Adding tags to source instance
    amazon-ebs.mongodb: Adding tag: "Name": "Packer Builder"
    amazon-ebs.mongodb: Instance ID: i-0926aa15abb5f6e43
==> amazon-ebs.mongodb: Waiting for instance (i-0926aa15abb5f6e43) to become ready...
==> amazon-ebs.mongodb: Using SSH communicator to connect: 44.201.132.142
==> amazon-ebs.mongodb: Waiting for SSH to become available...
==> amazon-ebs.mongodb: Connected to SSH!
==> amazon-ebs.mongodb: Provisioning with shell script: ./scripts/apt_upgrade.sh
==> amazon-ebs.mongodb:
==> amazon-ebs.mongodb: WARNING: apt does not have a stable CLI interface. Use with caution in scripts.
==> amazon-ebs.mongodb:
    amazon-ebs.mongodb: Hit:1 http://us-east-1.ec2.archive.ubuntu.com/ubuntu focal InRelease
    amazon-ebs.mongodb: Get:2 http://us-east-1.ec2.archive.ubuntu.com/ubuntu focal-updates InRelease [114 kB]
    amazon-ebs.mongodb: Get:3 http://us-east-1.ec2.archive.ubuntu.com/ubuntu focal-backports InRelease [108 kB]
    amazon-ebs.mongodb: Get:4 http://us-east-1.ec2.archive.ubuntu.com/ubuntu focal/universe amd64 Packages [8628 kB]
    amazon-ebs.mongodb: Get:5 http://us-east-1.ec2.archive.ubuntu.com/ubuntu focal/universe Translation-en [5124 kB]
    amazon-ebs.mongodb: Get:6 http://us-east-1.ec2.archive.ubuntu.com/ubuntu focal/universe amd64 c-n-f Metadata [265 kB]
    amazon-ebs.mongodb: Get:7 http://us-east-1.ec2.archive.ubuntu.com/ubuntu focal/multiverse amd64 Packages [144 kB]
    amazon-ebs.mongodb: Get:8 http://security.ubuntu.com/ubuntu focal-security InRelease [114 kB]
 amazon-ebs.mongodb: Get:6 https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4/multiverse amd64 mongodb-org-tools amd64 4.4.13 [2896 B]
    amazon-ebs.mongodb: Get:7 https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4/multiverse amd64 mongodb-org amd64 4.4.13 [3520 B]
==> amazon-ebs.mongodb: debconf: unable to initialize frontend: Dialog
==> amazon-ebs.mongodb: debconf: (Dialog frontend will not work on a dumb terminal, an emacs shell buffer, or without a controlling terminal.)
==> amazon-ebs.mongodb: debconf: falling back to frontend: Readline
==> amazon-ebs.mongodb: debconf: unable to initialize frontend: Readline
==> amazon-ebs.mongodb: debconf: (This frontend requires a controlling tty.)
==> amazon-ebs.mongodb: debconf: falling back to frontend: Teletype
==> amazon-ebs.mongodb: dpkg-preconfigure: unable to re-open stdin:
    amazon-ebs.mongodb: Fetched 96.6 MB in 2s (59.9 MB/s)
    amazon-ebs.mongodb: Selecting previously unselected package mongodb-database-tools.
    amazon-ebs.mongodb: (Reading database ... 60993 files and directories currently installed.)
    amazon-ebs.mongodb: Preparing to unpack .../0-mongodb-database-tools_100.5.2_amd64.deb ...
    amazon-ebs.mongodb: Unpacking mongodb-database-tools (100.5.2) ...
    amazon-ebs.mongodb: Selecting previously unselected package mongodb-org-shell.
    amazon-ebs.mongodb: Preparing to unpack .../1-mongodb-org-shell_4.4.13_amd64.deb ...
    amazon-ebs.mongodb: Unpacking mongodb-org-shell (4.4.13) ...
    amazon-ebs.mongodb: Selecting previously unselected package mongodb-org-server.
    amazon-ebs.mongodb: Preparing to unpack .../2-mongodb-org-server_4.4.13_amd64.deb ...
    amazon-ebs.mongodb: Unpacking mongodb-org-server (4.4.13) ...
    amazon-ebs.mongodb: Selecting previously unselected package mongodb-org-mongos.
    amazon-ebs.mongodb: Preparing to unpack .../3-mongodb-org-mongos_4.4.13_amd64.deb ...
    amazon-ebs.mongodb: Unpacking mongodb-org-mongos (4.4.13) ...
    amazon-ebs.mongodb: Selecting previously unselected package mongodb-org-database-tools-extra.
    amazon-ebs.mongodb: Preparing to unpack .../4-mongodb-org-database-tools-extra_4.4.13_amd64.deb ...
    amazon-ebs.mongodb: Unpacking mongodb-org-database-tools-extra (4.4.13) ...
    amazon-ebs.mongodb: Selecting previously unselected package mongodb-org-tools.
    amazon-ebs.mongodb: Preparing to unpack .../5-mongodb-org-tools_4.4.13_amd64.deb ...
    amazon-ebs.mongodb: Unpacking mongodb-org-tools (4.4.13) ...
    amazon-ebs.mongodb: Selecting previously unselected package mongodb-org.
    amazon-ebs.mongodb: Preparing to unpack .../6-mongodb-org_4.4.13_amd64.deb ...
    amazon-ebs.mongodb: Unpacking mongodb-org (4.4.13) ...
    amazon-ebs.mongodb: Setting up mongodb-org-server (4.4.13) ...
    amazon-ebs.mongodb: Adding system user `mongodb (UID 113) ...
    amazon-ebs.mongodb: Adding new user `mongodb' (UID 113) with group `nogroup' ...
    amazon-ebs.mongodb: Not creating home directory `/home/mongodb'.
    amazon-ebs.mongodb: Adding group `mongodb' (GID 119) ...
    amazon-ebs.mongodb: Done.
    amazon-ebs.mongodb: Adding user `mongodb' to group `mongodb' ...
    amazon-ebs.mongodb: Adding user mongodb to group mongodb
    amazon-ebs.mongodb: Done.
    amazon-ebs.mongodb: Setting up mongodb-org-shell (4.4.13) ...
    amazon-ebs.mongodb: Setting up mongodb-database-tools (100.5.2) ...
    amazon-ebs.mongodb: Setting up mongodb-org-mongos (4.4.13) ...
    amazon-ebs.mongodb: Setting up mongodb-org-database-tools-extra (4.4.13) ...
    amazon-ebs.mongodb: Setting up mongodb-org-tools (4.4.13) ...
    amazon-ebs.mongodb: Setting up mongodb-org (4.4.13) ...
    amazon-ebs.mongodb: Processing triggers for man-db (2.9.1-1) ...
==> amazon-ebs.mongodb: Stopping the source instance...
    amazon-ebs.mongodb: Stopping instance
==> amazon-ebs.mongodb: Waiting for the instance to stop...
==> amazon-ebs.mongodb: Creating AMI mongodb-packer-image-20220319164311 from instance i-0926aa15abb5f6e43
    amazon-ebs.mongodb: AMI: ami-0907879fa1d59e340
==> amazon-ebs.mongodb: Waiting for AMI to become ready...
==> amazon-ebs.mongodb: Skipping Enable AMI deprecation...
==> amazon-ebs.mongodb: Terminating the source AWS instance...
==> amazon-ebs.mongodb: Cleaning up any extra volumes...
==> amazon-ebs.mongodb: No volumes to clean up, skipping
==> amazon-ebs.mongodb: Deleting temporary security group...
==> amazon-ebs.mongodb: Deleting temporary keypair...
Build 'amazon-ebs.mongodb' finished after 5 minutes 27 seconds.

==> Wait completed after 5 minutes 27 seconds

==> Builds finished. The artifacts of successful builds are:
--> amazon-ebs.mongodb: AMIs were created:
us-east-1: ami-0907879fa1d59e340

fernando@debian10x64:~/cursos/packer/descomplicando-o-packer$
~~~




- Ajustado o arquivo de build, para buildar a imagem original do projeto "Descomplicando o Packer".
- Testando novamente o build:
packer validate -var 'release=v0.7.1' .
packer build -var 'release=v0.7.1' .

~~~bash
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer$ packer validate -var 'release=v0.7.1' .
Error: Attribute redefined

  on build.pkr.hcl line 30, in source "amazon-ebs" "example":
  30:     ssh_username = "ubuntu"

The argument "ssh_username" was already set at build.pkr.hcl:9,5-17. Each
argument may be set only once.

fernando@debian10x64:~/cursos/packer/descomplicando-o-packer$ ^C
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer$ ^C
~~~


- Removido o campo "ssh_username" duplicado e testado novamente:
~~~bash
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer$ packer validate -var 'release=v0.7.1' .
The configuration is valid.
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer$
~~~


~~~bash
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer$ packer build -var 'release=v0.7.1' .
amazon-ebs.example: output will be in this color.

==> amazon-ebs.example: Prevalidating any provided VPC information
==> amazon-ebs.example: Prevalidating AMI Name: base-v0-7-1
    amazon-ebs.example: Found Image ID: ami-01896de1f162f0ab7
==> amazon-ebs.example: Creating temporary keypair: packer_62360c05-bde6-424c-786b-aac174ef2fad
==> amazon-ebs.example: Creating temporary security group for this instance: packer_62360c09-e6a5-16d2-6b89-e6301cd184aa
==> amazon-ebs.example: Authorizing access to port 22 from [0.0.0.0/0] in the temporary security groups...
==> amazon-ebs.example: Launching a source AWS instance...
==> amazon-ebs.example: Adding tags to source instance
    amazon-ebs.example: Adding tag: "Name": "Packer Builder"
    amazon-ebs.example: Instance ID: i-030b8be9b288c0f78
==> amazon-ebs.example: Waiting for instance (i-030b8be9b288c0f78) to become ready...
==> amazon-ebs.example: Using SSH communicator to connect: 34.230.44.145
==> amazon-ebs.example: Waiting for SSH to become available...
==> amazon-ebs.example: Connected to SSH!
==> amazon-ebs.example: Provisioning with shell script: /tmp/packer-shell2987927976
    amazon-ebs.example: provisioning all the things
==> amazon-ebs.example: Stopping the source instance...
    amazon-ebs.example: Stopping instance
==> amazon-ebs.example: Waiting for the instance to stop...
==> amazon-ebs.example: Creating AMI base-v0-7-1 from instance i-030b8be9b288c0f78
    amazon-ebs.example: AMI: ami-0ab4faa9a01e16200
==> amazon-ebs.example: Waiting for AMI to become ready...
==> amazon-ebs.example: Skipping Enable AMI deprecation...
==> amazon-ebs.example: Adding tags to AMI (ami-0ab4faa9a01e16200)...
==> amazon-ebs.example: Tagging snapshot: snap-0f5444f536a33612f
==> amazon-ebs.example: Creating AMI tags
    amazon-ebs.example: Adding tag: "Extra": "<no value>"
    amazon-ebs.example: Adding tag: "OS_Version": "Ubuntu"
    amazon-ebs.example: Adding tag: "Product": "Base"
    amazon-ebs.example: Adding tag: "Release": "v0.7.1"
    amazon-ebs.example: Adding tag: "Base_AMI_Name": "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20220308"
==> amazon-ebs.example: Creating snapshot tags
==> amazon-ebs.example: Terminating the source AWS instance...
==> amazon-ebs.example: Cleaning up any extra volumes...
==> amazon-ebs.example: No volumes to clean up, skipping
==> amazon-ebs.example: Deleting temporary security group...
==> amazon-ebs.example: Deleting temporary keypair...
Build 'amazon-ebs.example' finished after 3 minutes 23 seconds.

==> Wait completed after 3 minutes 23 seconds

==> Builds finished. The artifacts of successful builds are:
--> amazon-ebs.example: AMIs were created:
us-east-1: ami-0ab4faa9a01e16200

fernando@debian10x64:~/cursos/packer/descomplicando-o-packer$
~~~



- Versão OK, que buildou conforme o esperado:
~~~hcl
locals {
    release      =    var.release != "" ? var.release : formatdate("YYYYMMDDhhmmss", timestamp())
    ami_name     =    replace("base-${local.release}", ".", "-")
}

source "amazon-ebs" "example" {
    # argument

    ssh_username    =   "ubuntu"
    instance_type   =   "t3.micro"
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
            name                    = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
            root-device-type        = "ebs"
            virtualization-type     = "hvm"
        }
        owners = ["099720109477"]
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
}
~~~




- Provisionou a imagem corretamente:
Packer Builder	ami-0ab4faa9a01e16200	base-v0-7-1	816678621138/base-v0-7-1









# Terraform

- Criar uma pasta chamada "terraform", para guardar os arquivos do Terraform.
- Criar um arquivo chamado "main.tf", dentro da pasta terraform.


# Data

- O Data no Terraform é uma forma do Terraform obter dados de outros serviços.

- Exemplo de data source para ami na aws:
    https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami
Data Source: aws_ami
Use this data source to get the ID of a registered AMI for use in other resources.

- Basicamente o arquivo do Terraform vai usar o Data para dizer "Traga a informação do AMI ID com base nos filtros que estou passando".



- Criar arquivo variable.tf

- O bacana da integração do Packer com o Terraform é que ao executar um Terraform Plan, ele já apresenta a falha caso não encontre a AMI, baseado nos filtros.

cd terraform
terraform init
terraform plan -out plan_file




fernando@debian10x64:~/cursos/packer/descomplicando-o-packer/terraform$ terraform plan -out plan_file
╷
│ Error: Your query returned no results. Please change your search criteria and try again.
│
│   with data.aws_ami.ubuntu,
│   on instance.tf line 1, in data "aws_ami" "ubuntu":
│    1: data "aws_ami" "ubuntu" {
│
╵
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer/terraform$




-Removida linha do arquivo "instance.tf":
    name_regex       = "^myami-\\d{3}"





terraform plan -out plan_file

fernando@debian10x64:~/cursos/packer/descomplicando-o-packer/terraform$ terraform plan -out plan_file

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_instance.main will be created
  + resource "aws_instance" "main" {
      + ami                                  = "ami-0ab4faa9a01e16200"
      + arn                                  = (known after apply)
      + associate_public_ip_address          = (known after apply)
[...]
Plan: 1 to add, 0 to change, 0 to destroy.

──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Saved the plan to: plan_file

To perform exactly these actions, run the following command to apply:
    terraform apply "plan_file"
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer/terraform$


- Verificado que o plan vai usar a imagem com a ami id que criamos:
    "ami-0ab4faa9a01e16200"


terraform apply "plan_file"

fernando@debian10x64:~/cursos/packer/descomplicando-o-packer/terraform$ ^C
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer/terraform$ terraform apply "plan_file"
aws_instance.main: Creating...
aws_instance.main: Still creating... [10s elapsed]
aws_instance.main: Creation complete after 20s [id=i-014a9f30a4e0117d0]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer/terraform$




- Observação:
Na AWS não é possível alterar/destruir a ami que está em uso por alguma instância.



- Mudando a versão do projeto.
- Supondo que a release tenha que mudar, devido alterações ocorridas.

cd /home/fernando/cursos/packer/descomplicando-o-packer/
packer build -var 'release=v0.7.2' .


fernando@debian10x64:~/cursos/packer/descomplicando-o-packer/terraform$ cd /home/fernando/cursos/packer/descomplicando-o-packer/
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer$ packer build -var 'release=v0.7.2' .
amazon-ebs.example: output will be in this color.

==> amazon-ebs.example: Prevalidating any provided VPC information
==> amazon-ebs.example: Prevalidating AMI Name: base-v0-7-2
    amazon-ebs.example: Found Image ID: ami-01896de1f162f0ab7
==> amazon-ebs.example: Creating temporary keypair: packer_62362e59-dcfd-0a12-5672-c544889ecc8b
==> amazon-ebs.example: Creating temporary security group for this instance: packer_62362e5d-cd61-fd0e-659b-851d79883a8c
==> amazon-ebs.example: Authorizing access to port 22 from [0.0.0.0/0] in the temporary security groups...
==> amazon-ebs.example: Launching a source AWS instance...
==> amazon-ebs.example: Adding tags to source instance
    amazon-ebs.example: Adding tag: "Name": "Packer Builder"
    amazon-ebs.example: Instance ID: i-0663e89fc7b49f0cd
==> amazon-ebs.example: Waiting for instance (i-0663e89fc7b49f0cd) to become ready...
==> amazon-ebs.example: Using SSH communicator to connect: 44.201.185.108
==> amazon-ebs.example: Waiting for SSH to become available...
==> amazon-ebs.example: Connected to SSH!
==> amazon-ebs.example: Provisioning with shell script: /tmp/packer-shell236265176
    amazon-ebs.example: provisioning all the things
==> amazon-ebs.example: Stopping the source instance...
    amazon-ebs.example: Stopping instance
==> amazon-ebs.example: Waiting for the instance to stop...
==> amazon-ebs.example: Creating AMI base-v0-7-2 from instance i-0663e89fc7b49f0cd
    amazon-ebs.example: AMI: ami-0daaeb3aa7ff3b270
==> amazon-ebs.example: Waiting for AMI to become ready...
==> amazon-ebs.example: Skipping Enable AMI deprecation...
==> amazon-ebs.example: Adding tags to AMI (ami-0daaeb3aa7ff3b270)...
==> amazon-ebs.example: Tagging snapshot: snap-0b0fa8c672e874566
==> amazon-ebs.example: Creating AMI tags
    amazon-ebs.example: Adding tag: "Base_AMI_Name": "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20220308"
    amazon-ebs.example: Adding tag: "Extra": "<no value>"
    amazon-ebs.example: Adding tag: "OS_Version": "Ubuntu"
    amazon-ebs.example: Adding tag: "Product": "Base"
    amazon-ebs.example: Adding tag: "Release": "v0.7.2"
==> amazon-ebs.example: Creating snapshot tags
==> amazon-ebs.example: Terminating the source AWS instance...
==> amazon-ebs.example: Cleaning up any extra volumes...
==> amazon-ebs.example: No volumes to clean up, skipping
==> amazon-ebs.example: Deleting temporary security group...
==> amazon-ebs.example: Deleting temporary keypair...
Build 'amazon-ebs.example' finished after 3 minutes 8 seconds.

==> Wait completed after 3 minutes 8 seconds

==> Builds finished. The artifacts of successful builds are:
--> amazon-ebs.example: AMIs were created:
us-east-1: ami-0daaeb3aa7ff3b270

fernando@debian10x64:~/cursos/packer/descomplicando-o-packer$


fernando@debian10x64:~/cursos/packer/descomplicando-o-packer$ cd /home/fernando/cursos/packer/descomplicando-o-packer/
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer$ packer build -var 'release=v0.7.2' .
amazon-ebs.example: output will be in this color.

==> amazon-ebs.example: Prevalidating any provided VPC information
==> amazon-ebs.example: Prevalidating AMI Name: base-v0-7-2
==> amazon-ebs.example: Error: AMI Name: 'base-v0-7-2' is used by an existing AMI: ami-0daaeb3aa7ff3b270
Build 'amazon-ebs.example' errored after 2 seconds 414 milliseconds: Error: AMI Name: 'base-v0-7-2' is used by an existing AMI: ami-0daaeb3aa7ff3b270

==> Wait completed after 2 seconds 414 milliseconds

==> Some builds didn't complete successfully and had errors:
--> amazon-ebs.example: Error: AMI Name: 'base-v0-7-2' is used by an existing AMI: ami-0daaeb3aa7ff3b270

==> Builds finished but no artifacts were created.
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer$





cd /home/fernando/cursos/packer/descomplicando-o-packer/terraform
terraform plan -out plan_file

~~~bash
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer$ cd /home/fernando/cursos/packer/descomplicando-o-packer/terraform
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer/terraform$ terraform plan -out plan_file
aws_instance.main: Refreshing state... [id=i-014a9f30a4e0117d0]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
-/+ destroy and then create replacement

Terraform will perform the following actions:

  # aws_instance.main must be replaced
-/+ resource "aws_instance" "main" {
      ~ ami                                  = "ami-0ab4faa9a01e16200" -> "ami-0daaeb3aa7ff3b270" # forces replacement
      ~ arn                                  = "arn:aws:ec2:us-east-1:816678621138:instance/i-014a9f30a4e0117d0" -> (known after apply)
      ~ associate_public_ip_address          = true -> (known after apply)
      ~ availability_zone                    = "us-east-1b" -> (known after apply)
      ~ cpu_core_count                       = 1 -> (known after apply)
      ~ cpu_threads_per_core                 = 2 -> (known after apply)
      ~ disable_api_termination              = false -> (known after apply)
      ~ ebs_optimized                        = false -> (known after apply)
      - hibernation                          = false -> null
      + host_id                              = (known after apply)
      ~ id                                   = "i-014a9f30a4e0117d0" -> (known after apply)
      ~ instance_initiated_shutdown_behavior = "stop" -> (known after apply)
      ~ instance_state                       = "running" -> (known after apply)
      ~ ipv6_address_count                   = 0 -> (known after apply)
      ~ ipv6_addresses                       = [] -> (known after apply)
      ~ monitoring                           = false -> (known after apply)
      + outpost_arn                          = (known after apply)
      + password_data                        = (known after apply)
      + placement_group                      = (known after apply)
      + placement_partition_number           = (known after apply)
      ~ primary_network_interface_id         = "eni-08126a0e57f45d2ca" -> (known after apply)
      ~ private_dns                          = "ip-172-31-94-53.ec2.internal" -> (known after apply)
      ~ private_ip                           = "172.31.94.53" -> (known after apply)
      ~ public_dns                           = "ec2-54-204-208-35.compute-1.amazonaws.com" -> (known after apply)
      ~ public_ip                            = "54.204.208.35" -> (known after apply)
      ~ secondary_private_ips                = [] -> (known after apply)
      ~ security_groups                      = [
          - "default",
        ] -> (known after apply)
      ~ subnet_id                            = "subnet-817c58a0" -> (known after apply)
        tags                                 = {
            "Name" = "phoenix"
        }
      ~ tenancy                              = "default" -> (known after apply)
      + user_data_base64                     = (known after apply)
      ~ vpc_security_group_ids               = [
          - "sg-ce5ae9d2",
        ] -> (known after apply)
        # (6 unchanged attributes hidden)

      ~ capacity_reservation_specification {
          ~ capacity_reservation_preference = "open" -> (known after apply)

          + capacity_reservation_target {
              + capacity_reservation_id = (known after apply)
            }
        }

      - credit_specification {
          - cpu_credits = "unlimited" -> null
        }

      + ebs_block_device {
          + delete_on_termination = (known after apply)
          + device_name           = (known after apply)
          + encrypted             = (known after apply)
          + iops                  = (known after apply)
          + kms_key_id            = (known after apply)
          + snapshot_id           = (known after apply)
          + tags                  = (known after apply)
          + throughput            = (known after apply)
          + volume_id             = (known after apply)
          + volume_size           = (known after apply)
          + volume_type           = (known after apply)
        }

      ~ enclave_options {
          ~ enabled = false -> (known after apply)
        }

      + ephemeral_block_device {
          + device_name  = (known after apply)
          + no_device    = (known after apply)
          + virtual_name = (known after apply)
        }

      ~ metadata_options {
          ~ http_endpoint               = "enabled" -> (known after apply)
          ~ http_put_response_hop_limit = 1 -> (known after apply)
          ~ http_tokens                 = "optional" -> (known after apply)
        }

      + network_interface {
          + delete_on_termination = (known after apply)
          + device_index          = (known after apply)
          + network_interface_id  = (known after apply)
        }

      ~ root_block_device {
          ~ delete_on_termination = true -> (known after apply)
          ~ device_name           = "/dev/sda1" -> (known after apply)
          ~ encrypted             = false -> (known after apply)
          ~ iops                  = 100 -> (known after apply)
          + kms_key_id            = (known after apply)
          ~ tags                  = {} -> (known after apply)
          ~ throughput            = 0 -> (known after apply)
          ~ volume_id             = "vol-0f57a6ea7e4392af6" -> (known after apply)
          ~ volume_size           = 8 -> (known after apply)
          ~ volume_type           = "gp2" -> (known after apply)
        }
    }

Plan: 1 to add, 0 to change, 1 to destroy.

──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Saved the plan to: plan_file

To perform exactly these actions, run the following command to apply:
    terraform apply "plan_file"
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer/terraform$
~~~

- No plan acima, ele vai destruir 1 recurso(a instancia que foi criada antes) e vai criar uma nova com base na nova release.




- Terraform tem um parametro chamado lifecycle.

https://www.terraform.io/language/meta-arguments/lifecycle
~~~hcl
resource "aws_instance" "example" {
  # ...

  lifecycle {
    ignore_changes = [
      # Ignore changes to tags, e.g. because a management agent
      # updates these based on some ruleset managed elsewhere.
      tags,
    ]
  }
}
~~~


- Com este recurso do lifecycle do Terraform, podemos dizer para ele ignorar as mudanças na ami, por exemplo.
~~~hcl
  lifecycle {
    ignore_changes = [
      ami,
    ]
  }
~~~

- Editar o arquivo instance.tf



- Efetuar novo plan com o lifecycle aplicado no arquivo instance.tf
~~~bash
cd /home/fernando/cursos/packer/descomplicando-o-packer/terraform
terraform plan -out plan_file
~~~

~~~bash
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer/terraform$ cd /home/fernando/cursos/packer/descomplicando-o-packer/terraform
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer/terraform$ terraform plan -out plan_file
aws_instance.main: Refreshing state... [id=i-014a9f30a4e0117d0]

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration and found no differences, so no changes are needed.
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer/terraform$
~~~





terraform destroy

~~~bash
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer/terraform$ terraform destroy
aws_instance.main: Refreshing state... [id=i-014a9f30a4e0117d0]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  # aws_instance.main will be destroyed
  - resource "aws_instance" "main" {
      - ami                                  = "ami-0ab4faa9a01e16200" -> null
      - arn                                  = "arn:aws:ec2:us-east-1:816678621138:instance/i-014a9f30a4e0117d0" -> null
      - associate_public_ip_address          = true -> null
      - availability_zone                    = "us-east-1b" -> null
      - cpu_core_count                       = 1 -> null
      - cpu_threads_per_core                 = 2 -> null
      - disable_api_termination              = false -> null

Plan: 0 to add, 0 to change, 1 to destroy.

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

aws_instance.main: Destroying... [id=i-014a9f30a4e0117d0]
aws_instance.main: Still destroying... [id=i-014a9f30a4e0117d0, 10s elapsed]
aws_instance.main: Still destroying... [id=i-014a9f30a4e0117d0, 20s elapsed]
aws_instance.main: Still destroying... [id=i-014a9f30a4e0117d0, 30s elapsed]
aws_instance.main: Still destroying... [id=i-014a9f30a4e0117d0, 40s elapsed]
aws_instance.main: Still destroying... [id=i-014a9f30a4e0117d0, 50s elapsed]
aws_instance.main: Still destroying... [id=i-014a9f30a4e0117d0, 1m0s elapsed]
aws_instance.main: Destruction complete after 1m6s

Destroy complete! Resources: 1 destroyed.
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer/terraform$
~~~





- Editado o instace.tf
- Adicionado o lifecycle
- Agora o terraform plan já busca a nova ami("ami-0daaeb3aa7ff3b270"), devido a instancia que foi destruida:
~~~bash
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer/terraform$ terraform plan

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_instance.main will be created
  + resource "aws_instance" "main" {
      + ami                                  = "ami-0daaeb3aa7ff3b270"
[...]
Plan: 1 to add, 0 to change, 0 to destroy.

──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply" now.
fernando@debian10x64:~/cursos/packer/descomplicando-o-packer/terraform$

~~~