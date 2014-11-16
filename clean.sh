#!/bin/bash

for i in bcpc-{bootstrap,vm{1..3}} ; do
  VBoxManage controlvm $i poweroff
  VBoxManage unregistervm $i --delete
done

#TODO: figure out where vbox VM state directory is and blow that away
