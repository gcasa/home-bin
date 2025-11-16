#!/bin/bash

HD="/Users/heron/hda.img"
CD="/Users/heron/Desktop/OPENSTEP_4.2_User.iso"
FD="/Users/heron/Desktop/4.2_Install_Disk.img"

qemu-system-i386 \
  -M pc \
  -cpu 486 \
  -m 64 \
  -vga cirrus \
  -drive file=${FD},if=floppy,format=raw \
  -blockdev driver=file,node-name=diskfile,filename=${HD} \
  -device ide-hd,drive=diskfile,unit=0,cyls=1024,heads=16,secs=63 \
  -drive file=${CD},media=cdrom,if=ide,unit=1 \
  -boot a
