#!/bin/bash

# See https://www.kernel.org/doc/Documentation/vm/ksm.txt

disable_ksm_merge_across_nodes () {
    echo 0 > /sys/kernel/mm/ksm/merge_across_nodes
}

start_ksm () {
    disable_ksm_merge_across_nodes
    echo 1 > /sys/kernel/mm/ksm/run
    exit 0
}

stop_ksm () {
    echo 2 > /sys/kernel/mm/ksm/run
}

restart_ksm () {
    stop_ksm
    start_ksm
}

# Start ksm if not already running
grep -q -e 0 -e 2 /sys/kernel/mm/ksm/run && start_ksm

# If ksm is already running, unmerge, disable, and restart ksm
grep -q 1 /sys/kernel/mm/ksm/run && grep -q 1 /sys/kernel/mm/ksm/merge_across_nodes && restart_ksm
