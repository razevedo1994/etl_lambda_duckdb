locals {
  bucket_names = toset(["raw", "silver", "gold"])
}


resource "aws_s3_bucket" "lakehouse_zones" {
    for_each = local.bucket_names

    bucket = "${each.key}-${data.aws_caller_identity.current.account_id}"

    tags = {
        Name = "poc-lambda-duckdb"
    }
}

resource "aws_s3_bucket_ownership_controls" "this" {
    for_each = aws_s3_bucket.lakehouse_zones

    bucket = each.value.id

    rule {
        object_ownership = "BucketOwnerPreferred"
    }
}

resource "aws_s3_bucket_acl" "example" {
  for_each = aws_s3_bucket.lakehouse_zones

  depends_on = [aws_s3_bucket_ownership_controls.this]

  bucket = each.value.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
    for_each = aws_s3_bucket.lakehouse_zones

    bucket = each.value.id

    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
}

resource "aws_s3_bucket_notification" "aws-lambda-raw-trigger" {
  bucket = aws_s3_bucket.lakehouse_zones["raw"].id

  lambda_function {
    lambda_function_arn = aws_lambda_function.this.arn
    events              = ["s3:ObjectCreated:*"]

  }
}
resource "aws_lambda_permission" "this" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${aws_s3_bucket.lakehouse_zones["raw"].id}"
}