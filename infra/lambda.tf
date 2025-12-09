resource "aws_lambda_function" "this" {
  function_name = var.lambda_name
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.lambda_duckdb.repository_url}:latest"
  role          = aws_iam_role.role.arn

  depends_on = [
    aws_iam_role_policy_attachment.attach,
    terraform_data.docker_build
  ]
}