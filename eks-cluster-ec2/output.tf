# Outputs for the infrastructure setup
output "s3_bucket_name" {
  value = aws_s3_bucket.my_bucket.bucket
}
output "sqs_queue_url" {
  value = aws_sqs_queue.my_queue.url
}