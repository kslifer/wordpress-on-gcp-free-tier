#!/bin/sh

echo "Loading terraform.tfvars into environment variables..."

eval $(egrep "^[^#;]" ./terraform/terraform.tfvars | sed 's/ *//g' | sed 's/"//g' | sed '/^$/d' | sed '/^#/d' | xargs -d'\n' -n1 | sed 's/^/export /')