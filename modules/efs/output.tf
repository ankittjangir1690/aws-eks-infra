output "efs_id" {
  value = aws_efs_file_system.eks_efs.id
}

output "security_group_id" {
  value = aws_security_group.efs_sg.id
}   