# Database Instance on Docker
## Usage Note: 
## IF YOU ARE USING THIS REPO TO SET UP YOUR DATABASE, DONT DIRECTLY USE THE DEFAULT DOCKER COMPOSE FILES.
1. Copy the desired docker-compose file to create your running instance. For example(or whatever you want to name it):
```
cp docker-compose-postgres.yml PROD-docker-compose-postgres.yml
```
2. Run the docker compose file:
```
docker compose -f PROD-docker-compose-postgres.yml up -d --build
```
3. You can name it whatever you want, but it should be something that indicates the environment. And make sure it's different for each environment and the default docker-compose.yml file is not used.

## Setting Up the Database
1. Create your environment file by copying the template:
```
cp .env.format .env
```
2. Configure the required fields (user and password) in the `.env` file
3. Create a docker network for your service (network name can be modified in the `.env` file):
```
docker network create main-network -d bridge
```
4. Run the docker compose file:
```
docker compose -f docker-compose.yml up -d --build
```

## Running the Explorer
1. Ensure the database is running first
2. Launch the explorer using docker compose:
```
docker compose -f docker-compose-explorer.yml up -d --build
```