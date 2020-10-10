#!/bin/bash

root_password=""
admin_password=""

#Place where you want to preserved backup.
OUTPUT="."

TIMESTAMP=`date +%Y-%m-%d_%H-%M-%S`;
mkdir $OUTPUT/$TIMESTAMP;
cd $OUTPUT/$TIMESTAMP;
echo "Starting MySQL Backup";
echo 'date';
databases=$(mysql -u root -p$root_password -N -e "SHOW DATABASES;" | tr -d "| " | grep -Ev "(Database|information_schema|performance_schema|mysql)");

echo $databases;

for db in $databases; do
    mysqldump --force --opt -u root -p$root_password --databases $db > $OUTPUT/dbbackup-$TIMESTAMP-$db.sql
    gzip $OUTPUT/dbbackup-$TIMESTAMP-$db.sql
done

users=$(mysql -u root -p$root_password -N -e "SELECT User FROM mysql.db" | tr -d "| ")

echo "" > $OUTPUT/dbusers-$TIMESTAMP-mysql.sql

for u in $users; do
    cols=($(mysql -u root -p$root_password -N -e "SELECT Host, Db FROM mysql.db WHERE User = '$u'" | tr -d "| "))
    cat <<EOF>> $OUTPUT/dbusers-$TIMESTAMP-mysql.sql
# Create database \`${cols[1]}\` and grant privileges for \`$u\`
CREATE DATABASE ${cols[1]} COLLATE utf8_general_ci;
CREATE USER '$u'@'${cols[0]}' IDENTIFIED BY '1234567890';
GRANT ALL PRIVILEGES ON ${cols[1]} . * TO '$u'@'${cols[0]}';
FLUSH PRIVILEGES;


EOF
done

echo "Finished MySQL Backup";
echo 'date';

mariadb_version="10.4"
centmin_url="https://raw.githubusercontent.com/centminmod/centminmod/master"
low_ram='262144' # 256MB

server_ram_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)

# Install MariaDB Repo 10.4
cat > /etc/yum.repos.d/MariaDB.repo <<EOF
# MariaDB $mariadb_version CentOS repository list - created `date +"%F %R"` UTC
# http://downloads.mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/$mariadb_version/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF

yum -y remove mysql* MariaDB*

yum -y install MariaDB-server MariaDB-client

systemctl enable mariadb.service
systemctl start mysql.service

ulimit -n 262144

cp /etc/my.cnf /etc/my.cnf-original

if [[ "$(expr $server_ram_total \<= 2099000)" = "1" ]]; then
	# echo -e "\nCopying MariaDB my-mdb10-min.cnf file to /etc/my.cnf\n"
	wget -q $centmin_url/config/mysql/my-mdb10-min.cnf -O /etc/my.cnf
fi

if [[ "$(expr $server_ram_total \> 2100001)" = "1" && "$(expr $server_ram_total \<= 4190000)" = "1" ]]; then
	# echo -e "\nCopying MariaDB my-mdb10.cnf file to /etc/my.cnf\n"
	wget -q $centmin_url/config/mysql/my-mdb10.cnf -O /etc/my.cnf
fi

if [[ "$(expr $server_ram_total \>= 4190001)" = "1" && "$(expr $server_ram_total \<= 8199999)" = "1" ]]; then
	# echo -e "\nCopying MariaDB my-mdb10-4gb.cnf file to /etc/my.cnf\n"
	wget -q $centmin_url/config/mysql/my-mdb10-4gb.cnf -O /etc/my.cnf
fi

if [[ "$(expr $server_ram_total \>= 8200000)" = "1" && "$(expr $server_ram_total \<= 15999999)" = "1" ]]; then
	# echo -e "\nCopying MariaDB my-mdb10-8gb.cnf file to /etc/my.cnf\n"
	wget -q $centmin_url/config/mysql/my-mdb10-8gb.cnf -O /etc/my.cnf
fi

if [[ "$(expr $server_ram_total \>= 16000000)" = "1" && "$(expr $server_ram_total \<= 31999999)" = "1" ]]; then
	# echo -e "\nCopying MariaDB my-mdb10-16gb.cnf file to /etc/my.cnf\n"
	wget -q $centmin_url/config/mysql/my-mdb10-16gb.cnf -O /etc/my.cnf
fi

if [[ "$(expr $server_ram_total \>= 32000000)" = "1" ]]; then
	# echo -e "\nCopying MariaDB my-mdb10-32gb.cnf file to /etc/my.cnf\n"
	wget -q $centmin_url/config/mysql/my-mdb10-32gb.cnf -O /etc/my.cnf
fi

sed -i "s/\/var\/lib\/mysql\/slowq.log/\/home\/$server_name\/logs\/mysql-slow.log/g" /etc/my.cnf
sed -i "s/\/var\/log\/mysqld.log/\/home\/$server_name\/logs\/mysql.log/g" /etc/my.cnf
sed -i "s/tmpdir=\/home\/mysqltmp//g" /etc/my.cnf

rm -f /var/lib/mysql/ib_logfile0
rm -f /var/lib/mysql/ib_logfile1
rm -f /var/lib/mysql/ibdata1

sleep 1

'/usr/bin/mysqladmin' -u root password "$root_password"
mysql -u root -p"$root_password" -e "GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost' IDENTIFIED BY '$admin_password' WITH GRANT OPTION;"
mysql -u root -p"$root_password" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost')"
mysql -u root -p"$root_password" -e "DELETE FROM mysql.user WHERE User=''"
mysql -u root -p"$root_password" -e "DROP User '';"
mysql -u root -p"$root_password" -e "DROP DATABASE test"
mysql -u root -p"$root_password" -e "FLUSH PRIVILEGES"

cat > "/root/.my.cnf" <<END
[client]
user=root
password=$root_password
END
chmod 600 /root/.my.cnf

cat > "/etc/logrotate.d/mysql" <<END
/home/*/logs/mysql*.log {
        create 640 mysql mysql
        notifempty
        daily
        rotate 3
        maxage 7
        missingok
        compress
        postrotate
        # just if mysqld is really running
        if test -x /usr/bin/mysqladmin && \
           /usr/bin/mysqladmin ping &>/dev/null
        then
           /usr/bin/mysqladmin flush-logs
        fi
        endscript
	su mysql mysql
}
END
