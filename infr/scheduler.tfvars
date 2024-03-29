vpc_cidr                        = "192.168.0.0/16"
public_subnet_1_cidr            = "192.168.1.0/24"
public_subnet_2_cidr            = "192.168.2.0/24"
public_subnet_3_cidr            = "192.168.3.0/24"
private_subnet_1_cidr           = "192.168.4.0/24"
private_subnet_2_cidr           = "192.168.5.0/24"
private_subnet_3_cidr           = "192.168.6.0/24"
kubernetes_cluster_key          = "kubernetes.io/cluster/cluster1"
kubernetes_cluster_value        = "shared"
kubernetes_elb_internal_key     = "kubernetes.io/role/internal-elb"
kubernetes_elb_internal_value   = "1"
kubernetes_elb_key              = "kubernetes.io/role/elb"
kubernetes_elb_value            = "1"
aws_profile                     = "btg"