################################### DATA ###############################################

data "aws_availability_zones" "available" {}


data "aws_iam_role" "master" {
  name = "eksClusterRole"
}

data "aws_iam_role" "worker" {
  name = "eks-node-role"
}


################################### RESOURCES ###############################################

# NETWORKING #
resource "aws_vpc" "vpc" {
  cidr_block           = var.network_address_space
  enable_dns_hostnames = "true"

}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

}

resource "aws_subnet" "subnet" {
  count                   = var.subnet_count
  cidr_block              = cidrsubnet(var.network_address_space, 8, count.index)
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags_all = {
    "kubernetes.io/role/elb"          = "1"
    "kubernetes.io/role/internal-elb" = "1"
  }
}


# ROUTING #
resource "aws_route_table" "rtb" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta-subnet" {
  count          = var.subnet_count
  subnet_id      = aws_subnet.subnet[count.index].id
  route_table_id = aws_route_table.rtb.id
}
# SECURITY GROUPS #

resource "aws_security_group" "aws-sg" {
  name   = "mysecuritygroup"
  vpc_id = aws_vpc.vpc.id

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.network_address_space]
  }

  # outbound internet access
}

resource "aws_eks_cluster" "eks" {
  name     = var.eks_name
  role_arn = data.aws_iam_role.master.arn

  vpc_config {
    subnet_ids = [aws_subnet.subnet[0].id, aws_subnet.subnet[1].id]
  }
  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }
  enabled_cluster_log_types = ["api", "audit", "controllerManager", "scheduler", "authenticator"]
  bootstrap_self_managed_addons = true

}


resource "aws_eks_node_group" "backend" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "dev"
  node_role_arn   = data.aws_iam_role.worker.arn
  subnet_ids      = [aws_subnet.subnet[0].id, aws_subnet.subnet[1].id]
  capacity_type   = "ON_DEMAND"
  disk_size       = "20"
  instance_types  = ["t2.large"]
  remote_access {
    ec2_ssh_key               = "Neeharika_Terraform"
    source_security_group_ids = [aws_security_group.aws-sg.id]
  }

  labels = tomap({ env = "dev" })

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

}
