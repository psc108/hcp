resource "aws_efs_file_system" "efs-install" {
  creation_token   = "efs-install"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
}

resource "aws_efs_mount_target" "efs-mt" {
  file_system_id  = aws_efs_file_system.efs-install.id
  subnet_id = aws_subnet.private[0].id
}

resource "aws_efs_access_point" "install-access-point" {
  file_system_id = aws_efs_file_system.efs-install.id

  root_directory {
    path = "/install"
  }
}