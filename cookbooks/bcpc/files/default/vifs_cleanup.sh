#!/bin/bash

# cleans up stale virtual interfaces from nova-network tables
# (otherwise nova-network restarts can take a very long time)
mysql -e "USE nova; CREATE TABLE IF NOT EXISTS virtual_interfaces_archive LIKE virtual_interfaces; START TRANSACTION; INSERT virtual_interfaces_archive SELECT * FROM virtual_interfaces WHERE deleted > 0 AND instance_uuid NOT IN (SELECT uuid FROM instances WHERE deleted = 0); DELETE FROM virtual_interfaces WHERE id IN (SELECT id FROM virtual_interfaces_archive); COMMIT;"
