#!/bin/bash

# Performs PUT/GET/DELETE (in this order) with user-specified S3 credentials
# and bucket to validate S3 functionality.

start_time=$(date +%s.%N)
script=$(basename "$0")
key=$1
secret=$2
proto=$3
fqdn=$4
bucket=$5
s3_path=$6
local_path=/tmp
filename="$script-$(hostname -s)-$fqdn-$start_time"
file_content="$(uuidgen) $date"
content_type='application/x-compressed-tar'
acl="x-amz-acl:private"
curl_cmd='curl -q -f --max-time 10'
[[ $proto == 'https' ]] && curl_cmd="$curl_cmd -k"

function get_signature()
{
  string=$1
  signature=$(echo -en "${string}" | openssl sha1 -hmac "${secret}" -binary | base64)
  echo "$signature"
}

function get_date()
{
  date=$(date -R -u)
  echo "$date"
}

function log()
{
  message=$1
  logger -t s3test -p syslog.notice "$message"
}

# Create a monitoring test file for upload
echo "$file_content" > "$local_path/$filename"

# Create bucket
date=$(get_date)
verb=PUT
string="$verb\n\n\n$date\n/$bucket/"
signature=$(get_signature "$string")
$curl_cmd -X $verb \
  -H "Host: $bucket.$fqdn" \
  -H "Date: $date" \
  -H "Authorization: AWS ${key}:$signature" \
  "$proto://${bucket}.${fqdn}" 2>/dev/null

[[ $? -eq 0 ]] || { echo -1 && exit 0; }

# Upload, download and delete file
for verb in PUT GET DELETE; do
  curl="$curl_cmd -X $verb"
  date=$(get_date)
  string="$verb\n\n$content_type\n$date\n$acl\n/$bucket$s3_path$filename"
  signature=$(get_signature "$string")

  if [ $verb == 'PUT' ]; then
    curl="$curl -T $local_path/$filename"
  elif [ $verb == 'GET' ]; then
    curl="$curl -o $local_path/$filename"
  fi

  log "Starting $verb $filename"
  $curl \
    -H "Host: $bucket.$fqdn" \
    -H "Date: $date" \
    -H "Content-Type: $content_type" \
    -H "$acl" \
    -H "Authorization: AWS ${key}:$signature" \
    "$proto://${bucket}.${fqdn$s3_path}${filename}" 2>/dev/null

  rc="$?"
  log "$verb $filename returned $rc"
  [[ $rc -eq 0 ]] || { echo -1 && exit 0; }

  # Ensure monitoring test file does not exist
  [[ -f "$local_path"/"$filename" ]] && rm -f "$local_path"/"$filename"

done

end_time=$(date +%s.%N)
duration=$(echo "${end_time}"-"${start_time}" | bc -l)

echo "$duration"
