#!/bin/bash
# Author: baiyitong
# baiyitong@hotmail.com

[ ! $(id -u) -eq 0 ]  && exit 1

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

cd $(dirname $(readlink -f $0 ))
source config.env

function make_directory(){
  [ ! -d ${apps_root} ] || rm -fr ${apps_root}
  [ ! -d ${data_root} ] || rm -fr ${data_root}
  [ ! -d ${logs_root} ] || rm -fr ${logs_root}
  [ ! -d ${pkgs_root} ] || rm -fr ${pkgs_root}

  mkdir -p ${apps_root} ${logs_root} ${data_root} ${pkgs_root}
}


basedir=${apps_root}/mysql-${mysql_version}.${mysql_subversion}-el7-x86_64
logsdir=${logs_root}/mysql-${mysql_version}.${mysql_subversion}-el7-x86_64
datadir=${data_root}/mysql-${mysql_version}.${mysql_subversion}-el7-x86_64

function get_packages(){
  cd ${pkgs_root}
  ls mysql-${mysql_version}.${mysql_subversion}-el7-x86_64.tar.gz  || \
    wget https://cdn.mysql.com/archives/mysql-${mysql_version}/mysql-${mysql_version}.${mysql_subversion}-el7-x86_64.tar.gz
  tar zxvf mysql-${mysql_version}.${mysql_subversion}-el7-x86_64.tar.gz -C ${apps_root}
}

function reset_configuration(){
  envsubst < my.cnf.tempalte > ${basedir}/conf/my.cnf
  envsubst < mysqld.service.template > /usr/lib/systemd/system/mysqld.service
  envsubst < conn_to_local_mysq.sh.template > ${basedir}/conn_to_local_mysql.sh
}

function init_database(){
  ./bin/mysql_install_db --defaults-file=conf/my.cnf --basedir=${basedir} --datadir=${datadir}  --insecure
}

function reset_mysql_root_password(){
  mysql_root_old_password=$(grep 'temporary password' ${logsdir}/mysqld.log | awk '{print $11}')
  mysql_root_new_password=${root_password}

  #mysqladmin -uroot -p"${mysql_root_old_password}" -S ${datadir}/mysql.sock password "${mysql_root_new_password}"
  mysql -uroot -p"${root_password}" -S ${datadir}/mysql.sock  <<EOF
ALTER USER 'root'@'localhost' PASSWORD EXPIRE NEVER;
FLUSH PRIVILEGES;
CREATE DATABASE ${user_database} DEFAULT CHARACTER SET utf8;
GRANT ALL PRIVILEGES ON ${user_database}.* TO '${user_name}'@'%' IDENTIFIED BY '${user_password}' WITH GRANT OPTION;
EOF
}




