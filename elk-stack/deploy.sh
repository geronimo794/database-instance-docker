#/bin/bash

CURRENT_USER=$(eval "whoami")
CURRENT_GROUP=$(eval "id -gn")

sudo chown 0 metricbeat.yml
sudo docker compose up -d --build

# Reverse the chown
# sudo chown $CURRENT_USER:$CURRENT_GROUP metricbeat.yml
