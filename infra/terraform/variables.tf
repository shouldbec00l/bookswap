variable "aws_region" {
  description = "AWS-регіон (відповідає Deployment View з Лаб. 1)"
  type        = string
  default     = "eu-central-1"
}

variable "environment" {
  description = "Назва середовища (staging / production)"
  type        = string
  default     = "staging"
}

variable "project_name" {
  description = "Префікс для імен ресурсів"
  type        = string
  default     = "bookswap"
}

variable "vpc_cidr" {
  description = "CIDR віртуальної приватної мережі"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR публічної підмережі"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "Тип EC2 (t3.micro входить у Free Tier для eu-central-1)"
  type        = string
  default     = "t3.micro"
}

variable "root_volume_size_gb" {
  description = "Розмір кореневого диска, ГБ (Free Tier: до 30 ГБ EBS)"
  type        = number
  default     = 20

  validation {
    condition     = var.root_volume_size_gb >= 8 && var.root_volume_size_gb <= 30
    error_message = "Розмір диска має бути в межах 8–30 ГБ (ліміт Free Tier)."
  }
}

variable "ssh_public_key_path" {
  description = "Шлях до публічного SSH-ключа, який потрапить на сервер"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "ssh_private_key_path" {
  description = "Шлях до приватного ключа (записується в Ansible-інвентар)"
  type        = string
  default     = "~/.ssh/id_ed25519"
}

variable "allowed_ssh_cidrs" {
  description = "CIDR-и, з яких дозволено SSH (порт 22). Вкажіть свій IP, напр. 203.0.113.7/32"
  type        = list(string)

  validation {
    condition     = !contains(var.allowed_ssh_cidrs, "0.0.0.0/0")
    error_message = "SSH не можна відкривати для всього інтернету (0.0.0.0/0): принцип найменших привілеїв."
  }
}

variable "ansible_user" {
  description = "Користувач ОС за замовчуванням в AMI (Ubuntu → ubuntu)"
  type        = string
  default     = "ubuntu"
}

variable "ubuntu_ami_id" {
  description = "AMI ID для Ubuntu 24.04 LTS у вибраному регіоні"
  type        = string
}