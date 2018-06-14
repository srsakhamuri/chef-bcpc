#!/bin/bash

echo 0 > /sys/kernel/mm/ksm/merge_across_nodes 2>/dev/null && exit 0
# That didn't work. Let's unmerge, disable, and restart ksm
# See https://www.kernel.org/doc/Documentation/vm/ksm.txt
echo 2 > /sys/kernel/mm/ksm/run
echo 0 > /sys/kernel/mm/ksm/merge_across_nodes
echo 1 > /sys/kernel/mm/ksm/run
