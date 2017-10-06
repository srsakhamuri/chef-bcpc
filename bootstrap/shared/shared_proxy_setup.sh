#!/bin/bash

source "$REPO_ROOT"/bootstrap/shared/shared_functions.sh
load_configs

get(){
  local timeout=10
  local url="$1"

  [[ -z "$url" ]] && return 1
  local args="-s --connect-timeout $timeout"
  # Add the certs for proxy test if available
  if [[ -d "$BOOTSTRAP_ADDITIONAL_CACERTS_DIR" ]] && \
      [[ -x "$BOOTSTRAP_ADDITIONAL_CACERTS_DIR" ]]; then
    args+=" --capath $BOOTSTRAP_ADDITIONAL_CACERTS_DIR"
  fi
  curl $args "$url"
}

[ -n "$SHARED_PROXY_SETUP" ] || {
  REQUIRED_VARS=( BOOTSTRAP_HTTP_PROXY_URL BOOTSTRAP_HTTPS_PROXY_URL )
  check_for_envvars "${REQUIRED_VARS[@]}"
  
  if [[ ! -z "$BOOTSTRAP_HTTP_PROXY_URL" ]]; then
    export http_proxy="${BOOTSTRAP_HTTP_PROXY_URL}"

    get http://www.google.com > /dev/null && true
    if [[ $? != 0 ]]; then
      echo "Error: proxy $BOOTSTRAP_HTTP_PROXY_URL non-functional for HTTP requests" >&2
      exit 1
    fi
  fi

  if [[ ! -z "$BOOTSTRAP_HTTPS_PROXY_URL" ]]; then
    export https_proxy="${BOOTSTRAP_HTTPS_PROXY_URL}"
    get https://github.com > /dev/null && true
    if [[ $? != 0 ]]; then
      echo "Error: proxy $BOOTSTRAP_HTTPS_PROXY_URL non-functional for HTTPS requests" >&2
      exit 1
    fi
  fi
}

# State variable to avoid doing this again
export SHARED_PROXY_SETUP=1
