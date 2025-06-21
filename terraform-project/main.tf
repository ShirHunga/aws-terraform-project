provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "MainVPC"
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_a_cidr
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"
  tags = {
    Name = "PublicSubnet1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_b_cidr
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}b"
  tags = {
    Name = "PublicSubnet2"
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.private_subnet_a_cidr
  availability_zone = "${var.aws_region}c"
  tags = {
    Name = "PrivateSubnet1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.private_subnet_b_cidr
  availability_zone = "${var.aws_region}d"
  tags = {
    Name = "PrivateSubnet2"
  }
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "MainIGW"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "PublicRouteTable"
  }
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

# Creating public NACL
resource "aws_network_acl" "public_nacl" {
  vpc_id     = aws_vpc.main_vpc.id
  subnet_ids = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id
  ]

  tags = {
    Name = "PublicNACL"
  }
}

# Inbound Rules for Public NACL

resource "aws_network_acl_rule" "public_inbound_https" {
  network_acl_id = aws_network_acl.public_nacl.id
  rule_number    = 100
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
  egress         = false
}

resource "aws_network_acl_rule" "public_inbound_ephemeral" {
  network_acl_id = aws_network_acl.public_nacl.id
  rule_number    = 120
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
  egress         = false
}


# Outbound Rules for public NACL

resource "aws_network_acl_rule" "public_outbound_https" {
  network_acl_id = aws_network_acl.public_nacl.id
  rule_number    = 200
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
  egress         = true
}

resource "aws_network_acl_rule" "public_outbound_ephemeral" {
  network_acl_id = aws_network_acl.public_nacl.id
  rule_number    = 210
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
  egress         = true
}

resource "aws_network_acl_rule" "public_outbound_dns_udp" {
  network_acl_id = aws_network_acl.public_nacl.id
  rule_number    = 220
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 53
  to_port        = 53
  egress         = true
}

resource "aws_network_acl_rule" "public_outbound_dns_tcp" {
  network_acl_id = aws_network_acl.public_nacl.id
  rule_number    = 221
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 53
  to_port        = 53
  egress         = true
}

resource "aws_network_acl_rule" "public1_outbound_db" {
  network_acl_id = aws_network_acl.public_nacl.id
  rule_number    = 230
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = aws_subnet.private_subnet_1.cidr_block
  from_port      = 5432
  to_port        = 5432
  egress         = true
}

resource "aws_network_acl_rule" "public2_outbound_db" {
  network_acl_id = aws_network_acl.public_nacl.id
  rule_number    = 231
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = aws_subnet.private_subnet_2.cidr_block
  from_port      = 5432
  to_port        = 5432
  egress         = true
}


# Creating NACl for the private subnet
resource "aws_network_acl" "private_nacl" {
  vpc_id = aws_vpc.main_vpc.id
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  tags = {
    Name = "PrivateNACL"
  }
}

# Inbound rules for private NACL
resource "aws_network_acl_rule" "private_inbound_db_from_public_1" {
  network_acl_id = aws_network_acl.private_nacl.id
  rule_number    = 100
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = aws_subnet.public_subnet_1.cidr_block  
  from_port      = 5432
  to_port        = 5432
  egress         = false
}

resource "aws_network_acl_rule" "private_inbound_db_from_public_2" {
  network_acl_id = aws_network_acl.private_nacl.id
  rule_number    = 101
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = aws_subnet.public_subnet_2.cidr_block  
  from_port      = 5432
  to_port        = 5432
  egress         = false
}

# Outbound rules for private NACL
resource "aws_network_acl_rule" "private_outbound" {
  network_acl_id = aws_network_acl.private_nacl.id
  rule_number    = 200
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
  egress         = true
}

resource "aws_network_acl_rule" "private_outbound_dns_udp" {
  network_acl_id = aws_network_acl.private_nacl.id
  rule_number    = 201
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 53
  to_port        = 53
  egress         = true
}

resource "aws_network_acl_rule" "private_outbound_dns_tcp" {
  network_acl_id = aws_network_acl.private_nacl.id
  rule_number    = 202
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 53
  to_port        = 53
  egress         = true
}



# Creating subnet group for RDS
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]

  tags = {
    Name = "DBSubnetGroup"
  }
}

# Creating RDS SG
resource "aws_security_group" "rds_sg" {
  name        = "rds-postgres-sg"
  description = "Allow PostgreSQL from public subnet"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name = "RDS PostgreSQL SG"
  }
}

# Creating RDS
resource "aws_db_instance" "postgres" {
  identifier             = var.rds_endpoint
  engine                 = "postgres"
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = false
  skip_final_snapshot    = true
  deletion_protection    = false

  tags = {
    Name = "MyAppPostgres"
  }
}

# Creating EKS
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.37.1"

  cluster_name    = var.cluster_name
  cluster_version = "1.32"

  # Networking
  vpc_id                   = aws_vpc.main_vpc.id
  subnet_ids               = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id
  ]
  control_plane_subnet_ids = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id
  ]

  # Access & Authentication
  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  # Core Add-ons
  cluster_addons = {
    coredns                = {}
    kube-proxy             = {}
    vpc-cni                = {}
    eks-pod-identity-agent = {}
  }

  # Default settings for node groups
  eks_managed_node_group_defaults = {
    instance_types = ["t3.medium"]
  }

  eks_managed_node_groups = {
    default = {
      ami_type       = "AL2023_x86_64_STANDARD"
      desired_size   = 1
      min_size       = 1
      max_size       = 2

      subnet_ids = [
        aws_subnet.public_subnet_1.id,
        aws_subnet.public_subnet_2.id
      ]
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

# Set up kubenetes provider to deploy pods
data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# Initialize postgres RDS table
resource "kubernetes_config_map" "init_sql" {
  metadata {
    name = "init-sql"
  }

  data = {
    "init.sql" = file("${path.module}/init.sql")
  }
}

resource "kubernetes_job" "init_db" {
  metadata {
    name = "init-db"
  }

  spec {
    template {
      metadata {
        labels = {
          app = "init-db"
        }
      }

      spec {
        restart_policy = "Never"

        container {
          name  = "psql-client"
          image = "postgres:15"

          command = ["psql"]
          args = [
            "-h", trimspace(split(":", aws_db_instance.postgres.endpoint)[0]),
            "-p", "5432",
            "-U", var.db_username,
            "-d", var.db_name,
            "-f", "/sql/init.sql"
          ]

          env {
            name  = "PGPASSWORD"
            value = var.db_password
          }

          volume_mount {
            name       = "sql-volume"
            mount_path = "/sql"
          }
        }

        volume {
          name = "sql-volume"

          config_map {
            name = kubernetes_config_map.init_sql.metadata[0].name
          }
        }
      }
    }

    backoff_limit = 2
  }
}