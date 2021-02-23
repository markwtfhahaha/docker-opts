#!/bin/bash
sqlplus / as sysdba << EOF
    ALTER PROFILE DEFAULT LIMIT PASSWORD_LIFE_TIME UNLIMITED;
    exit;
EOF
