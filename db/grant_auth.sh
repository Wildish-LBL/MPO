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
) | psql --username mpoadmin --host $PGHOST --port $PGPORT $PGDATABASE