data "archive_file" "lambda" {
  type          = "zip"
  source_file   = "./app/main.py"
  output_path   = "./lambda_code/lambda_function_payload.zip"
}

resource "aws_lambda_layer_version" "my_python_layer" {
  layer_name          = "my-python-dependencies"
  filename            = "./app/python.zip"
  compatible_runtimes = ["python3.10"]
  description         = "Layer with common Python libraries"
}

resource "aws_lambda_function" "this" {
  filename      = "./lambda_code/lambda_function_payload.zip"
  function_name = var.lambda_name
  handler       = "main.lambda_handler"
  role          = aws_iam_role.role.arn

  source_code_hash = filebase64sha256("./lambda_code/lambda_function_payload.zip")

  layers = [aws_lambda_layer_version.my_python_layer.arn]

  runtime = "python3.10"

  depends_on = [ 
    aws_iam_role_policy_attachment.attach
   ]
}