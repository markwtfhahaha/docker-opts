#!/bin/bash

###添加计划任务
mkdir /home/oracle/sh/ -p

cat >> /home/oracle/sh/${ORACLE_SID}_archive_del.sh << EOF 
#!/bin/bash
ORACLE_SID=$ORACLE_SID; export ORACLE_SID
ORACLE_UNQNAME=$ORACLE_UNQNAME; export ORACLE_UNQNAME
JAVA_HOME=/usr/java; export JAVA_HOME
ORACLE_BASE=/opt/oracle; export ORACLE_BASE
ORACLE_HOME=\$ORACLE_BASE/product/19c/dbhome_1; export ORACLE_HOME
ORACLE_PATH=/home/u01/app/common/oracle/sql; export ORACLE_PATH
ORACLE_TERM=xterm; export ORACLE_TERM
NLS_DATE_FORMAT="YYYY-MM-DD HH24:MI:SS"; export NLS_DATE_FORMAT
TNS_ADMIN=\$ORACLE_HOME/network/admin; export TNS_ADMIN
ORA_NLS11=\$ORACLE_HOME/nls/data; export ORA_NLS11
PATH=.:\${JAVA_HOME}/bin:\${PATH}:\$HOME/bin:\$ORACLE_HOME/bin
PATH=\${PATH}:/usr/bin:/bin:/usr/bin/X11:/usr/local/bin
PATH=\${PATH}:/home/u01/app/common/oracle/bin
export PATH
LD_LIBRARY_PATH=\$ORACLE_HOME/lib
LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:\$ORACLE_HOME/oracm/lib
LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/lib:/usr/lib:/usr/local/lib
export LD_LIBRARY_PATH
CLASSPATH=\$ORACLE_HOME/JRE
CLASSPATH=\${CLASSPATH}:\$ORACLE_HOME/jlib
CLASSPATH=\${CLASSPATH}:\$ORACLE_HOME/rdbms/jlib
CLASSPATH=\${CLASSPATH}:\$ORACLE_HOME/network/jlib
export CLASSPATH
THREADS_FLAG=native; export THREADS_FLAG
export TEMP=/tmp
export TMPDIR=/tmp
export NLS_LANG=AMERICAN_AMERICA.AL32UTF8
umask 022
###################### DELETE NOPROMPT force ARCHIVELOG ALL COMPLETED BEFORE 'SYSDATE-7';##########
rman target /  log=/home/oracle/sh/log/${ORACLE_SID}_archive_del.log append  <<EOF1
run {
CROSSCHECK archivelog all;
CONFIGURE ARCHIVELOG DELETION POLICY TO APPLIED ON ALL STANDBY;
DELETE NOPROMPT force ARCHIVELOG ALL COMPLETED BEFORE 'SYSDATE-5';
}

EOF1

EOF


cd /home/oracle
echo "1 6 * * * /home/oracle/sh/${ORACLE_SID}_archive_del.sh" > cron.txt
crontab cron.txt
rm cron.txt -f

mkdir /home/oracle/sh/log/
touch /home/oracle/sh/log/${ORACLE_SID}_archive_del.log
chmod +x /home/oracle/sh/${ORACLE_SID}_archive_del.sh

sudo crond #启动计划任务


###开启自动收集统计信息
sqlplus / as sysdba << EOF
    exec DBMS_AUTO_TASK_ADMIN.ENABLE();
    exec DBMS_AUTO_TASK_ADMIN.ENABLE(client_name => 'auto optimizer stats collection',operation =>'auto optimizer stats job',window_name=> null);
    exec DBMS_AUTO_TASK_ADMIN.ENABLE(client_name => 'auto optimizer stats collection',operation => NULL,window_name => NULL);
    exit;
EOF

###创建login.sql
cat >> /home/u01/app/oracle/product/19c/dbhome_1/sqlplus/admin/glogin.sql << EOF 
define _editor=vi
set serveroutput on size 1000000
set trimspool on
set long  5000
set linesize  1000
set pagesize  9999
column plan_plus_exp format a80
set sqlprompt '&_user.@&_connect_identifier.>'
EOF

###密码不过期
sqlplus / as sysdba << EOF
    ALTER PROFILE DEFAULT LIMIT PASSWORD_LIFE_TIME UNLIMITED;
    exit;
EOF