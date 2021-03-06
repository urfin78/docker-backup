#!/bin/bash
set -o errexit
set -o nounset
DATE=$(date +"%Y%m%d-%H%M%S")
TARGETDIR='.'
PREPAREENV=''
for CONTAINER in $(docker ps --format '{{.ID}}'); do
	ENVDATA=$(docker inspect --format '{{.Config.Env}}' "${CONTAINER}")
	if echo "${ENVDATA}"|grep -qoE 'MYSQL_DATABASE(|_FILE)=.*'; then
		DB=$(echo "${ENVDATA}"|grep -oE 'MYSQL_DATABASE(|_FILE)=.*'|sed -E 's/^MYSQL_DATABASE(|_FILE)=([^ ]+).*/\2/')
		DBUSER=$(echo "${ENVDATA}"|grep -oE 'MYSQL_USER(|_FILE)=.*'|sed -E 's/^MYSQL_USER(|_FILE)=([^ ]+).*/\2/')
		DBPW=$(echo "${ENVDATA}"|grep -oE 'MYSQL_PASSWORD(|_FILE)=.*'|sed -E 's/^MYSQL_PASSWORD(|_FILE)=([^ ]+).*/\2/') 
		if echo "${ENVDATA}"|grep -qoE 'MYSQL_DATABASE_FILE'; then
			#shellcheck disable=SC2016
			PREPAREENV+='DB=$(cat '${DB}');'
			DBASE=$(docker exec "${CONTAINER}" /bin/bash -c ''"${PREPAREENV}"' echo ${DB}')
		else
			PREPAREENV+='DB='${DB}';'
			DBASE="${DB}"
		fi
		if echo "${ENVDATA}"|grep -qoE 'MYSQL_USER_FILE'; then
			#shellcheck disable=SC2016
			PREPAREENV+='DBUSER=$(cat '${DBUSER}');'
		else
			PREPAREENV+='DBUSER='${DBUSER}';'
		fi
		if echo "${ENVDATA}"|grep -qoE 'MYSQL_PASSWORD_FILE'; then
			#shellcheck disable=SC2016
			PREPAREENV+='DBPW=$(cat'" ${DBPW}"'); '
		else
			PREPAREENV+='DBPW='${DBPW}';'
		fi

		docker exec "${CONTAINER}" /bin/bash -c ''"${PREPAREENV}"' mysqldump --single-transaction -n -c -e --hex-blob -R -u ${DBUSER} -p${DBPW} ${DB}' | gzip -9 -c > "${TARGETDIR}"/"${DBASE}"-"${DATE}".sql.gz
		PREPAREENV=''
	fi 
done
