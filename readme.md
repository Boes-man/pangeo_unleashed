# Pangeo Unleashed Lab Github

This repo is used with the [Pangeo Unleashed](https://medium.com/p/5cdfc2c045f4/edit) blog and is a step by step version, without the extra context of the original blog. The idea would be to copy and paste the commands in sequence.

## Prerequisites:
- Terraform
- AWS CLI
- SSH
- [jq](https://stedolan.github.io/jq/)
- [Helm](https://helm.sh/docs/using_helm/)

See Mesosphere [documentation](https://docs.mesosphere.com/1.12/installing/evaluation/aws/)

## Steps

- Ensure all prerequisites are installed, that AWS CLI `aws configure --profile=<your-profile-name>` (access key, secret access key, region, etc) is complete and that AWS_PROFILE is set `export AWS_PROFILE="<your-AWS-profile>"`
Do not continue until this is successful.

- Clone this git repo to your computer `git clone https://github.com/Boes-man/pangeo_unleashed.git`
- Move to the folder `cd pangeo_unleashed`
- Make scripts executable `chmod +x *.sh` 
- Edit `main.tf` with correct `availability_zones` list and `region`, if need be and `ssh_public_key_file` eg ssh_public_key_file = "~/.ssh/id_rsa.pub"
- `terraform init`
- `terraform apply -auto-approve`
- Once terraform successfully builds DCOS cluster, install the `dcos cli` as per blog instructions.
- Get cluster endpoint `dcos config show core.dcos_url` eg http://pangeo-lab-1478824809.us-west-2.elb.amazonaws.com
- Set cluster endpoint to https `dcos config set core.dcos_url https://your_cluster_fqdn_above` eg dcos config set core.dcos_url https://pangeo-lab-1478824809.us-west-2.elb.amazonaws.com
- Disable SSL verification `dcos config set core.ssl_verify false`
- Install Portworx `dcos package install portworx --options=px_ectd_6nodes.json --yes`
- Wait for Portworx deployment to complete `dcos portworx plan status deploy`
- Install Marathon-lb `dcos package install marathon-lb --yes`
- Add Kubernetes API application `dcos marathon app add mlb-kube-app-api.json`
- Install Kubernetes Cluster Manager `dcos package install kubernetes --yes`
- Install Kubernetes Cluster `dcos kubernetes cluster create --options=kubernetes1-options-oss.json --yes`
- Wait for Kubernetes Cluster to complete `dcos kubernetes cluster debug plan status deploy --cluster-name=kubernetes-cluster1`
- Get Marathon-lb agent id `mlb_id=$(dcos task marathon-lb. --json |  jq -r '.[] | .slave_id')`
- Get Marathon-lb public IP `mlb_ip=$(dcos node ssh --option StrictHostKeyChecking=no --option LogLevel=quiet --master-proxy --user centos --mesos-id=$mlb_id "curl -s ifconfig.co |  tr -d '\r'")`
- Create KubeConfig `dcos kubernetes cluster kubeconfig --cluster-name=kubernetes-cluster1 --apiserver-url https://$mlb_ip:6443 --insecure-skip-tls-verify`
- Start kubectl proxy in a new or diffrent console window `kubectl proxy`
- Get Kubernetes version `version=$(kubectl version --short | awk -Fv '/Server Version: / {print $3}')`
- Create Portworx Kubernetes `kubectl apply -f "https://install.portworx.com?kbver=${version}&dcos=true&stork=true"`
- Create Portwork Kubernetes Storage Class `kubectl create -f portworx-sc.yaml`
- Set default storage class `kubectl patch storageclass portworx-sc -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'`
- Prep kubernetes for Helm `./2_configure_kubernetes.sh`
- Install Pangeo with Helm `./3_deploy_helm.sh`
- Install Treafik Ingress Controller `./k8_create_treafik.sh`
- Create Pangeo ingress `kubectl create -f pgeo_proxy-ingress.yaml --namespace=pangeo`
- Get Ingress agent id `pangeo_id=$(dcos task kube-node-public --json |  jq -r '.[] | .slave_id')`
- Get Pangeo IP `dcos node ssh --option StrictHostKeyChecking=no --option LogLevel=quiet --master-proxy --user centos --mesos-id=$pangeo_id "curl -s ifconfig.co |  tr -d '\r'"`
