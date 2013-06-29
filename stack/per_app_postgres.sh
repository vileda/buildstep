#!/bin/bash
set -e

export APP_NAME=$1
export PGHOST=$(< $HOME/predeploy.d/postgres_host)
export PGUSER=admin

if [ -f $HOME/$APP_NAME/DATABASE_URL ]; then
	# Database URL is already set - DB must exist
	DATABASE_URL=$(cat $HOME/$APP_NAME/DATABASE_URL)
else
	# New DB needs to be created
	DB_NAME=$(echo $APP_NAME | sed -r 's/[^a-z0-9]/_/g')
	USER_NAME=$DB_NAME
	USER_PASSWORD=$(tr -dc "[:alpha:]" < /dev/urandom | head -c 16)

	echo "CREATE ROLE $USER_NAME WITH LOGIN ENCRYPTED PASSWORD '$USER_PASSWORD'" | psql -h $PGHOST -d postgres -U $PGUSER
	echo "CREATE DATABASE $DB_NAME WITH OWNER $USER_NAME" | psql -h $PGHOST -d postgres -U $PGUSER

	DATABASE_URL="postgresql://$USER_NAME:$USER_PASSWORD@$PGHOST/$DB_NAME"
	echo "$DATABASE_URL" > $HOME/$APP_NAME/DATABASE_URL
	echo -n " -d -e DATABASE_URL=${DATABASE_URL} " > $HOME/$APP_NAME/CUSTOM_ENV
fi

echo "     Database URL: $DATABASE_URL"