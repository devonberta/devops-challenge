data "aws_ami" "ubuntu-image" {
  most_recent = true
  owners      = ["767397899482"] # Canonical (Ubuntu)

  filter {
    name   = "name"
    values = [var.deployment.ubuntu-image-id]
  }
}