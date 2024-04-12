# Deploy Stack With Environment
https://github.com/moby/moby/issues/29133
PORTAINER
```
sudo su
source .env
export PORTAINER_AGENT_PORT
docker stack deploy -c docker-compose-portainer-agent.yaml portainer_agent
```
