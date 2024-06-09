#!/bin/bash

# Function to display usage information
usage() {
    echo "Usage: $0 [-signal] process_name"
    echo "       $0 process_name"
    exit 1
}

# Check if no arguments are provided
if [ $# -eq 0 ]; then
    usage
fi

# Check if the first argument is a signal
if [[ $1 == -* ]]; then
    SIGNAL=$1
    shift
else
    SIGNAL="-TERM"
fi

# Check if process name is provided
if [ $# -eq 0 ]; then
    usage
fi

PROCESS_NAME=$1
PROCESSES=`ps auxwww | grep $PROCESS_NAME | awk '{print $2}'`

# Loop through all processes and kill the ones with the specified name
for PID in $PROCESSES 
do
    kill $SIGNAL $PID
    if [ $? -eq 0 ]; then
        echo "Killed $PROCESS_NAME with PID $PID"
    else
        echo "Failed to kill $PROCESS_NAME with PID $PID"
    fi
done

exit 0