#!/bin/bash

export TN_STAGING=3310
export TN_SREC=3309
export TN_TR=3308
export TN_DW=3307
function start_tunnels {
PIDS=$(ps -eaf | grep autossh | grep -v grep | awk '{print $2}')
if [[ "$PIDS" != "" ]]; then kill -9 $PIDS; fi


autossh -N -f -M 0 \
-L ${TN_SREC}:olap.srecs.solsystems.com:3306 readonly@t.solsystems.com \
-L ${TN_TR}:olap.tr.solsystems.com:3306 readonly@t.solsystems.com \
-L ${TN_DW}:olap.dw.solsystems.com:3306 readonly@t.solsystems.com \
-L ${TN_STAGING}:srec-platform-staging.ctnwxbtxzctl.us-east-1.rds.amazonaws.com:3306 staging.srecs.solsystems.com


echo "OK"
}

start_tunnels
