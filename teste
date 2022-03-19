


# Aula - Descomplicando o Packer

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

- v1
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


