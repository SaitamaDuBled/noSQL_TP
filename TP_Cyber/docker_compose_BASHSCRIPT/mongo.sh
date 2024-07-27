#!/bin/bash

MONGO_URI="mongodb://localhost:27017"
DB_NAME="Galaxies"
BACKUP_PATH="./data/galaxies_backup.archive"

echo "Pulling MongoDB Docker image..."
docker pull mongodb/mongodb-community-server:latest

echo "Running MongoDB container..."
docker-compose up -d

sleep 10

echo "Verifying that the container is running..."
docker ps

echo "Connecting to MongoDB container..."
docker exec -it mongodb_container mongosh --eval 'db.runCommand({ connectionStatus: 1 })'

echo "Creating database and collections..."
docker exec -it mongodb_container mongosh "$MONGO_URI" --eval "
use $DB_NAME;
db.createCollection('Stars');
db.createCollection('Planets');
"

echo "Inserting documents into Stars collection..."
docker exec -it mongodb_container mongosh "$MONGO_URI" --eval "
use $DB_NAME;
db.Stars.insertMany([
  { Name: 'Sun', Type: 'G-Type', Age: 4.6, Distance_from_Earth: 0 },
  { Name: 'Sirius', Type: 'A-Type', Age: 0.2, Distance_from_Earth: 8.6 },
  { Name: 'Betelgeuse', Type: 'M-Type', Age: 8.0, Distance_from_Earth: 640 },
  { Name: 'Polaris', Type: 'F-Type', Age: 70, Distance_from_Earth: 433 },
  { Name: 'Rigel', Type: 'B-Type', Age: 8.0, Distance_from_Earth: 860 }
]);
"

echo "Querying Stars collection..."
docker exec -it mongodb_container mongosh "$MONGO_URI" --eval "
use $DB_NAME;
db.Stars.find().pretty();
"

echo "Inserting documents into Planets collection..."
docker exec -it mongodb_container mongosh "$MONGO_URI" --eval "
use $DB_NAME;
db.Planets.insertMany([
  { Name: 'Earth', Type: 'Rocky', Number_of_Moons: 1, Distance_from_Sun: 149.6 },
  { Name: 'Mars', Type: 'Rocky', Number_of_Moons: 2, Distance_from_Sun: 227.9 },
  { Name: 'Jupiter', Type: 'Gas Giant', Number_of_Moons: 79, Distance_from_Sun: 778.3 },
  { Name: 'Saturn', Type: 'Gas Giant', Number_of_Moons: 83, Distance_from_Sun: 1427 },
  { Name: 'Neptune', Type: 'Ice Giant', Number_of_Moons: 14, Distance_from_Sun: 4495 }
]);
"

echo "Creating indexes on Name field..."
docker exec -it mongodb_container mongosh "$MONGO_URI" --eval "
use $DB_NAME;
db.Stars.createIndex({ Name: 1 });
db.Planets.createIndex({ Name: 1 });
"

echo "Creating a backup of the Galaxies database..."
docker exec -it mongodb_container mongodump --uri="$MONGO_URI/$DB_NAME" --archive=/data/db/galaxies_backup.archive

echo "Moving backup to host directory..."
docker cp mongodb_container:/data/db/galaxies_backup.archive $BACKUP_PATH

echo "Setup complete!"
