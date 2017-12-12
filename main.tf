# Configure the Alicloud Provider
provider "alicloud" {}

resource "alicloud_vpc" "default" {
  name        = "magento-vpc"
  cidr_block  = "10.0.0.0/16"
}

resource "alicloud_security_group" "web" {
  name   = "web-sg"
  vpc_id = "${alicloud_vpc.default.id}"
}

resource "alicloud_security_group_rule" "allow_http_access" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "80/80"
  priority          = 1
  security_group_id = "${alicloud_security_group.web.id}"
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_ssh_access" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "22/22"
  priority          = 1
  security_group_id = "${alicloud_security_group.web.id}"
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_vswitch" "web" {
  vpc_id            = "${alicloud_vpc.default.id}"
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-southeast-1a"
}

resource "alicloud_vswitch" "db" {
  vpc_id            = "${alicloud_vpc.default.id}"
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-southeast-1a"
}

resource "alicloud_slb" "web" {
  name                 = "web-slb"
  internet             = true
  internet_charge_type = "paybytraffic"

  listener = [
    {
      "instance_port" = "80"
      "lb_port"       = "80"
      "lb_protocol"   = "http"
      "bandwidth"     = "5"
    }
  ]
}

resource "alicloud_ess_scaling_group" "web" {
  scaling_group_name = "web-group-magento"
  min_size           = 2
  max_size           = 4

  removal_policies   = ["OldestInstance", "NewestInstance"]
  vswitch_id         = "${alicloud_vswitch.web.id}"
  loadbalancer_ids   = ["${alicloud_slb.web.id}"]
  db_instance_ids    = ["${alicloud_db_instance.default.id}"]
}

resource "alicloud_ess_scaling_configuration" "web_config" {
  scaling_configuration_name = "scaling-configuration-web"
  scaling_group_id           = "${alicloud_ess_scaling_group.web.id}"

  image_id                   = "ubuntu_16_0402_64_20G_alibase_20170818.vhd"
  instance_type              = "ecs.n4.large"
  security_group_id          = "${alicloud_security_group.web.id}"
  active                     = true
  enable                     = true
  force_delete               = true
  system_disk_category       = "cloud_efficiency"
  user_data                = "${data.template_file.user_data.rendered}"

  substitute                 = "${alicloud_ess_scaling_configuration.web_config_sleep.id}"
}

resource "alicloud_ess_scaling_configuration" "web_config_sleep" {
  scaling_configuration_name = "scaling-configuration-web-sleep"
  scaling_group_id           = "${alicloud_ess_scaling_group.web.id}"

  image_id                   = "ubuntu_16_0402_64_20G_alibase_20170818.vhd"
  instance_type              = "ecs.n4.large"
  security_group_id          = "${alicloud_security_group.web.id}"
  active                     = false
  enable                     = false
  force_delete               = true
  system_disk_category       = "cloud_efficiency"
  user_data                = "${data.template_file.user_data.rendered}"
}

resource "alicloud_db_instance" "default" {
    engine                = "MySQL"
    engine_version        = "5.6"
    db_instance_class     = "rds.mysql.t1.small"
    db_instance_storage   = "10"

    master_user_name      = "admin_sql"
    master_user_password  = "p@ssword"

    db_instance_net_type  = "Intranet"
    instance_network_type = "VPC"

    vswitch_id            = "${alicloud_vswitch.db.id}"
    security_ips          = ["10.0.1.0/24"]

    db_mappings = [
      {
        db_name = "magento_db"
        character_set_name = "utf8"
      }
    ]
}

data "template_file" "user_data" {
  template = "${file("user_data.sh")}"

  vars {
    DB_HOST_IP = "${alicloud_db_instance.default.connections.0.ip_address}"
    DB_NAME = "magento_db"
    DB_USER = "admin_sql"
    DB_PASSWORD = "p@ssword"
    DOMAIN_URL = "www.myecommerce.com"
    MAGENTO_AUTH_PUBLIC_KEY = "$${var.magento_auth_public_key}"
    MAGENTO_AUTH_PRIVATE_KEY = "$${var.magento_auth_private_key}"
    MAGENTO_ADMIN_USER = "admin"
    MAGENTO_ADMIN_PASSWORD = "admin123"
    MAGENTO_ADMIN_EMAIL = "admin@myecommerce.com"
    MAGENTO_ADMIN_FIRSTNAME = "John" 
    MAGENTO_ADMIN_LASTNAME = "Doe"
  }
}

output "slb_web_public_ip" {
  value = "${alicloud_slb.web.address}"
}

output "db_connections" {
  value = "${alicloud_db_instance.default.connections}"
}

