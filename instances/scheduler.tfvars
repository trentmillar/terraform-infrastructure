remote_state_bucket = "scheduler-terraform-states"
remote_state_key    = "us-west-2/development/terraform.tfstate"

max_instance_size   = "5"
min_instance_size   = "2"
ec2_instance_type   = "t2.micro"

autoscaling_sns_sms_endpoint = "+15555551234"