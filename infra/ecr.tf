resource "aws_ecr_repository" "lambda_duckdb" {
  name                 = "lambda_duckdb"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "terraform_data" "docker_build" {
  triggers_replace = [
    filemd5("${path.module}/app/Dockerfile"),
    filemd5("${path.module}/app/main.py"),
    filemd5("${path.module}/app/requirements.txt"),
  ]

  provisioner "local-exec" {
    command = <<-EOT
      # Login to ECR
      aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.lambda_duckdb.repository_url}
      
      # Build Docker image
      docker build -t ${aws_ecr_repository.lambda_duckdb.repository_url}:latest ${path.module}/app
      
      # Push image to ECR
      docker push ${aws_ecr_repository.lambda_duckdb.repository_url}:latest
    EOT
  }

  depends_on = [aws_ecr_repository.lambda_duckdb]
}

data "aws_ecr_image" "lambda_image" {
  repository_name = aws_ecr_repository.lambda_duckdb.name
  image_tag       = "latest"

  depends_on = [terraform_data.docker_build]
}
