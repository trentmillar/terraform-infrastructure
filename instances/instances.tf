provider "aws" {
    region = "${var.region}"
}

terraform {
    backend "s3" { }
}

data "terraform_remote_state" "network_configuration" {
  backend = "s3"
  config {
      bucket = "${var.remote_state_bucket}"
      key = "${var.remote_state_key}"
      region = "${var.region}"
  }  
}

resource "aws_security_group" "ec2_public_security_group" {
    name = "EC2-Public-SG"
    description = "Exposed access for EC2 Containers"
    vpc_id = "${data.terraform_remote_state.network_configuration.vpc_id}"

    ingress {
        from_port = 80
        protocol = "TCP"
        to_port = 80
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 22
        protocol = "TCP"
        to_port = 22
        cidr_blocks = [""]
    }

    egress {
        from_port = 0
        protocol = "-1"
        to_port = 0
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "ec2_private_security_group" {
  name = "EC2-Private-SG"
  description = "Only allow public SG resources"
  vpc_id = "${data.terraform_remote_state.network_configuration.vpc_id}"

  ingress {
      from_port = 0
      protocol = "-1"
      to_port = 0
      cidr_blocks = ["${aws_security_group.ec2_public_security_group.id}"]
  }

  ingress {
      from_port = 80
      protocol = "TCP"
      to_port = 80
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow health check for EC2 instances in SG"
  }

  egress {
      from_port = 0
      protocol = "-1"
      to_port = 0
      cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "elb_security_group" {
  name = "ELB-SG"
  description = "ELB Security Group"
  vpc_id = "${data.terraform_remote_state.network_configuration.vpc_id}"

  ingress {
      from_port = 0
      protocol = "-1"
      to_port = 0
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow web traffic to LB"
  }

  egress {
      from_port = 0
      protocol = "-1"
      to_port = 0
      cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "ec2_iam_role" {
  name = "EC2-IAM-ROLE"
  assume_role_policy = <<EOF
{
    Version: "2012-10-17",
    Statement: [
        {
            Effect: "Allow",
            Principal: {
                Services: [
                    "ec2.amazonaws.com",
                    "application-autoscaling.amazonaws.com"
                ]
            },
            Action: "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "ec2_iam_role_policy" {
  name = "EC2-IAM-Policy"
  role = "${aws_iam_role.ec2_iam_role.id}"
  policy = <<EOF
{
    Version: "2012-10-17",
    Statement: [
        {
            Effect: "Allow",
            Action: [
                "ec2:*",
                "elasticloadbalancing:*",
                "cloudwatch:*",
                "logs:*"
            ],
            Resource: "*"
        }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
    name = "EC2-IAM-Instance-Profile"
    role = "${aws_iam_role.ec2_iam_role.name}"
}

data "aws_ami" "launch_configuration_ami" {
    most_recent = true

    filter {
        name = "owner-alias"
        values = ["amazon"]
    }
}

resource "aws_launch_configuration" "ec2_private_launch_configuation" {
  image_id                    = "${data.aws_ami.launch_configuration_ami.id}"
  instance_type               = "${var.ec2_instance_type}"
  key_name                    = "${var.keypair_name}"
  associate_public_ip_address = false
  iam_instance_profile        = "${aws_iam_instance_profile.ec2_instance_profile.name}"
  security_groups             = ["${aws_security_group.ec2_private_security_group.id}"]

  user_data = <<EOF
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install apache2
    export INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
    echo "<html><body><h1>Running $INSTANCE_ID</h1></body></html>" > /var/www/html/index.html
  EOF
}

resource "aws_launch_configuration" "ec2_public_launch_configuration" {
    image_id                    = "${data.aws_ami.launch_configuration_ami.id}"
    instance_type               = "${var.ec2_instance_type}"
    key_name                    = "${var.keypair_name}"
    associate_public_ip_address = true
    iam_instance_profile        = "${aws_iam_instance_profile.ec2_instance_profile.name}"
    security_groups             = ["${aws_security_group.ec2_public_security_group.id}"]

    user_data = <<EOF
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install apache2
    export INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
    echo "<html><body><h1>Running $INSTANCE_ID</h1></body></html>" > /var/www/html/index.html
  EOF
}

resource "aws_elb" "webapp_load_balancer" {
  name            = "Scheduler-Public-LoadBalancer"
  internal        = false
  security_groups = ["${aws_security_group.elb_security_group.id}"]
  subnets         = [
      "${data.terraform_remote_state.network_configuration.public_subnet_1_id}",
      "${data.terraform_remote_state.network_configuration.public_subnet_2_id}",
      "${data.terraform_remote_state.network_configuration.public_subnet_3_id}"
  ]

  listener {
      instance_port     = 80
      instance_protocol = "HTTP"
      lb_port           = 80
      lb_protocol       = "HTTP"
  }

  health_check {
      healthy_threshold   = 5
      interval            = 30
      target              = "HTTP:80/index.html"
      timeout             = 10
      unhealthy_threshold = 5
  }
}

// Begin - Backend/Private ELB w/ all private subnets & generic listener
resource "aws_elb" "backend_load_balancer" {
  name            = "Schedule-Private-LoadBalance"
  internal        = true
  security_groups = ["${aws_security_group.elb_security_group.id}"]
  subnets         = [
      "${data.terraform_remote_state.network_configuration.private_subnet_1_id}",
      "${data.terraform_remote_state.network_configuration.private_subnet_2_id}",
      "${data.terraform_remote_state.network_configuration.private_subnet_3_id}",
  ]

  listener {
      instance_port     = 80
      instance_protocol = "HTTP"
      lb_port           = 80
      lb_protocol       = "HTTP"
  }

    health_check {
      healthy_threshold   = 5
      interval            = 30
      target              = "HTTP:80/index.html"
      timeout             = 10
      unhealthy_threshold = 5
  }
}
// End - Backend/Private ELB w/ all private subnets & generic listener

// Begin - Autoscaling group for private EC2 instances
resource "aws_autoscaling_group" "ec2_private_autoscaling_group" {
    name                 = "Scheduler-Private-AutoScalingGroup"
    vpc_zone_identifier  = [
      "${data.terraform_remote_state.network_configuration.private_subnet_1_id}",
      "${data.terraform_remote_state.network_configuration.private_subnet_2_id}",
      "${data.terraform_remote_state.network_configuration.private_subnet_3_id}",
    ]
    max_size             = "${var.max_instance_size}"
    min_size             = "${var.min_instance_size}"
    launch_configuration = "${aws_launch_configuration.ec2_private_launch_configuation.name}"
    health_check_type    = "ELB"
    load_balancers       = ["${aws_elb.backend_load_balancer.name}"]

    tag {
        key                 ="Name"
        propagate_at_launch = false
        value               = "Backend-EC2-Instance"
    }

    tag {
        key                 = "Type"
        propagate_at_launch = false
        value               = "Scheduler"
    }
}
// End - Autoscaling group for private EC2 instances

// Begin - Autoscaling group for public EC2 instances
resource "aws_autoscaling_group" "ec2_public_autoscaling_group" {
    name                 = "Scheduler-Public-AutoScalingGroup"
    vpc_zone_identifier  = [
      "${data.terraform_remote_state.network_configuration.public_subnet_1_id}",
      "${data.terraform_remote_state.network_configuration.public_subnet_2_id}",
      "${data.terraform_remote_state.network_configuration.public_subnet_3_id}",
    ]
    max_size             = "${var.max_instance_size}"
    min_size             = "${var.min_instance_size}"
    launch_configuration = "${aws_launch_configuration.ec2_public_launch_configuration.name}"
    health_check_type    = "ELB"
    load_balancers       = ["${aws_elb.webapp_load_balancer.name}"]

    tag {
        key                 ="Name"
        propagate_at_launch = false
        value               = "Frontend-EC2-Instance"
    }

    tag {
        key                 = "Type"
        propagate_at_launch = false
        value               = "Scheduler"
    }
}
// End - Autoscaling group for public EC2 instances

// Begin - handle actual instance scaling - Public
resource "aws_autoscaling_policy" "public_scaling_policy" {
  autoscaling_group_name = "${aws_autoscaling_group.ec2_public_autoscaling_group.name}"
  name                   = "Scheduler-Frontend-AutoScaling-Policy"
  policy_type            = "TargetTrackingPolicy"
  min_adjustment_step    = 1

  target_tracking_configuration {
      predefined_metric_specification {
          predefined_metric_specification = "ASGAverageCPUUtilization"
      }
      target_value = 60
  }
}
// End - handle actual instance scaling - Public

// Begin - handle actual instance scaling - Private
resource "aws_autoscaling_policy" "public_scaling_policy" {
  autoscaling_group_name = "${aws_autoscaling_group.ec2_private_autoscaling_group.name}"
  name                   = "Scheduler-Backend-AutoScaling-Policy"
  policy_type            = "TargetTrackingPolicy"
  min_adjustment_step    = 1

  target_tracking_configuration {
      predefined_metric_specification {
          predefined_metric_specification = "ASGAverageCPUUtilization"
      }
      target_value = 60
  }
}
// End - handle actual instance scaling - Private

