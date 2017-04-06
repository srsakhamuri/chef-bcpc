#!/bin/bash

SLAVES="`cat /usr/local/etc/dns-update-slaves`"
COND=

# Name of zone to update. If empty, all zones will be updated.
ZONE=$1

# If zone argument is non-empty, apply SQL conditional clause
test -n "$ZONE" && COND="WHERE name = '$ZONE'"

mysql --defaults-file=/etc/mysql/debian.cnf -N -s -D pdns -e \
"SELECT name FROM domains $COND" | \
while read zone; do
  pdnssec increase-serial $zone || exit 1
  for slave in $SLAVES; do
    pdns_control notify-host $zone $slave >/dev/null 2>&1 || exit 1
  done
done
