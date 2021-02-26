#!/bin/bash
sqlplus / as sysdba << EOF
    exec DBMS_AUTO_TASK_ADMIN.ENABLE();
    exec DBMS_AUTO_TASK_ADMIN.ENABLE(client_name => 'auto optimizer stats collection',operation =>'auto optimizer stats job',window_name=> null);
    exec DBMS_AUTO_TASK_ADMIN.ENABLE(client_name => 'auto optimizer stats collection',operation => NULL,window_name => NULL);
    exit;
EOF
