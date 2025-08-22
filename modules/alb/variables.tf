variable "vpc_id" {
  description = "The ID of the VPC where the ALB will be created"
  type        = string
}
variable "subnets" {
  description = "List of subnet IDs to attach to the ALB"
  type        = list(string)
}
variable "acm_certificate_arn" {
  description = "The ARN of the ACM certificate for HTTPS"
  type        = string
}