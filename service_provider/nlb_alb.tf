resource "aws_iam_role" "populate_NLB_TG_with_ALB" {
  name = "populate_NLB_TG_with_ALB"

  assume_role_policy = <<EOF
{
  "Version":"2012-10-17",
  "Statement":[
    {
      "Action":"sts:AssumeRole",
      "Principal":{
        "Service": ["lambda.amazonaws.com", "events.amazonaws.com"]
      },
      "Effect":"Allow",
      "Sid":""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "populate_NLB_TG_with_ALB" {
  name        = "populate_NLB_TG_with_ALB"
  path        = "/"
  description = "populate_NLB_TG_with_ALB"

  policy = <<EOF
{
	"Version":"2012-10-17",
	"Statement":[
	{
		"Action":[
		"logs:CreateLogGroup",
		"logs:CreateLogStream",
		"logs:PutLogEvents"
		],
		"Resource":[
		"arn:aws:logs:*:*:*"
		],
		"Effect":"Allow",
		"Sid":"LambdaLogging"
	},
	{
		"Action":[
		"s3:Get*",
		"s3:PutObject",
		"s3:CreateBucket",
		"s3:ListBucket",
		"s3:ListAllMyBuckets"
		],
		"Resource":"*",
		"Effect":"Allow",
		"Sid":"S3"
	},
	{
		"Action":[
		"elasticloadbalancing:Describe*",
		"elasticloadbalancing:RegisterTargets",
		"elasticloadbalancing:DeregisterTargets"
		],
		"Resource":"*",
		"Effect":"Allow",
		"Sid":"ELB"
	},
	{
		"Action":[
		"cloudwatch:putMetricData"
		],
		"Resource":"*",
		"Effect":"Allow",
		"Sid":"CW"
	}
	]
}
EOF
}

resource "aws_iam_role_policy_attachment" "populate_NLB_TG_with_ALB" {
  role       = "${aws_iam_role.populate_NLB_TG_with_ALB.name}"
  policy_arn = "${aws_iam_policy.populate_NLB_TG_with_ALB.arn}"
}

resource "random_string" "bucket_name" {
  length  = 12
  special = false
  upper   = false
}

resource "aws_s3_bucket" "populate_nln_tg_with_alb" {
  bucket        = "hibritest${random_string.bucket_name.result}"
  acl           = "private"
  force_destroy = true

  tags {
    Name        = "bucket to populate nlb tg with alb "
    Environment = "Dev"
  }
}

resource "aws_lambda_function" "populate_NLB_TG_with_ALB" {
  filename         = "${path.module}/files/populate_NLB_TG_with_ALB.zip"
  function_name    = "populate_NLB_TG_with_ALB"
  role             = "${aws_iam_role.populate_NLB_TG_with_ALB.arn}"
  handler          = "populate_NLB_TG_with_ALB.lambda_handler"
  source_code_hash = "${base64sha256(file("${path.module}/files/populate_NLB_TG_with_ALB.zip"))}"
  runtime          = "python2.7"
  timeout          = 300

  environment {
    variables = {
      ALB_DNS_NAME                      = "${module.fargate_alb.dns_name}"
      ALB_LISTENER                      = "${aws_lb_listener.alb.port}"
      CW_METRIC_FLAG_IP_COUNT           = "true"
      INVOCATIONS_BEFORE_DEREGISTRATION = 3
      MAX_LOOKUP_PER_INVOCATION         = 50
      NLB_TG_ARN                        = "${aws_lb_target_group.service_frontend.arn}"
      S3_BUCKET                         = "${aws_s3_bucket.populate_nln_tg_with_alb.id}"
    }
  }
}

resource "aws_cloudwatch_event_rule" "populate_NLB_TG_with_ALB" {
  name        = "populate_NLB_TG_with_ALB"
  description = "populate_NLB_TG_with_ALB"

  schedule_expression = "rate(1 minute)"
  role_arn            = "${aws_iam_role.populate_NLB_TG_with_ALB.arn}"
}

resource "aws_lambda_alias" "test_alias" {
  name             = "testalias"
  description      = "a sample description"
  function_name    = "${aws_lambda_function.populate_NLB_TG_with_ALB.function_name}"
  function_version = "$LATEST"
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.populate_NLB_TG_with_ALB.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.populate_NLB_TG_with_ALB.arn}"
}

resource "aws_cloudwatch_event_target" "populate_NLB_TG_with_ALB" {
  rule      = "${aws_cloudwatch_event_rule.populate_NLB_TG_with_ALB.name}"
  target_id = "populate_NLB_TG_with_ALB"
  arn       = "${aws_lambda_function.populate_NLB_TG_with_ALB.arn}"
}
