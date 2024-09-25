# Deploy Stack With Environment
https://github.com/moby/moby/issues/29133
1. Portainer Agent
```
sudo su
...
source .env
export PORTAINER_AGENT_PORT
docker stack deploy -c docker-compose-portainer-agent.yaml portainer_agent
```
2. MySQL
```
sudo su
...
source .env
export NETWORK
export MYSQL_USER
export MYSQL_DATABASE
export MYSQL_PORT
docker stack deploy -c docker-compose-mysql.yaml -d mysql
```
3. MongoDB
```
sudo su
...
source .env
export NETWORK
export MONGODB_PORT
docker stack deploy -c docker-compose-mongodb.yaml -d mongodb
```
