# Database Instance on Docker

> This repository is inspired by [docker/awesome-compose](https://github.com/docker/awesome-compose) but customized for personal use with a focus on database instances and related services. It provides simplified and ready-to-use docker-compose configurations for various databases and services.

## Available Database Options
This repository provides docker-compose configurations for various databases and services:

- PostgreSQL (`docker-compose-postgres.yaml`)
- MySQL (`docker-compose-mysql.yaml`)
- MongoDB (`docker-compose-mongodb.yaml`)
- MS SQL Server (`docker-compose-mssql.yaml`)
- Redis (`docker-compose-redis.yaml`)
- RabbitMQ (`docker-compose-rabbitmq.yml`)

Additional services:
- pgAdmin (`docker-compose-pgadmin.yaml`)
- Portainer (`docker-compose-portainer.yaml`)
- Prometheus (`docker-compose-prometheus.yml`)
- Registry (`docker-compose-registry.yaml`)
- Postfix (`docker-compose-postfix.yaml`)

## Usage Note
**IMPORTANT: DO NOT USE THE DEFAULT DOCKER COMPOSE FILES DIRECTLY IN PRODUCTION**

1. Copy the desired docker-compose file to create your running instance:
```bash
# For PostgreSQL example
cp docker-compose-postgres.yaml PROD-docker-compose-postgres.yaml
```

2. Configure your environment:
```bash
# Copy the environment template
cp .env.format .env
# Edit the .env file with your desired configuration
```

3. Create a docker network (if not exists):
```bash
docker network create main-network -d bridge
```

4. Run the docker compose file:
```bash
docker compose -f PROD-docker-compose-postgres.yaml up -d --build
```

## Deployment Scripts
For convenience, deployment scripts are provided for each service:
- `deploy-postgres.sh`
- `deploy-mysql.sh`
- `deploy-redis.sh`
- `deploy-mssql.sh`
- `deploy-portainer-stack.sh`
- `deploy-registry.sh`
- `deploy-postfix.sh`

These scripts handle the copying and deployment process automatically.

## Additional Services

### Database Explorers
- pgAdmin for PostgreSQL
- Portainer for container management
- Prometheus for monitoring

To run an explorer:
```bash
docker compose -f docker-compose-explorer.yml up -d --build
```

### Monitoring and Management
- Portainer for container management
- Prometheus for metrics collection
- Autoheal for container health management

## Security Notes
1. Always use different credentials for each environment
2. Keep your `.env` files secure and never commit them to version control
3. Use the provided deployment scripts to ensure proper setup
4. Consider using docker secrets for sensitive data in production
.