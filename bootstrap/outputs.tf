output "state_bucket_name" {
  description = "Bucket name of the State File"
  value = aws_s3_bucket.terraform_state.bucket
}

# output "dynamodb_table" {
#   description = "Dynamo DB table used for State Locking"
#   value = aws_dynamodb_table.terraform_state.name
# }

output "region" {
  description = "Region used for Deploying the bucket"
  value = var.region
}