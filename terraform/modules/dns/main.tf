data "aws_route53_zone" "main" {
  name         = var.base_domain
  private_zone = false
}
