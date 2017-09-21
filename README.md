# AWS deployment

## Prerequisites

* Install Ansible
* Install Kops (https://github.com/kubernetes/kops) (see below)
* Install kubectl (see below)
* Create secure Amazon S3 bucket, which the Kops tool will use as the storage for cluster configurations. (see below) **The bucket will contain also the access details for the clusters configured with Kops. It should be secured accordingly.**

### Kubectl installation

Playbook `install-kubectl.yaml` can be used for installing the latest version of kubectl on Linux or MacOS. To install it run
```
ansible-playbook install-kubectl.yaml --user=username --ask-sudo-pass
```

### Kops installation

Playbook `install-kops.yaml` can be used for installing the latest version of Kops utility on Linux or MacOS. To install it run
```
ansible-playbook install-kops.yaml --user=username --ask-sudo-pass
```

### S3 bucket for state store

Playbook `create-state-store.yaml` can be used to create the S3 bucket to store the Kops state. To install it run
```
ansible-playbook create-state-store.yaml
```

## Install Kubernetes cluster

## Setup AWS IAM user 

In order to build clusters within AWS we'll create a dedicated IAM user for kops. This user requires API credentials in order to use kops. Create the user, and credentials, using the AWS console.

The kops user will require the following IAM permissions to function properly:
```
AmazonEC2FullAccess
AmazonRoute53FullAccess
AmazonS3FullAccess
IAMFullAccess
AmazonVPCFullAccess
```
You can create the kops IAM user from the command line using the following:
```
aws iam create-group --group-name kops

aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess --group-name kops
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonRoute53FullAccess --group-name kops
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess --group-name kops
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/IAMFullAccess --group-name kops
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonVPCFullAccess --group-name kops

aws iam create-user --user-name kops

aws iam add-user-to-group --user-name kops --group-name kops

aws iam create-access-key --user-name kops
```
You should record the SecretAccessKey and AccessKeyID in the returned JSON output, and then use them below:

### configure the aws client to use your new IAM user
```
aws configure           # Use your new access and secret key here
aws iam list-users      # you should see a list of all your IAM users here
```
### Because "aws configure" doesn't export these vars for kops to use, we export them now
```
export AWS_ACCESS_KEY_ID=<access key>
export AWS_SECRET_ACCESS_KEY=<secret key>
```

### Create Cluster State storage In S3

aws s3api create-bucket \
    --bucket prefix-example-com-state-store \
    --region us-east-1

### Prepare local environment

```
export NAME=myfirstcluster.example.com
export KOPS_STATE_STORE=s3://prefix-example-com-state-store
```

## Create cluster

First you have to create a variables file in  inventory/group_vars/_name_of_cluster.yaml_.  Use test.c.demo.com as a template.
Next add an entry into the inventory file under inventory/inventory.  Basically you just have to copy what was done for test.c.demo.com in that file.  Finally run the command below.
The Kubernetes cluster can be created by running
```
ansible-playbook create.yaml
```

To spin up the test.c.demo.com cluster you would do:
```
ansible-playbook create-registry.yaml -l demo.jiannc.com

```

The main configuration of the cluster is in the variables in `group_vars/all/vars.yaml`. Following table shows the different options.

| Option | Explanation | Example |
|--------|-------------|---------|
| `cluster_name` | Name of the cluster which should be created. The name has to end with the domain name of the DNS zone hosted in Route 53. | `kubernetes.my-cluster.com` |
| `state_store` | Name of the Amazon S3 bucket which should be used as a Kops state store. It should start with `s3://`. | `s3://kops-state-store` |
| `ssh_public_key` | Path to the public part of the SSH key, which should be used for the SSH access to the Kubernetes hosts | `~/.ssh/id_rsa.pub` |
| `aws_region` | AWS region where the cluster should be installed. | `eu-west-1` |
|  `version`   | What version of kubernetes do you want to be installed | `1.5.4` |
| `aws_zones` | List of availability zones in which the cluster should be installed. Must be an odd number (1, 3 or 5) of zones (at least 3 zones are needed for AWS setup accross availability zones). | `eu-west-1a,eu-west-1b,eu-west-1c` |
| `dns_zone` | Name of the Rote 53 hosted zone. Must be reflected in the cluster name. | `my-cluster.com` |
| `network_cidr` | A new VPC will be created. It will use the CIDR specified in this option. | `172.35.0.0/16` |
| `kubernetes_networking` | Defines which networking plugin should be used in Kubernetes. Tested with Calico only. | `calico` |
| `master_size` | EC2 size of the nodes used for the Kubernetes masters (and Etcd hosts) | `t2.small` |
| `node_size` | EC2 size of the nodes used as workers. | `t2.small` |
| `node_count` | Nomber of EC2 worker hosts. | `6` |

## Updating Kubernetes cluster

The Kubernetes cluster setup is done using the Kops tool only. All updates to it can be done using Kops. The Ansible playbooks from this project only simplify the initial setup.

## Delete Kubernetes cluster

To delete the cluster run
```
ansible-playbook delete.yaml
```

## Install add-ons

Currently, the supported add-ons are:
* Kubernetes dashboard
* Heapster for resource monitoring
* Storage class for automatic provisioning of persisitent volumes

To install the add-ons run
```
ansible-playbook addons.yaml
```

## Debugging
Some helpful tips to aid in debugging
* export `ANSIBLE_STDOUT_CALLBACK=debug` in your shell to get human read-able logs
## Scaling Cluster

edit instancegroup
```
kops edit instancegroup nodes
```
Apply the config
```
kops update cluster $KOPS_NAME --yes
```

