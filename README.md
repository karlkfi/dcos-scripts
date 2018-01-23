# DC/OS Scripts

A collection of bash scripts that utilize the [DC/OS CLI](https://docs.mesosphere.com/latest/cli/) and [DC/OS API](https://docs.mesosphere.com/latest/api/).

## Example: Install CLI

```
# Install and configure to target dcos-docker or dcos-vagrant
./install-cli.sh http://m1.dcos/
```

## Example: CLI Login with Test User

```
# Create User
DCOS_USER="test@example.com"
./create-oauth-user.sh "${DCOS_USER}"

# Login
DCOS_ACS_TOKEN="$(./login-oauth-user.sh "${DCOS_USER}")"
dcos config set core.dcos_acs_token "${DCOS_ACS_TOKEN}"
```

## Example: Install Marathon App

```
# Install Oinker
dcos marathon app add oinker.json
./await-app-health.sh "$(cat oinker.json | jq -r '.id')"

# Block until Marathon-LB routing works (1 minute timeout)
ci/await-url-health.sh "http://$(cat oinker.json | jq -r '.labels.HAPROXY_0_VHOST')/" 60
```

## Example: Install SDK Service

```
# Install Cassandra
dcos package install cassandra --yes
./await-app-health.sh 'cassandra'

# Block until cassandra node deployment is complete (15 minute timeout)
./await-sdk-health.sh 'cassandra' 'cassandra' 900
```

## Example: Extract All Node Logs

```
# SSH into each node and download the journalctl contents to local log files
./extract-logs.sh
```

## License

Copyright 2018 Karl Isenberg

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
