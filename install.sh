#!/usr/bin/env bash
source ./scripts/init.sh
ACTION=$1
ENV=$2

if [ -z ${ENV} ]; then
  echo "ENV is not defined"
  exit 1
fi

if ! [[ ${ACTION} =~ ^(apply|destroy|show)$ ]]; then
  echo "ACTION is not valid. Should be 'apply' or 'destroy'"
  exit 1
fi

set -euo pipefail
export ENV
export TF_VAR_env_folder=$(pwd)/envs/${ENV}
terraform -chdir=terraform init -backend-config="bucket=${S3_TF_STATE}" -reconfigure
terraform -chdir=terraform workspace select ${ENV} || terraform -chdir=terraform workspace new ${ENV}
terraform -chdir=terraform ${ACTION}