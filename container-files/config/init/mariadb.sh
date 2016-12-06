#!/bin/bash
DATADIR="/var/lib/mysql"
tempSqlFile='/tmp/mysql-first-time.sql'
if [ ! -d "$DATADIR/mysql" ]; then
	if [ -z "$MYSQL_ROOT_PASSWORD" -a -z "$MYSQL_ALLOW_EMPTY_PASSWORD" ]; then
		echo >&2 'error: database is uninitialized and MYSQL_ROOT_PASSWORD not set'
		echo >&2 '  Did you forget to add -e MYSQL_ROOT_PASSWORD=... ?'
		exit 1
	fi
        
	echo 'Running mysql_install_db ...'
	mysql_install_db --datadir="$DATADIR"
	echo 'Finished mysql_install_db'
		
	# These statements _must_ be on individual lines, and _must_ end with
	# semicolons (no line breaks or comments are permitted).
	# TODO proper SQL escaping on ALL the things D:
	
	cat > "$tempSqlFile" <<-EOSQL
		DELETE FROM mysql.user ;
		CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;
		GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION ;
		DROP DATABASE IF EXISTS test ;
	EOSQL
        set +u
        for i in {1..10}
	do
        MY_DB=MYSQL_DATABASE$i
        MY_USER=MYSQL_USER$i
	MY_PW=MYSQL_PASSWORD$i
        echo "${!MY_DB}"
	if [ "${!MY_DB}" ]; then
		echo "CREATE DATABASE IF NOT EXISTS \`${!MY_DB}\` ;" >> "$tempSqlFile"
	fi
		
	if [ "${!MY_USER}" -a "${!MY_PW}" ]; then
		echo "CREATE USER '${!MY_USER}'@'%' IDENTIFIED BY '${!MY_PW}' ;" >> "$tempSqlFile"
		
		if [ "${!MY_DB}" ]; then
			echo "GRANT ALL ON \`${!MY_DB}\`.* TO '${!MY_USER}'@'%' ;" >> "$tempSqlFile"
		fi
	fi
	done	
        set -u
	echo 'FLUSH PRIVILEGES ;' >> "$tempSqlFile"
fi
chown -R mysql:mysql $DATADIR
/usr/bin/mysqld_safe --user=mysql --datadir=/var/lib/mysql &
sleep 2
mysql -uroot < "$tempSqlFile"
mysqladmin -uroot -p${MYSQL_ROOT_PASSWORD} shutdown
rm -f "$tempSqlFile"
