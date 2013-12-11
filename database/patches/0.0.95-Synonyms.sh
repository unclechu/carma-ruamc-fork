#!/bin/bash -e

$PSQL -c 'drop table "Dictionary"'
$PSQL -f baseline/1-tables/1-Dictionary.sql
$PSQL -c 'drop table "FieldPermission"'
$PSQL -f baseline/3-dictionaries/8-FieldPermission.sql
$PSQL -f baseline/3-dictionaries/24-SynCarMake.sql
$PSQL -f baseline/3-dictionaries/25-SynCarModel.sql
