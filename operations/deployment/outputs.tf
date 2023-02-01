output "instance_public_dns" {
  description = "Public DNS address of the GCP VM instance"
  #   value       = var.ec2_instance_public_ip ? aws_instance.server.public_dns : "EC2 Instance doesn't have public DNS"
  value = google_compute_instance.gcp_instance.network_interface[0].access_config[0].nat_ip
}

output "instance_id" {
  description = "ssh'able name of the instance"
  value       = google_compute_instance.gcp_instance.id
}

output "bucket_name" {
  value = google_storage_bucket.default.name
}
