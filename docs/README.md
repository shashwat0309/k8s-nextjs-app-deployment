# Initial Setup

### Prerequisite
- [AWS Account](https://aws.amazon.com/resources/create-account/)
- Access/Secret keys are generated and configured (Ref: [link](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html))
- Required CLI Tools: [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli), [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/). [Kubectl](https://kubernetes.io/docs/tasks/tools/), [Helm](https://helm.sh/docs/intro/install/)
- S3 bucket for Terragrunt state files.



## Deployment steps

### Step-1: Update Bucket, Account, Region and Environment

- Update the bucket name in file: `/infra/terragrunt/backed.tf` and `/infra/terragrunt/terragrunt.hcl`
- Update Account, Region and Environmet in files:

```bash
/infra/terragrunt/aws/<account-name>/account.hcl
/infra/terragrunt/aws/<account-name>/<region-name>/region.hcl
/infra/terragrunt/aws/<account-name>/<region-name>/<environment-name>/environment.hcl

```

### Step-2: Deploy Cloud Services

- VPC
  - Public Subnets
  - Private Subnets
  - NAT gateway
  - Internet gateway
- ECR
- EKS (Carpenter Setup)
- IAM


1. Navigate to the relevant folderd for each services, e.g., `infra/terragrunt/aws/test/us-east-1/vpc`.
2. Update the neccassary values in the `terragrunt.hcl` file.
3. Run the following commands:

```bash
terragrunt init
terragrunt plan
terragrunt apply
```

**Note** - To connect with EKS Cluster

``` aws eks --region <region> update-kubeconfig --name <cluster-name>```

### Step 3: Deploy required operators/services in cluster

#### 3.1 Deploy ArgoCD

Argo CD is a declarative, GitOps continuous delivery tool for Kubernetes. We would be using it to manage CD for Backend deployments.


- Clone the repository.
- Navigate to the `infra/helm-charts/argo-cd directory`.
- Create a new values file (e.g., `values.override.yaml`) and configure values as needed:
```bash
e.g.,:
values.override.yaml:
    ingress:
        enabled: true

```
- Connect to the EKS cluster and install Argo CD:

```bash
helm upgrade --install --create-namespace -n argocd argocd . -f values.yaml -f values.override.yaml 
```
- Deploy root application for argoCD: 
```bash 
cd /infra/argocd/bootstrap
kubectl apply -f root.yaml -n argocd 
```
**NOTE**: The default username of the ArgoCD UI would be `admin` and password can be obtained via below-mentioned command:

```bash
kubectl get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

#### 3.2 Setup Monitoring

- Clone the repository
- Navigate to `infra/argocd/apps/monitoring`
- Update  `config.yaml` file with the necessary values
- Commit and push changes to the master branch. 

### Step 4 Application Deployment via ArgoCD

- Navigate to the `infra/argocd/apps/app-next directory`
-  Update  `config.yaml` file with the necessary values:

```bash
e.g.,
destNamespace: "next-app"
appValues: |
  ### Basic
  nameOverride: "" 
  namespace: "'

  image:
    repository: <ecr-repo>
    tag: <image-tag>


  replicas: ""

  ingress:
    enabled: ""
  autoscalling:
    min: ""
    max: ""
    targetCPUutilisation: ""

```
- Commit and push changes to the master branch.
