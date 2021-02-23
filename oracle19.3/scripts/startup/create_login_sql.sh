#!/bin/bash
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
