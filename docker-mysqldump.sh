#!/bin/bash
DATE=$(date -I)
for CONTAINER in $(docker ps --format '{{.ID}}'); do
 DB=$(docker inspect --format '{{.Config.Env}}' ${CONTAINER}|grep -oE 'MYSQL_DATABASE=.*'|sed -E 's/^MYSQL_DATABASE=([^ ]+).*/\1/')
 if [ -n "${DB}" ]; then
 	DBPW=$(docker inspect --format '{{.Config.Env}}' ${CONTAINER}|grep -oE 'MYSQL_PASSWORD_FILE=.*'|sed -E 's/^MYSQL_PASSWORD_FILE=([^ ]+).*/\1/')
	DBUSER=$(docker inspect --format '{{.Config.Env}}' ${CONTAINER}|grep -oE 'MYSQL_USER=.*'|sed -E 's/^MYSQL_USER=([^ ]+).*/\1/')
	 echo "${DB} ${DBPW}:"
	docker exec -it ${CONTAINER} /bin/bash -c 'PW=$(cat '${DBPW}'); mysqldump -u '${DBUSER}' -p${PW} '${DB}'' > ${DB}-${DATE}.sql
fi 
done
