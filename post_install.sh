#!/bin/sh

mysqlroot=$(openssl rand -base64 15)
guacamole_password=$(openssl rand -base64 15)

pkg install -y guacamole-server
pkg install -y guacamole-client
pkg install -y mysql80-server
pkg install -y mysql-connector-java


echo 'guacd_enable="YES"' >> /etc/rc.conf
echo 'tomcat9_enable="YES"' >> /etc/rc.conf
echo 'mysql_enable="YES"' >> /etc/rc.conf

mkdir /usr/local/etc/guacamole-client/lib
mkdir /usr/local/etc/guacamole-client/extensions

cp /usr/local/share/java/classes/mysql-connector-java.jar /usr/local/etc/guacamole-client/lib

tar xvfz /usr/local/share/guacamole-client/guacamole-auth-jdbc.tar.gz -C /tmp/

cp /tmp/guacamole-auth-jdbc-*/mysql/*.jar /usr/local/etc/guacamole-client/extensions

cp /usr/local/etc/guacamole-server/guacd.conf.sample /usr/local/etc/guacamole-server/guacd.conf

cp /usr/local/etc/guacamole-client/logback.xml.sample /usr/local/etc/guacamole-client/logback.xml

cp /usr/local/etc/guacamole-client/guacamole.properties.sample /usr/local/etc/guacamole-client/guacamole.properties

echo "mysql-hostname: localhost" >> /usr/local/etc/guacamole-client/guacamole.properties
echo "mysql-port:     3306" >> /usr/local/etc/guacamole-client/guacamole.properties
echo "mysql-database: guacamole_db" >> /usr/local/etc/guacamole-client/guacamole.properties
echo "mysql-username: guacamole_user" >> /usr/local/etc/guacamole-client/guacamole.properties
echo "mysql-password: $guacamole_password" >> /usr/local/etc/guacamole-client/guacamole.properties

service mysql-server start

mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${mysqlroot}';CREATE DATABASE guacamole_db;CREATE USER 'guacamole_user'@'localhost' IDENTIFIED BY '${guacamole_password}';GRANT SELECT,INSERT,UPDATE,DELETE ON guacamole_db.* TO 'guacamole_user'@'localhost';FLUSH PRIVILEGES;";


cat /tmp/guacamole-auth-jdbc-*/mysql/schema/*.sql | mysql -u root -p"${mysqlroot}" guacamole_db


service mysql-server restart
service guacd restart
service tomcat9 restart

echo "$mysqlroot"
echo "$guacamole_password"

echo
cat <<EOF > /root/PLUGIN_INFO
#---------------------------------------------------------------------#
# Getting started with the AdGuard Home plugin
#---------------------------------------------------------------------#
AdGuard Home is a network-wide software for blocking ads & tracking. 
After you set it up, it'll cover ALL your home devices, 
and you don't need any client-side software for that.
Source: https://github.com/AdguardTeam/AdGuardHome
 
The default user for the Admin Portal is "admin" with password "admin"
MySQL Username: root
MySQL Password: "$mysqlroot"
Guacamole DB User: guacamole_user
Guacamole DB Password: "$guacamole_password"

EOF



