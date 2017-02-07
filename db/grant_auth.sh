#!/bin/sh

(
  echo "grant select, update, insert, delete on mpousers to $PGUSER;"
  echo "grant select, update, insert, delete on mpoauth to $PGUSER;"
  echo "grant select, update, insert, delete on collection to $PGUSER;"
  echo "grant select, update, insert, delete on collection_elements to $PGUSER;"
  echo "grant select, update, insert, delete on workflow to $PGUSER;"
  echo "grant select, update, insert, delete on dataobject to $PGUSER;"
  echo "grant select, update, insert, delete on dataobject_instance to $PGUSER;"
  echo "grant select, update, insert, delete on activity to $PGUSER;"
  echo "grant select, update, insert, delete on comment to $PGUSER;"
  echo "grant select, update, insert, delete on workflow_connectivity to $PGUSER;"
  echo "grant select, update, insert, delete on metadata to $PGUSER;"
  echo "grant select, update, insert, delete on ontology_classes to $PGUSER;"
  echo "grant select, update, insert, delete on ontology_terms to $PGUSER;"
  echo "grant select, update, insert, delete on ontology_instances to $PGUSER;"

  echo "insert into mpousers (username,uuid,firstname,lastname,email,organization,dn,creation_time) values ('$PGUSER', uuid_generate_v4(), 'MPO', 'APP User', 'wildish@lbl.gov', 'LBNL', 'emailAddress=wildish@lbl.gov,CN=/DN goes here',now());"
  echo "insert into mpoauth (u_guid, read, write) select uuid, true, true from mpousers where uuid not in ( select u_guid from mpoauth);"

) | psql --username mpoadmin --host $PGHOST --port $PGPORT $PGDATABASE