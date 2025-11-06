locals {
  bucket_names = toset(["raw", "silver", "gold"])
}


resource "aws_s3_bucket" "lakehouse_zones" {
    for_each = local.bucket_names

    bucket = each.key

    tags = {
        Name = "Bucket ${each.key}"
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