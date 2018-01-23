#!/usr/bin/env bash

# Extracts the journalctl logs on each node.
# Writes to <node-type>-<node-ip>.log
#
# Options:
#  -i --insecure         Ignore known_hosts checking
#
# Flags:
#  -n --lines <INTEGER>   Number of journal entries to show
#  -u --user <STRING>     Name of the SSH user to use for the nodes (e.g. root or centos or vagrant)
#  -k --key <PATH>        Path (relative or absolute) to the SSH user's private key (e.g. ~/.ssh/rsa_id_centos.pem)
#
# Usage:
# $ extract-logs.sh [--lines INTEGER] [--insecure] [--user STRING] [--key PATH]

set -o errexit -o nounset -o pipefail

for i in "$@"; do
  if [[ -n "${FLAG_VAR:-}" ]]; then
    eval "${FLAG_VAR}=\"${i}\""
    FLAG_VAR=""
    continue
  fi
  case "${i}" in
    -n|--lines)
      FLAG_VAR="LINES"
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
      echo >&2 "Invalid parameter: ${i}"
      exit 1
      ;;
  esac
done

if [[ -n "${FLAG_VAR:-}" ]]; then
  echo >&2 "Invalid parameter: ${i} requires a subsequent value"
  exit 2
fi

if [[ -n "${LINES:-}" ]]; then
  LINES_ARG="-n ${LINES}"
fi

if ! [[ -f "./node-ssh.sh" ]]; then
  echo >&2 "Error: ./node-ssh.sh not found."
fi

NODE_LIST_JSON="$(dcos node --json)"
MASTER_IPS="$(echo "${NODE_LIST_JSON}" | jq -r '.[] | select(.type | startswith("master")) | .ip')"
AGENT_IPS="$(echo "${NODE_LIST_JSON}" | jq -r '.[] | select(.type | startswith("agent")) | .hostname')"

# Use array to store arguments so that quotes are preserved
NODE_SSH_ARGS=(--command "journalctl --no-pager ${LINES_ARG:-}")

if [[ "${INSECURE:-}" == 'true' ]]; then
  NODE_SSH_ARGS+=(--insecure)
fi

if [[ -n "${USER:-}" ]]; then
  NODE_SSH_ARGS+=(--user "${USER}")
fi

if [[ -n "${PRIVATE_KEY:-}" ]]; then
  NODE_SSH_ARGS+=(--key "${PRIVATE_KEY}")
fi

for NODE_IP in ${MASTER_IPS}; do
  echo "Extracting Node Logs (Master): ${NODE_IP}"
  ./node-ssh.sh "${NODE_SSH_ARGS[@]}" ${NODE_IP} > "master-${NODE_IP}.log"
done

for NODE_IP in ${AGENT_IPS}; do
  echo "Extracting Node Logs (Agent): ${NODE_IP}"
  ./node-ssh.sh "${NODE_SSH_ARGS[@]}" ${NODE_IP} > "agent-${NODE_IP}.log"
done
