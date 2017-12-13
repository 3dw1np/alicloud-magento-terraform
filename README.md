# Deploy Magento 2 (eCommerce Platform) on Alibaba Cloud with Terraform

At Alibaba Cloud, we use Terraform to provide fast demos to our customers.
I truly believe that the infrasture-as-code is the quick way to leverage a public cloud provider services. Instead of clicking on the Web Console UI, the logic of the infrasture-as-code allows us to define more accuratly, manage each services, and automate the entire infrastructure with a versionning control (git).


## Get access keys from Magento Marketplace 
To obtain Magento 2 platform, we need some access keys. You need to go to [https://marketplace.magento.com/]() and create an account there. Next, follow Home > Customer Account > My Access Keys, and generate new access keys.

## Export environment variables
We provide the Alicloud credentials with envrionments variables. In this tutorial, we are going to use the Singapore Region (ap-southeast-1).
 
```
root@alicloud:~$ export ALICLOUD_ACCESS_KEY="anaccesskey"
root@alicloud:~$ export ALICLOUD_SECRET_KEY="asecretkey"
root@alicloud:~$ export ALICLOUD_REGION="ap-southeast-1"
```

If you don't have an access key for your Alicloud account yet, just follow this [tutorial](https://www.alibabacloud.com/help/doc-detail/28955.htm).

## Install Terraform
To install Terraform, download the appropriate package for your OS. The download contains an executable file that you can add in your global PATH.

Verify your PATH configuration by typing the terraform

```
root@alicloud:~$ terraform
Usage: terraform [--version] [--help] <command> [args]
```

## Setup Alicloud terraform provider (> v1.3.2)
The official repository for Alicloud terraform provider is [https://github.com/alibaba/terraform-provider]() 

* Download a compiled binary from https://github.com/alibaba/terraform-provider/releases.
* Create a custom plugin directory named **terraform.d/plugins/darwin_amd64**.
* Move the binary inside this custom plugin directory.
* Create **test.tf** file for the plan and provide inside:

```
# Configure the Alicloud Provider
provider "alicloud" {}
```

* Initialize the working directory but Terraform will not download the alicloud provider plugin from internet, because we provide a newest version locally.

```
terraform init
```


## Build Infrastructure
* Remove the file **test.tf**.
* Copy the file **main.tf** in the working directory.
* Create an excution plan to see changes to do to achieve the desired state.

```
terraform plan --var 'magento_auth_public_key=<public_key>' --var 'magento_auth_private_key=<private_key>'
```

* Finally apply the changes to reach the desired state.

```
terrform apply --var 'magento_auth_public_key=<public_key>' --var 'magento_auth_private_key=<private_key>'
```

* A local file named "terraform.tfstate" should appear and contains the state your deployed infrastructure.