resource "aws_sns_topic" "alarms" {
  name = "${local.category_name}-cloudtrail-alarm-topic"

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

/*
resource "aws_sns_topic_subscription" "alarm_notification_sns_target" {
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email" # 구독 승인 처리를 하지 못하므로 SMTP 프로토콜은 지원되지 않는다.
  endpoint  = "master.opsnow@bespinglobal.com"
}
*/

resource "random_pet" "this" {
  length = 2
}

resource "aws_cloudwatch_log_group" "this" {
  name = "${local.category_name}-cloudtrail-logs-${random_pet.this.id}"
}

module "cis_cloudwatch" {

  source  = "terraform-aws-modules/cloudwatch/aws//modules/cis-alarms"
  version = "~> 1.3"

  # Variables for CloudWatch alarms for CIS
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


# https://github.com/trussworks/terraform-aws-logs
module "config_logs" {
  source  = "trussworks/logs/aws"
  version = "~> 10"

  s3_bucket_name     = "${local.category_name}-config-logs-${random_pet.this.id}"
  allow_config       = true
  config_logs_prefix = "config"
  force_destroy      = true
}


module "cis_config" {
  source = "trussworks/config/aws"

  # Variables for AWS Config rules for CIS
  aggregate_organization = false
  check_approved_amis_by_tag = true # APPROVED_AMIS_BY_TAG
  ami_required_tag_key_value = "Team:${var.team_alias},CostCenter:${var.cost_center}"
  acm_days_to_expiration = 14
  check_acm_certificate_expiration_check = true # ACM_CERTIFICATE_EXPIRATION_CHECK
  check_cloud_trail_encryption = false # CLOUD_TRAIL_ENCRYPTION_ENABLED
  check_cloud_trail_log_file_validation = false # CLOUD_TRAIL_LOG_FILE_VALIDATION_ENABLED
  check_cloudtrail_enabled = true # CLOUD_TRAIL_ENABLED
  check_cloudwatch_log_group_encrypted = true # CLOUDWATCH_LOG_GROUP_ENCRYPTED
  check_ebs_snapshot_public_restorable = true # EBS_SNAPSHOT_PUBLIC_RESTORABLE_CHECK
  check_ec2_encrypted_volumes = false # ENCRYPTED_VOLUMES
  check_ec2_volume_inuse_check = true # EC2_VOLUME_INUSE_CHECK
  check_eip_attached = true # EIP_ATTACHED
  check_guard_duty = false # GUARDDUTY_ENABLED_CENTRALIZED
  check_iam_group_has_users_check = true # IAM_GROUP_HAS_USERS_CHECK
  check_iam_password_policy = true # IAM_PASSWORD_POLICY
  password_require_uppercase = true
  password_require_lowercase = true
  password_require_symbols = true
  password_require_numbers = true
  password_min_length = 10
  password_max_age = 90
  password_reuse_prevention = 1
  check_iam_root_access_key = true # IAM_ROOT_ACCESS_KEY_CHECK
  check_iam_user_no_policies_check = true # IAM_USER_NO_POLICIES_CHECK
  check_instances_in_vpc = true # INSTANCES_IN_VPC
  check_mfa_enabled_for_iam_console_access = true # MFA_ENABLED_FOR_IAM_CONSOLE_ACCESS
  check_multi_region_cloud_trail= true # MULTI_REGION_CLOUD_TRAIL_ENABLED
  check_rds_public_access = true # RDS_INSTANCE_PUBLIC_ACCESS_CHECK
  check_rds_snapshots_public_prohibited  = true # RDS_SNAPSHOTS_PUBLIC_PROHIBITED
  check_rds_storage_encrypted  = false # RDS_STORAGE_ENCRYPTED
  check_required_tags = true # REQUIRED_TAGS
  # required-tags (https://docs.amazonaws.cn/en_us/config/latest/developerguide/required-tags.html)
  required_tags_resource_types = [
    "ACM::Certificate",
    "AutoScaling::AutoScalingGroup",
    "CloudFormation::Stack",
    "CodeBuild::Project",
    "DynamoDB::Table",
    "EC2::CustomerGateway",
    "EC2::Instance",
    "EC2::InternetGateway",
    "EC2::NetworkAcl",
    "EC2::NetworkInterface",
    "EC2::RouteTable",
    "EC2::SecurityGroup",
    "EC2::Subnet",
    "EC2::Volume",
    "EC2::VPC",
    "EC2::VPNConnection",
    "EC2::VPNGateway",
    "ElasticLoadBalancing::LoadBalancer",
    "ElasticLoadBalancingV2::LoadBalancer",
    "RDS::DBInstance",
    "RDS::DBSecurityGroup",
    "RDS::DBSnapshot",
    "RDS::DBSubnetGroup",
    "RDS::EventSubscription",
    "Redshift::Cluster",
    "Redshift::ClusterParameterGroup",
    "Redshift::ClusterSecurityGroup",
    "Redshift::ClusterSnapshot",
    "Redshift::ClusterSubnetGroup",
    "S3::Bucket"
  ]

  # depends-on required_tags_resource_types
  required_tags = {
    tag1Key   = "Team"
    tag1Value = var.team_alias
    tag2Key   = "CostCenter"
    tag2Value = var.cost_center
  }

  check_restricted_ssh = false # INCOMING_SSH_DISABLED
  check_root_account_mfa_enabled = true # ROOT_ACCOUNT_MFA_ENABLED
  check_s3_bucket_public_write_prohibited = true # S3_BUCKET_PUBLIC_WRITE_PROHIBITED
  check_s3_bucket_ssl_requests_only = true # S3_BUCKET_SSL_REQUESTS_ONLY
  check_vpc_default_security_group_closed = true # VPC_DEFAULT_SECURITY_GROUP_CLOSED

  config_aggregator_name = "organization"
  config_delivery_frequency = "Twelve_Hours" # One_Hour | Three_Hours | Six_Hours | Twelve_Hours | TwentyFour_Hours

  config_name        = "${local.category_name}-aws-config"
  enable_config_recorder = true
  include_global_resource_types = true
  config_logs_bucket = module.config_logs.aws_logs_bucket
  config_logs_prefix = "config"
  config_max_execution_frequency = "TwentyFour_Hours" # One_Hour | Three_Hours | Six_Hours | Twelve_Hours | TwentyFour_Hours
  config_sns_topic_arn = aws_sns_topic.alarms.arn

  tags = {
    "Automation" = "Terraform"
    "Name"       =  "${local.category_name}-aws-config"
  }

}


resource aws_config_config_rule iam_user_unused_credentials_check {

  name        = "iam-user-unused-credentials-check"
  description = "Checks whether your AWS IAM users have credentials that have not been used within the specified number of days you provided"

  source {
    owner             = "AWS"
    source_identifier = "IAM_USER_UNUSED_CREDENTIALS_CHECK"
  }

  input_parameters = jsonencode({
    maxCredentialUsageAge = tostring(var.max_credential_usage_age)
  })

  depends_on = [module.cis_config.aws_config_role_arn]

}


resource aws_config_config_rule access_keys_rotated_check {

  name        = "access-keys-rotated-check"
  description = "Checks whether the active access keys are rotated within the number of days specified in maxAccessKeyAge. The rule is NON_COMPLIANT if the access keys have not been rotated for more than maxAccessKeyAge number of days."

  source {
    owner             = "AWS"
    source_identifier = "ACCESS_KEYS_ROTATED"
  }

  input_parameters = jsonencode({
    maxAccessKeyAge = tostring(var.max_access_key_age)
  })

  depends_on = [module.cis_config.aws_config_role_arn]

}
