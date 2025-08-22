# resource "aws_route53_record" "nodejs" {
#   zone_id = "Z03560981K5AILGFN9YQH"  # Replace with your Zone ID
#   name    = "app.k8s.mgrant.in"  # Replace with your domain name
#   type    = "A"
#   alias {
#     name                   = module.alb.alb_dns_name
#     zone_id                = module.alb.alb_zone_id
#     evaluate_target_health = true
#   }
# }
