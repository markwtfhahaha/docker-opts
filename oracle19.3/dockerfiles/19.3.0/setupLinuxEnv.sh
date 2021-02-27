#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
#
# Since: December, 2016
# Author: gerald.venzl@oracle.com
# Description: Sets up the unix environment for DB installation.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

# Setup filesystem and oracle user
# Adjust file permissions, go to /opt/oracle as user 'oracle' to proceed with Oracle installation
# ------------------------------------------------------------
mkdir -p $ORACLE_BASE/scripts/setup && \
mkdir $ORACLE_BASE/scripts/startup && \
ln -s $ORACLE_BASE/scripts /docker-entrypoint-initdb.d && \
mkdir $ORACLE_BASE/oradata && \
mkdir -p $ORACLE_HOME && \
chmod ug+x $ORACLE_BASE/*.sh && \
yum -y install oracle-database-preinstall-19c openssl vim vi sudo && \
rm -rf /var/cache/yum && \
ln -s $ORACLE_BASE/$PWD_FILE /home/oracle/ && \
echo oracle:oracle | chpasswd && \
chown -R oracle:dba $ORACLE_BASE


# Replace oracle .bash_profile
#mv /home/oracle/.bash_profile /home/oracle/.bash_profile.bak
#cp $ORACLE_BASE/$ORACLE_BASH_PROFILE /home/oracle/.bash_profile
#sed -i -e "s|###ORACLE_SID###|$ORACLE_SID|g" /home/oracle/.bash_profile
#sed -i -e "s|###ORACLE_UNQNAME###|$ORACLE_UNQNAME|g" /home/oracle/.bash_profile
#sed -i -e "s|###ORACLE_HOSTNAME###|$ORACLE_HOSTNAME|g" /home/oracle/.bash_profile
