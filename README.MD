# Database Instance on Docker
## Run the Database
1. Copy .env.format to .env
```
cp .env.format .env
```
2. Fill the needed field like user and password on ```.env``` file
3. Run the docker compose file
```
docker compose -f docker-compose.yml up -d --build
```
## Run the explorer
1. Run the database first
2. Run the docker compose of explorer
```
docker compose -f docker-compose-explorer.yml up -d --build
```