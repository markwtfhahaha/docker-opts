主
CREATE USER 'admin'@'%' IDENTIFIED BY 'pass';
GRANT REPLICATION SLAVE, REPLICATION CLIENT ON . TO 'admin'@'%';
show master status;



备
change master to master_host='192.168.100.90', master_user='admin',
master_password='pass', master_port=3306, master_log_file='mysql-bin.000004', master_log_pos=617, master_connect_retry=30;
start slave;
show slave status \G;



验证
create database test1;
show databases;