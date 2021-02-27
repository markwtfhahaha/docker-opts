#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
# 
# Since: November, 2016
# Author: gerald.venzl@oracle.com
# Description: Creates an Oracle Database based on following parameters:
#              $ORACLE_SID: The Oracle SID and CDB name
#              $ORACLE_PDB: The PDB name
#              $ORACLE_PWD: The Oracle password
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

set -e

# Check whether ORACLE_SID is passed on
export ORACLE_SID=${1:-ORCLCDB}

# Check whether ORACLE_PDB is passed on
#export ORACLE_PDB=${2:-ORCLPDB1}
export ORACLE_UNQNAME=${2:-ORCLPDB}

# Auto generate ORACLE PWD if not passed on
export ORACLE_PWD=${3:-"`openssl rand -base64 8`1"}
echo "ORACLE PASSWORD FOR SYS, SYSTEM AND PDBADMIN: $ORACLE_PWD";

# Replace place holders in response file
cp $ORACLE_BASE/$CONFIG_RSP $ORACLE_BASE/dbca.rsp
sed -i -e "s|###ORACLE_SID###|$ORACLE_SID|g" $ORACLE_BASE/dbca.rsp
#sed -i -e "s|###ORACLE_PDB###|$ORACLE_PDB|g" $ORACLE_BASE/dbca.rsp
sed -i -e "s|###ORACLE_PWD###|$ORACLE_PWD|g" $ORACLE_BASE/dbca.rsp
sed -i -e "s|###ORACLE_CHARACTERSET###|$ORACLE_CHARACTERSET|g" $ORACLE_BASE/dbca.rsp

# Replace oracle .bash_profile
mv /home/oracle/.bash_profile /home/oracle/.bash_profile.bak
cp $ORACLE_BASE/$ORACLE_BASH_PROFILE /home/oracle/.bash_profile
sed -i -e "s|###ORACLE_SID###|$ORACLE_SID|g" /home/oracle/.bash_profile
sed -i -e "s|###ORACLE_UNQNAME###|$ORACLE_UNQNAME|g" /home/oracle/.bash_profile
sed -i -e "s|###ORACLE_HOSTNAME###|$ORACLE_HOSTNAME|g" /home/oracle/.bash_profile

# If there is greater than 8 CPUs default back to dbca memory calculations
# dbca will automatically pick 40% of available memory for Oracle DB
# The minimum of 2G is for small environments to guarantee that Oracle has enough memory to function
# However, bigger environment can and should use more of the available memory
# This is due to Github Issue #307
if [ `nproc` -gt 8 ]; then
   sed -i -e "s|totalMemory=2048||g" $ORACLE_BASE/dbca.rsp
fi;

# Create network related config files (sqlnet.ora, tnsnames.ora, listener.ora)
mkdir -p $ORACLE_HOME/network/admin
echo "NAME.DIRECTORY_PATH= (TNSNAMES, EZCONNECT, HOSTNAME)" > $ORACLE_HOME/network/admin/sqlnet.ora

# Listener.ora
echo "LISTENER = 
(DESCRIPTION_LIST = 
  (DESCRIPTION = 
    (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1)) 
    (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521)) 
  ) 
) 

DEDICATED_THROUGH_BROKER_LISTENER=ON
DIAG_ADR_ENABLED = off
" > $ORACLE_HOME/network/admin/listener.ora

# Start LISTENER and run DBCA
lsnrctl start &&
dbca -silent -createDatabase -responseFile $ORACLE_BASE/dbca.rsp ||
 cat /opt/oracle/cfgtoollogs/dbca/$ORACLE_SID/$ORACLE_SID.log ||
 cat /opt/oracle/cfgtoollogs/dbca/$ORACLE_SID.log

echo "$ORACLE_SID=localhost:1521/$ORACLE_SID" > $ORACLE_HOME/network/admin/tnsnames.ora
echo "$ORACLE_PDB= 
  (DESCRIPTION = 
    (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = $ORACLE_PDB)
    )
  )" >> $ORACLE_HOME/network/admin/tnsnames.ora

# Remove second control file, fix local_listener, make PDB auto open, enable EM global port
sqlplus / as sysdba << EOF
   ALTER SYSTEM SET control_files='$ORACLE_BASE/oradata/$ORACLE_SID/control01.ctl' scope=spfile;
   ALTER SYSTEM SET local_listener='';
   ALTER PLUGGABLE DATABASE $ORACLE_PDB SAVE STATE;
   EXEC DBMS_XDB_CONFIG.SETGLOBALPORTENABLED (TRUE);
   exit;
EOF

# Remove temporary response file
mv $ORACLE_BASE/dbca.rsp $ORACLE_BASE/dbca.rsp.bak

if [ ! -d "$ORACLE_BASE/oradata/admin/$ORACLE_SID/adump" ]; then
  mkdir $ORACLE_BASE/oradata/admin/$ORACLE_SID/adump -p
fi
if [ ! -d "$ORACLE_BASE/oradata/fast_recovery_area" ]; then
  mkdir $ORACLE_BASE/oradata/fast_recovery_area -p
fi

