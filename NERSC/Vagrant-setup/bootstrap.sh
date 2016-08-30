#!/bin/sh -e

# Edit the following to change the name of the database user that will be created:
PGUSER=mpo_user
# PGPASS='7GVvPHzx5iMnXgw'
PGPASS=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 20 | head -n 1)

# Edit the following to change the name of the database that is created (defaults to the user name)
PGDATABASE=mpo_nersc
PGHOST=localhost

# N.B. These must match the ports declared in the networking portion of the Vagrantfile!
PGPORT=5432
PGPORT_FORWARDED=15432
# Edit the following to change the version of PostgreSQL that is installed
PG_VERSION=9.5

###########################################################
# Changes below this line are probably not necessary
###########################################################
print_db_usage () {
  echo "Your PostgreSQL database has been setup and can be accessed on your local machine on the forwarded port (default: $PGPORT)"
  echo "  Host: $PGHOST"
  echo "  Port: $PGPORT"
  echo "  Database: $PGDATABASE"
  echo "  Username: $PGUSER"
  echo "  Password: $PGPASS"
  echo ""
  echo "Admin access to postgres user via VM:"
  echo "  vagrant ssh"
  echo "  sudo su - postgres"
  echo ""
  echo "psql access to app database user via VM:"
  echo "  vagrant ssh"
  echo "  sudo su - postgres"
  echo "  PGUSER=$PGUSER PGPASSWORD=$PGPASS psql -h $PGHOST $PGDATABASE"
  echo ""
  echo "Env variable for application development:"
  echo "  DATABASE_URL=postgresql://$PGUSER:$PGPASS@$PGHOST:$PGPORT_FORWARDED/$PGDATABASE"
  echo ""
  echo "Local command to access the database via psql:"
  echo "  PGUSER=$PGUSER PGPASSWORD=$PGPASS psql -h $PGHOST -p $PGPORT $PGDATABASE"
}

export DEBIAN_FRONTEND=noninteractive

PROVISIONED_ON=/etc/vm_provision_on_timestamp
if [ -f "$PROVISIONED_ON" ]
then
  echo "VM was already provisioned at: $(cat $PROVISIONED_ON)"
  echo "To run system updates manually login via 'vagrant ssh' and run 'apt-get update && apt-get upgrade'"
  echo ""
  print_db_usage
  exit
fi

PG_REPO_APT_SOURCE=/etc/apt/sources.list.d/pgdg.list
if [ ! -f "$PG_REPO_APT_SOURCE" ]
then
  # Add PG apt repo:
  echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" > "$PG_REPO_APT_SOURCE"

  # Add PGDG repo key:
  wget --quiet -O - https://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | apt-key add -
fi

# Update package list and upgrade all packages
apt-get update
apt-get -y upgrade

apt-get -y install "postgresql-$PG_VERSION" "postgresql-contrib-$PG_VERSION"

PG_CONF="/etc/postgresql/$PG_VERSION/main/postgresql.conf"
PG_HBA="/etc/postgresql/$PG_VERSION/main/pg_hba.conf"
PG_DIR="/var/lib/postgresql/$PG_VERSION/main"

# Edit postgresql.conf to change listen address to '*':
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "$PG_CONF"

# Append to pg_hba.conf to add password auth:
echo "host    all             all             all                     md5" >> "$PG_HBA"

# Explicitly set default client_encoding
echo "client_encoding = utf8" >> "$PG_CONF"

# Restart so that all new config is loaded:
service postgresql restart

cat << EOF | su - postgres -c psql
-- Create the database users:
CREATE USER $PGUSER  WITH PASSWORD '$PGPASS';
CREATE USER mpoadmin WITH PASSWORD '$PGPASS';

-- Create the database:
CREATE DATABASE $PGDATABASE WITH OWNER=mpoadmin
                                  LC_COLLATE='en_US.utf8'
                                  LC_CTYPE='en_US.utf8'
                                  ENCODING='UTF8'
                                  TEMPLATE=template0;
EOF

# Tag the provision time:
date > "$PROVISIONED_ON"

# Now set up the vagrant account to have access to this database
(
  echo "${PGHOST}:${PGPORT}:${PGDATABASE}:${PGUSER}:${PGPASS}"
  echo "${PGHOST}:${PGPORT}:${PGDATABASE}:mpoadmin:${PGPASS}"
) | tee ~vagrant/.pgpass >/dev/null
chmod 0600 ~vagrant/.pgpass
chown vagrant:vagrant ~vagrant/.pgpass
usermod -a -G postgres vagrant
(
  echo " "
  echo "# Setting up for PostgreSQL"
  echo "export PGUSER=$PGUSER"
  echo "export PGHOST=$PGHOST"
  echo "export PGPORT=$PGPORT"
  echo "export PGDATABASE=$PGDATABASE"
  echo "export PATH=\${PATH}:/usr/lib/postgresql/$PG_VERSION/bin"
  echo "export MPO_HOME=/vagrant"
) >> ~vagrant/.profile

echo "Successfully created PostgreSQL dev virtual machine."
echo ""
print_db_usage
