#!/usr/bin/env bash
set -e

root=$(pwd)

# $1 = stage/region/env subfolder
# $2 = output file
# $3 = title
if [ -z "${1}" ]
then
  >&2 echo "Please provide the directory name as first arg"
  exit 1
fi
if [ -z "${1}" ]
then
  >&2 echo "Please provide the output filename as second arg"
  exit 1
fi

OUTPUT="${root}/${2}"
TITLE="${3}"

cat <<END > "${OUTPUT}"
# Plans ${3}
END

for plan in $(find . -name terraform.plan)
do
  dir=$(dirname "${plan}")
  name=$(echo "${plan}" | sed -e "s#.*/\([^/]*\)/\.terragrunt-cache.*/.*#\1#")
  (
    cd "${dir}"
    cat <<END >> "${OUTPUT}"

## ${name}

END
    name=$(echo "${plan}" | sed -e "s#${dir}#.#")
    terraform show -no-color -json "${name}" | terraform-j2md >> "${OUTPUT}"
  )
done