data "archive_file" "lambda" {
  type          = "zip"
  source_file   = "./app/main.py"
  output_path   = "./lambda_code/lambda_function_payload.zip"
}

resource "aws_lambda_function" "this" {
  filename      = "./lambda_code/lambda_function_payload.zip"
  function_name = var.lambda_name
  handler       = "main.lambda_handler"
  role          = aws_iam_role.role.arn

  source_code_hash = filebase64sha256("./lambda_code/lambda_function_payload.zip")

  runtime = "python3.12"

  depends_on = [ 
    aws_iam_role_policy_attachment.attach
   ]
}