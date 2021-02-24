#!/bin/bash
DATE=$(date +"%Y%m%d-%H%M%S")
TARGETDIR='.'
PREPARENV=''
for CONTAINER in $(docker ps --format '{{.ID}}'); do
	ENVDATA=$(docker inspect --format '{{.Config.Env}}' ${CONTAINER})
	if [[ "$(echo ${ENVDATA}|grep -oE 'MYSQL_DATABASE(|_FILE)=.*')" ]]; then
		DB="$(echo ${ENVDATA}|grep -oE 'MYSQL_DATABASE(|_FILE)=.*'|sed -E 's/^MYSQL_DATABASE(|_FILE)=([^ ]+).*/\2/')"
		DBUSER=$(echo ${ENVDATA}|grep -oE 'MYSQL_USER(|_FILE)=.*'|sed -E 's/^MYSQL_USER(|_FILE)=([^ ]+).*/\2/')
		DBPW=$(echo ${ENVDATA}|grep -oE 'MYSQL_PASSWORD(|_FILE)=.*'|sed -E 's/^MYSQL_PASSWORD(|_FILE)=([^ ]+).*/\2/') 
		if [[ "$(echo ${ENVDATA}|grep -oE 'MYSQL_DATABASE_FILE')" ]]; then
			PREPAREENV+='DB=$(cat '${DB}');'
			DBASE="$(docker exec -it ${CONTAINER} /bin/bash -c ''"${PREPAREENV}"' echo ${DB}')"
		else
			PREPAREENV+='DB='${DB}';'
			DBASE="${DB}"
		fi
		if [[ "$(echo ${ENVDATA}|grep -oE 'MYSQL_USER_FILE')" ]]; then
			PREPAREENV+='DBUSER=$(cat '${DBUSER}');'
		else
			PREPAREENV+='DBUSER='${DBUSER}';'
		fi
		if [[ "$(echo ${ENVDATA}|grep -oE 'MYSQL_PASSWORD_FILE')" ]]; then
			PREPAREENV+='DBPW=$(cat'" ${DBPW}"'); '
		else
			PREPAREENV+='DBPW='${DBPW}';'
		fi

		docker exec -it ${CONTAINER} /bin/bash -c ''"${PREPAREENV}"' mysqldump --single-transaction -n -c -e --hex-blob -R -u ${DBUSER} -p${DBPW} ${DB}' | bzip2 -c > ${TARGETDIR}/${DBASE}-${DATE}.sql.bz2
		PREPAREENV=''
	fi 
done
