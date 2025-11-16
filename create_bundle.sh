#!/bin/sh

# Replace values accordingly
COMPUTER_NAME=`hostname`
MAC_ADDRESS=$(ifconfig en0 | awk '/ether/{print $2}' | sed 's/://g' | grep -v autoselect)
SPARSEBUNDLE_NAME="${COMPUTER_NAME}_${MAC_ADDRESS}.sparsebundle"
SIZE="3t"


# Create sparsebundle on Desktop (change size as needed)
hdiutil create -size $SIZE -fs HFS+J -type SPARSEBUNDLE -volname "Time Machine" ./$SPARSEBUNDLE_NAME
