cluster_name: demo.jiannc.com
state_store: s3://jiannc-com-state-store
version: 1.7.2
REGION: US

# Remote access
ssh_public_key: ~/.ssh/id_rsa.pub

# Regions / Availability zones
aws_region: us-east-1
# aws_zones: us-east-1a,us-east-1b,us-east-1c
aws_zones: us-east-1a

# TODO: fixme, Network
dns_zone: Z3IIG95WRED95Q
network_cidr: 192.168.0.0/16
kubernetes_networking: calico
Topology: private



# EC2 host sizing
master_size: t2.micro
node_size: t2.micro
node_count: 2
master_volume_size: 8G
node_volume_size: 8G
#
# Additional namespaces
#
namespaces:
  - staging
  - prod

#
# Fluentd configs
#
#
FLUENTD_LOGSTASH_PREFIX: logstash-internal-k8s

enable_internal_ingress: true
enable_external_ingress: true

enable_default_ingress: true