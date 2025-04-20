This folder contains resources to deploy and manage the infrastructure of nextjs-app It's using terragrunt & terraform to manage multiple environments and resources.

In order to change the infrastructure, a PR should be created and the plan reviewed. Once the PR gets merge to `main`, the plan will be applied and the infrastructure will be updated.

## Structure

- aws/envs contains all the env specific configuration
- aws/modules contains all the re-usable modules (to be extracted as its own github repo)

## Local setup
Terraform Version: v1.6.5
Terragrunt Version: v0.45.2

```bash
$ cd aws/envs
$ terragrunt run-all init
$ terragrunt run-all plan
```

## CICD

### plan.yaml
- Setup terraform2md to push terraform plan files as comments on PR
- Uses special role (`role/infra-reader`) to run `terragunt plan` command
- Execute `scripts/plan.sh`

### apply.yaml
- Execute `terragrunt run-all apply`

### plan.sh
- Execute `make plan-${env}`:
  - execute `terragrunt run-all plan` in the specified `env` and output plan as `terraform.plan` file
  - execute `scripts/collect-and-push-plans.sh`
- Push plan as comment on PR

### collect-and-push-plans.sh
- Create output file
- For each `terraform.plan` file, add the plan to the output file
