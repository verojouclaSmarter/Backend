variable "sam_batch_trigger_lambda_zip_path" {
  description = "Path to the lambda zip artifact"
  type        = string
  default     = "assets/lambda/batch-transform-trigger.zip"
}

variable "sam_batch_trigger_lambda_handler" {
  description = "Lambda handler"
  type        = string
  default     = "app.lambda_handler"
}

variable "sam_batch_trigger_lambda_runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.11"
}
