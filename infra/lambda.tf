data "aws_ecr_repository" "duckdb_image" {
  name = "lambda_duckdb"
}

resource "aws_lambda_function" "this" {
  # filename      = "./lambda_code/lambda_function_payload.zip"
  # handler       = "main.lambda_handler"
  function_name = var.lambda_name
  package_type = "Image"
  image_uri     = "${data.aws_ecr_repository.duckdb_image.repository_url}/lambda:latest"
  role          = aws_iam_role.role.arn

  # source_code_hash = filebase64sha256("./lambda_code/lambda_function_payload.zip")

  # runtime = "python3.12"

  depends_on = [ 
    aws_iam_role_policy_attachment.attach
   ]
}