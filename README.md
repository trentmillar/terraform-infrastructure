# Terraform (VPC + 3 private & public subnets w/ Ubuntu instances incl. AS, SNS, SMS...)

### Create Custom VPC (contains all public x3 and private x3 subnets)
## So what is it?

AWS VPC on 192.168.0.0/16
- Public Subnet 1 w/ auto scaling group 192.168.1.0/24
- Public Subnet 2 - 192.168.2.0/24
- Public Subnet 3 - 192.168.3.0/24
- Private Subnet 1 w/ Auto scaling group 192.168.4.0/24
- Private Subnet 2 w/ Auto scaling group 192.168.5.0/24
- Private Subnet 3 w/ Auto scaling group 192.168.6.0/24
- SNS -> SMS notifications
- Launch config using Ubuntu 18.04 LTS AMIs
- and more...

#### Public Subnets
Create auto scaling notification -> SNS scaling topic, which can push SMS notifications
Public elastic load balancer

#### Private Subnets
Has a NAT Gateway to the “private route table” to access the internal load balancer hence the private subnets

## Follow Steps
1. Create an AWS account
    - Go to IAM on the AWS console and add a new user named, scheduler-deployer
    - Change Access Type to "Programmatic access", this way the user is only used to run the terraform IaC.
    - Click "Next: Permissions" and click on the "Attach existing policies directly" then give this user the AdministratorAccess permission...this is not the best long-term idea but will cover all the user needs to create.
    - Click through the remaining steps until you successfully create the user.
    - Download the .csv to capture the user's Access & Secret key. DONT LOSE
      - user: scheduler-deployer
      - access key: (YOUR KEY)
      - secret key: (YOUR SECRET)

2. Install dependencies (MAC)
    - `brew install terraform` > 0.12.6
    - `brew install awscli`

3. AWS CLI - Configure new user
After the earlier step of creating a new user, you should have both the access & secret keys.
To configure AWS locally to use this new user you need to use the aws cli's configure command.

- `aws configure` (press return)
  - `$ AWS Access Key ID [None]:` (YOUR ACCESS KEY)
  - `$ AWS Secret Access Key ID [None]:` (YOUR SECRET KEY)
  - `$ Default region name [None]:` (NONE/ANY REGION)
  - `$ Default output format [None]:` (json/text/table)

4. (optional) Configure multiple AWS profiles
If you have running the configure command already and already have an AWS profile configured, this will walk through having multiple profiles.

`aws configure --profile <PROFILE NAME>` (press return & follow the same steps above)


#### Viewing your config & credentials after running `aws configure`

You should have two files; `~/.aws/config` (which stores the region and output you defined) and `~/.aws/credentials` (which stores the access & secret keys)

The entries in these two files will in it's own staza using the profile name if you ran the command using the ***--profile*** option or else ***[default]*** will be used.

#### How to work with multiple AWS profiles 
By default terraform, when using the provider "aws", will use the default profile when you configured the aws cli. I you need to use a different or named profile you will need to either set the AWS_PROFILE environment variable to equal the name of the profile or you will need to set the `profile` variable in Terraform's `provider`

To set the environment variable execute, `export AWS_PROFILE=<NAME OF PROFILE>`
		
#### AWS - Create EC2 Keypair

From AWS console got to EC2 then create a keypair...give it a name, scheduler.pem will do.

Download the .pem file and place it in the root of terraform-infrastructure project. This is used as your identity file after ssh-ing into your instances when they are up and running.

#### AWS - State bucket

From AWS console go to S3 and create the bucket `scheduler-terraform-states`. Make sure you are doing this all in the same region. By default this project uses `us-west-2`

#### Terraform - initialize new project (Infrastructure)

We use S3 as the state backing store as defined in the file `.config` under the `infr` folder.

To initialize the project, cd to the `infr` folder within the project and run

    terraform init -backend-config='.config'

The results should be:
````
$ terraform init -backend-config='.config'

Initializing the backend...

Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.

Initializing provider plugins...
- Checking for available provider plugins...
- Downloading plugin for provider "aws" (terraform-providers/aws) 2.23.0...

The following providers do not have any version constraints in configuration,
so the latest version was installed.

To prevent automatic upgrades to new major versions that may contain breaking
changes, it is recommended to add version = "..." constraints to the
corresponding provider blocks in configuration, with the constraint strings
suggested below.

* provider.aws: version = "~> 2.23"

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
````
#### Terraform plan

When you are ready to start updating state run the plan command as follows:

	terraform plan -var-file='scheduler.tfvars'

The result should be(truncated):
````
$ terraform plan -var-file='scheduler.tfvars'
Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.


------------------------------------------------------------------------

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_eip.elastic-ip-for-nat-gw will be created
  + resource "aws_eip" "elastic-ip-for-nat-gw" {
      + allocation_id             = (known after apply)
      + associate_with_private_ip = "192.168.0.5"
      + association_id            = (known after apply)
      + domain                    = (known after apply)
      + id                        = (known after apply)
      + instance                  = (known after apply)
      + network_interface         = (known after apply)
      + private_dns               = (known after apply)
      + private_ip                = (known after apply)
      + public_dns                = (known after apply)
      + public_ip                 = (known after apply)
      + public_ipv4_pool          = (known after apply)
      + tags                      = {
          + "Name" = "Testing-EIP"
        }
      + vpc                       = true
    }

  # aws_internet_gateway.testing-igw will be created
…
````
#### Terraform Apply

If we are fine to make these changes then we can run 'apply'

***Note,*** always check that the plan is not destroying or changing anything you hadn't planned to.

    terraform apply -var-file='scheduler.tfvars'

#### SSH to public instances
Download the ssh key from the AWS Console > VPC > Key Pairs, if you haven't already.
You must chmod the key so that the file is only accessible by you,

	chmod 600 ~/dev/repo/terraform-infrastucture/scheduler.pem
Then ssh to the instance using it's assigned IP,

	ssh -i ~/dev/repo/terraform-infrastucture/scheduler.pem ubuntu@1.2.3.4

### Final steps/comments

***Important*** You will need repeat the `terraform apply -var-file='scheduler.tfvars'` from the `instances` folder. This can be done after you have `apply`ed the `infr` changes. If this is not done, you will have your infrastructure but no running EC2 instances.

You can change the `.tfvars` to contain settings specific to your needs. You will definately want to change the SMS phone number.