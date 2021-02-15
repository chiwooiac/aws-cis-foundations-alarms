resource "aws_sns_topic" "alarms" {
  name = "dx-an2-cloudtrail-alarm-topic"

  /*
  delivery_policy = <<EOF
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numRetries": 3,
      "numMaxDelayRetries": 0,
      "numNoDelayRetries": 0,
      "numMinDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false,
    "defaultThrottlePolicy": {
      "maxReceivesPerSecond": 1
    }
  }
}
EOF
  */

}

resource "random_pet" "this" {
  length = 2
}

resource "aws_cloudwatch_log_group" "this" {
  name = "${local.category_name}-cloudtrail-logs-${random_pet.this.id}"
}

module "cis_alarms" {

  source  = "terraform-aws-modules/cloudwatch/aws//modules/cis-alarms"
  version = "~> 1.3"

  # Variables for AWS CIS
  create = true
  use_random_name_prefix = false
  disabled_controls = []
  namespace = "CISBenchmark"
  log_group_name = aws_cloudwatch_log_group.this.id
  alarm_actions  = [
    aws_sns_topic.alarms.arn
  ]
  actions_enabled = true
  tags = local.extra_tags

  depends_on = [ aws_sns_topic.alarms ]
}
