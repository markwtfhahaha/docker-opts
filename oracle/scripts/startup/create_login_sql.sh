#!/bin/bash
cat >> /home/u01/app/oracle/product/19c/dbhome_1/sqlplus/admin/glogin.sql << EOF 
define _editor=vi
set serveroutput on size 1000000
set trimspool on
set long 5000
set linesize 1000
set pagesize 9999
column plan_plus_exp format a80
column global_name new_value gname
set termout off
define gname=idle
column global_name new_value gname
select lower(user) ||'@'|| substr(global_name,1,decode(dot,0,length(global_name),dot-1)) global_name
from (select global_name,instr(global_name,'.') dot from global_name);
set sqlprompt '&gname>'
set termout on
EOF
