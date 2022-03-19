#! /bin/bash

# Import the keys
wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -

# Add the repository
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list

# Update the apt cache
sudo apt-get update -y

# Install mongodb-org
sudo apt-get install -y mongodb-org

# -- Optional --
# Prepare data directory
sudo mkdir -p /data
sudo chown mongodb:mongodb -R /data