#!/bin/bash

HD="/Users/heron/Desktop/QEMU/openstep42.img"
CD="/Users/heron/Desktop/QEMU/OPENSTEP_4.2_User.iso"
FD="/Users/heron/Desktop/QEMU/4.2_Install_Disk.img"

# qemu-system-sparc \
#   -machine SS-20 \
#   -m 256 \
#   -hda ${HD} \
#   -cdrom ${CD} \
#   -boot d \
#   -g 1024x768x8

qemu-system-sparc \
  -M SS-5 \
  -m 128 \
  -drive file=${HD},format=raw,bus=0,unit=0,if=scsi,cache=writeback \
  -cdrom ${CD} \
  -net nic \
  -boot d \
  -g 1024x768x8
