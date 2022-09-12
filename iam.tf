data "aws_iam_policy_document" "logs" {

  statement {
    actions = [
      "logs:*"
    ]

    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "list_bucket" {

  statement {
    actions = [
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.bucket.bucket,
      "aws_s3_bucket.bucket.bucket/*"
    ]
  }
}

data "aws_iam_policy_document" "cloudwatch" {

  statement {
    actions = [
      "cloudwatch:PutMetrics"
    ]

    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "put_s3" {

  statement {
    actions = [
      "s3:PutObject"
    ]

    resources = [
      aws_s3_bucket.bucket.bucket,
      "aws_s3_bucket.bucket.bucket/*"
    ]
  }
}

data "aws_iam_policy_document" "combined" {
  source_policy_documents = [
    data.aws_iam_policy_document.logs.json,
    data.aws_iam_policy_document.list_bucket.json,
    data.aws_iam_policy_document.cloudwatch.json,
    data.aws_iam_policy_document.put_s3.json
  ]
}

resource "aws_iam_instance_profile" "profile" {
  name = "miner_profile"
  role = aws_iam_role.role.name
}

resource "aws_iam_role" "role" {
  name = "miner-role"
  path = "/"

  assume_role_policy = data.aws_iam_policy_document.combined.json
}
