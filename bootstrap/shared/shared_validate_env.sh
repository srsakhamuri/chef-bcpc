#!/bin/bash
NEEDED_PROGRAMS=( curl git rsync ssh )
FAILED=0
for binary in "${NEEDED_PROGRAMS[@]}"; do
  if ! which "$binary" >/dev/null; then
    FAILED=1
    echo "ERROR: Unable to locate $binary in this environment's PATH." >&2
  fi
done

if [[ $FAILED != 0 ]]; then
  printf "
       Please see above error output to determine which program(s) you may
       need to install or expose into this environment's PATH. Aborting.\n" >&2
  exit 1
fi

