#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
#
# Since: November, 2016
# Author: gerald.venzl@oracle.com
# Description: Starts the Listener and Oracle Database.
#              The ORACLE_HOME and the PATH has to be set.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 


# Check whether ORACLE_SID is passed on
export ORACLE_SID=${1:-ORCLCDB}

# Check whether ORACLE_PDB is passed on
#export ORACLE_PDB=${2:-ORCLPDB1}
export ORACLE_UNQNAME=${2:-ORCLPDB}

#
export ORACLE_HOSTNAME=${4:-oracle19c}


# Replace oracle .bash_profile
mv /home/oracle/.bash_profile /home/oracle/.bash_profile.bak
cp $ORACLE_BASE/$ORACLE_BASH_PROFILE /home/oracle/.bash_profile
sed -i -e "s|###ORACLE_SID###|$ORACLE_SID|g" /home/oracle/.bash_profile
sed -i -e "s|###ORACLE_UNQNAME###|$ORACLE_UNQNAME|g" /home/oracle/.bash_profile
sed -i -e "s|###ORACLE_HOSTNAME###|$ORACLE_HOSTNAME|g" /home/oracle/.bash_profile

# Check that ORACLE_HOME is set
if [ "$ORACLE_HOME" == "" ]; then
  script_name=`basename "$0"`
  echo "$script_name: ERROR - ORACLE_HOME is not set. Please set ORACLE_HOME and PATH before invoking this script."
  exit 1;
fi;

# Start Listener
lsnrctl start

# Start database
sqlplus / as sysdba << EOF
   STARTUP;
   exit;
EOF

if [ ! -d "$ORACLE_BASE/oradata/admin/$ORACLE_SID/adump" ]; then
  mkdir $ORACLE_BASE/oradata/admin/$ORACLE_SID/adump -p
fi
if [ ! -d "$ORACLE_BASE/oradata/fast_recovery_area" ]; then
  mkdir $ORACLE_BASE/oradata/fast_recovery_area -p
fi
