#!/bin/bash
set -o errexit
set -o nounset

function backup_volume {
exit
}

#Variables
BACKUPDIR="$(pwd)/backup"
RUNNING_CONTAINER=( $(docker ps --format {{.ID}}) )

for CONTAINER in ${RUNNING_CONTAINER[@]}
do

    CONTAINER_NAME=$(docker ps --filter ID=${CONTAINER} --format '{{.Names}}')
    IFS=',' read -ra VOLUMES <<< $(docker ps --filter ID=${CONTAINER} --format '{{.Mounts}}' --no-trunc)
    for VOLUME in ${VOLUMES[@]}
    do
        echo "${CONTAINER_NAME}-${VOLUME}"
    done
done
