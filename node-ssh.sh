#!/usr/bin/env bash

# SSH into a DC/OS node by IP.
# Wrapper around "dcos node ssh" to simplify usage.
# Command may be specified by flag or STDIN.
#
# Requires direct network access to the NODE_IP from the current machine.
# We can't use --master-proxy with an IdentityFile. Otherwise it would need to be on the masters at the exact same path.
#
# Options:
#  -i --insecure         Ignore known_hosts checking
#  -q --quiet            Silence non-error output
#
# Flags:
#  -u --user <STRING>     Name of the SSH user to use for the nodes (e.g. root or centos or vagrant)
#  -k --key <PATH>        Path (relative or absolute) to the SSH user's private key (e.g. ~/.ssh/rsa_id_centos.pem)
#  -c --command <STRING>  Command to execute
#
# Usage:
# $ node-ssh.sh [--insecure] [--user STRING] [--key PATH] [--command "COMMAND"] <NODE_IP>
# OR
# $ node-ssh.sh [--insecure] [--user STRING] [--key PATH] [--command "COMMAND"] <NODE_IP> < command.sh
# OR
# $ node-ssh.sh [--insecure] [--user STRING] [--key PATH] [--command "COMMAND"] <NODE_IP> <<< EOM
# > COMMAND
# > EOM

set -o errexit -o nounset -o pipefail

for i in "$@"; do
  if [[ -n "${FLAG_VAR:-}" ]]; then
    eval "${FLAG_VAR}=\"${i}\""
    FLAG_VAR=""
    continue
  fi
  case "${i}" in
    -i|--insecure)
      INSECURE="true"
      ;;
    -u|--user)
      FLAG_VAR="USER"
      ;;
    -k|--key)
      FLAG_VAR="PRIVATE_KEY"
      ;;
    -c|--command)
      FLAG_VAR="COMMAND"
      ;;
    *)
      if [[ -z "${NODE_IP:-}" ]]; then
        NODE_IP="${i}"
      else
        echo >&2 "Invalid parameter: ${i}"
        exit 1
      fi
      ;;
  esac
done

if [[ -z "${NODE_IP:-}" ]]; then
  echo >&2 "Error: NODE_IP is a required argument."
  exit 1
fi

# Use array to store arguments so that quotes are preserved
DCOS_SSH_ARGS=()

if [[ -n "${USER:-}" ]]; then
  DCOS_SSH_ARGS+=(--user "${USER}")
fi

if [[ "${INSECURE:-}" == 'true' ]]; then
  # dcos node ssh isn't quiet, so this only helps a little bit
  DCOS_SSH_ARGS+=(--option "LogLevel=QUIET")
  DCOS_SSH_ARGS+=(--option "StrictHostKeyChecking=no")
fi

if [[ -n "${PRIVATE_KEY:-}" ]]; then
  DCOS_SSH_ARGS+=(--option "IdentityFile=${PRIVATE_KEY}")
fi

if [[ -n "${COMMAND:-}" ]]; then
  dcos node ssh "${DCOS_SSH_ARGS[@]}" --private-ip=${NODE_IP} "${COMMAND}"
else
  dcos node ssh "${DCOS_SSH_ARGS[@]}" --private-ip=${NODE_IP}
fi
