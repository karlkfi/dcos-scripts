#!/usr/bin/env bash

# Generates a JWT (token) for a user using the dcos-oauth private key.
# Technically, this bypasses the login API and authentication provider.
# This method is only for testing and should not be used in production!
#
# Options:
#  -i --insecure              Ignore known_hosts checking
#
# Flags:
#  -d --duration <INTEGER>    Number of seconds until the JWT (token) expires (default: 86400)
#  -u --user <STRING>         Name of the SSH user to use for the nodes (e.g. root or centos or vagrant)
#  -k --key <PATH>            Path (relative or absolute) to the SSH user's private key (e.g. ~/.ssh/rsa_id_centos.pem)
#
# Usage:
# $ login-oauth-user.sh [--insecure] [--user STRING] [--key PATH] <user-email>

set -o errexit -o nounset -o pipefail

# Defaults
DURATION=86400 #24hrs

for i in "$@"; do
  if [[ -n "${FLAG_VAR:-}" ]]; then
    eval "${FLAG_VAR}=\"${i}\""
    FLAG_VAR=""
    continue
  fi
  case "${i}" in
    -d|--duration)
      FLAG_VAR="DURATION"
      ;;
    -i|--insecure)
      INSECURE="true"
      ;;
    -u|--user)
      FLAG_VAR="USER"
      ;;
    -k|--key)
      FLAG_VAR="PRIVATE_KEY"
      ;;
    *)
      if [[ -z "${USER_EMAIL:-}" ]]; then
        USER_EMAIL="${i}"
      else
        echo >&2 "Invalid parameter: ${i}"
        exit 1
      fi
      ;;
  esac
done

if [[ -z "${USER_EMAIL:-}" ]]; then
  echo >&2 'User email required'
  exit 2
fi

if ! [[ -f "./node-ssh.sh" ]]; then
  echo >&2 "Error: ./node-ssh.sh not found."
  exit 2
fi

NODE_LIST_JSON="$(dcos node --json)"
MASTER_IP="$(echo "${NODE_LIST_JSON}" | jq -r '.[] | select(.type == "master (leader)") | .ip')"

if [[ -z "${MASTER_IP}" ]]; then
  echo >&2 "Error: Leading master not found."
  exit 2
fi

# Use array to store arguments so that quotes are preserved
NODE_SSH_ARGS=()

if [[ "${INSECURE:-}" == 'true' ]]; then
  NODE_SSH_ARGS+=(--insecure)
fi

if [[ -n "${USER:-}" ]]; then
  NODE_SSH_ARGS+=(--user "${USER}")
fi

if [[ -n "${PRIVATE_KEY:-}" ]]; then
  NODE_SSH_ARGS+=(--key "${PRIVATE_KEY}")
fi

./node-ssh.sh "${NODE_SSH_ARGS[@]}" ${MASTER_IP} << EOM
docker run --rm \
    -v /var/lib/dcos/dcos-oauth/auth-token-secret:/key \
    karlkfi/jwt-encoder ${USER_EMAIL} /key --duration=${DURATION}
EOM
