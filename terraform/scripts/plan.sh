#!/usr/bin/env bash
set -e

DIR_NAME="${1}"
shift
PR_NUMBER="${1}"
if [ -z "$DIR_NAME" ]
then
  >&2 echo "Please specify which directory to plan as first argument"
  exit 1
fi

TITLE=$(echo ${DIR_NAME} | sed 's|^[a-z-]*\/||')

# Generate markdown terraform plan
terragrunt run-all plan -lock=false --terragrunt-include-dir=aws/envs/${DIR_NAME}/**/* -out=terraform.plan
./scripts/collect-and-push-plans.sh "${DIR_NAME}" ./.terraform.md "$TITLE"

# Push plan to GH as a comment
if [ -n "$PR_NUMBER" ]
then
  if ! gh pr comment "${PR_NUMBER}" --body-file "./.terraform.md"
  then
    echo "No active pull request to write comment to ${PR_NUMBER}"
  fi
else
  >&2 echo "Not commenting on PR"
fi
