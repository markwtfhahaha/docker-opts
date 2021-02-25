### 宿主机创建数据目录添加权限，以便容器能够正常创建文件和目录
```
chown 54321:54322 data/ && chown 54321:54321 exp_dir/
scripts目录可以不加权限,把相关脚本放进去
```

### 生成镜像命令和打补丁命令,提前把19c安装包和补丁包放置到对应目录,镜像已经提前打包到我们私有仓库
```
已经打包好的镜像为docker-harbor.clubs999.com/public/oracle/database:19.3.0-ee-patch-v1, 可以直接使用，不必重新打包

#生成镜像: oracle/database:19.3.0-ee
cd  dockerfiles
./buildContainerImage.sh  -v 19.3.0 -e
#生成镜像: oracle/database:19.3.0-ee-patch
cd applypatch-19.3
./buildPatchedDockerImage.sh -v 19.3.0 -e -p patch

select description, status from DBA_REGISTRY_SQLPATCH;
#打完补丁后可以把docker-compose文件里面的镜像改成新的，如果已经初始化建库，建议删掉，重建，这样新建的库不会有一些版本问题
```

### 可以手动开启归档,闪回，设置SAG,PGA，以及db_recovery_file;自动清理归档脚本已经自动添加好，可以手动验证下
```
shutdown immediate;
startup mount;
alter database archivelog;
archive log list;

alter system set db_recovery_file_dest_size = 100G; #自行设置合适的大小
alter system set db_recovery_file_dest='/opt/oracle/oradata/fast_recovery_area'; #目录为固定位置，会进行docker持久化
show parameter db_recover;

alter database flashback on;
alter database open ;

alter database force logging;
select force_logging from v$database;

#docker-compose里面设置的sga,pga只在第一次启动建库的时候生效,后期可以更改
alter system set pga_aggregate_target=10G scope=spfile; 
alter system set sga_max_size=40G scope=spfile; 
alter system set sga_target=40G scope=spfile;
show parameter sga;
show parameter pga;
shutdown immediate;
startup;
```
### 创建用户,数据文件示例,密码也为示例,自己请务必更换自定义密码
```
create tablespace op_tbs datafile '/opt/oracle/oradata/ORA19C/op_tbs01.dbf' size 2000m autoextend on next 200m maxsize 20000m;
alter tablespace op_tbs add datafile '/opt/oracle/oradata/ORA19C/op_tbs02.dbf' size 2000m autoextend on next 2000m maxsize 20000m;
alter tablespace op_tbs add datafile '/opt/oracle/oradata/ORA19C/op_tbs03.dbf' size 2000m autoextend on next 2000m maxsize 20000m;
alter tablespace op_tbs add datafile '/opt/oracle/oradata/ORA19C/op_tbs04.dbf' size 2000m autoextend on next 2000m maxsize 20000m;
alter tablespace op_tbs add datafile '/opt/oracle/oradata/ORA19C/op_tbs05.dbf' size 2000m autoextend on next 2000m maxsize 20000m;
......

create user ora19c identified by O4bkVHCHI0Wb8h2H default tablespace op_tbs;
grant connect,resource to ora19c;
create directory exp_dir as '/home/oracle/exp_dir';
Grant read,write on directory exp_dir to ora19c;
alter user ora19c account unlock ;
ALTER USER ora19c QUOTA unlimited ON op_tbs;

expdp ora19c/O4bkVHCHI0Wb8h2H schemas=ora19c directory=exp_dir dumpfile=test20200101.dmp
impdp ora19c/O4bkVHCHI0Wb8h2H  remap_schema=ora19c:ora19c directory=exp_dir  dumpfile=test20200101.dump full=y

drop user ora19c cascade; #删除用户及数据

```
### 一主一从配置,做完以上操作即可完成单实例部署，其他参数可以自行定义
```
1. 启动主数据库
注意: 删除备库上面的库
dbca -silent -deleteDatabase -sourcedb ora19cdb

shutdown immediate
startup mount
alter system enable restricted session;
drop database;

2. 两个实例分别定义四大配置文件 data/dbconfig/ORA19C/
listener.ora sqlnet.ora tnsnames.ora init${ORACLE_SID}.ora
从主库拷贝orapw文件到备库

3. 创建redo和standbyredo数据文件
select group#,thread#,bytes/1024/1024 M ,STATUS from v$log;
select * from v$logfile;
alter database add logfile thread 1 group 4 ('/opt/oracle/oradata/ORA19C/redo04.log') size 2000M;
alter database add logfile thread 1 group 5 ('/opt/oracle/oradata/ORA19C/redo05.log') size 2000M;
alter database add logfile thread 1 group 6 ('/opt/oracle/oradata/ORA19C/redo06.log') size 2000M;
alter database add logfile thread 1 group 7 ('/opt/oracle/oradata/ORA19C/redo07.log') size 2000M;

添加standby日志
alter database add standby logfile thread 1 group 21 ('/opt/oracle/oradata/ORA19C/standbyredo21.log') size 2000M;
alter database add standby logfile thread 1 group 22 ('/opt/oracle/oradata/ORA19C/standbyredo22.log') size 2000M;
alter database add standby logfile thread 1 group 23 ('/opt/oracle/oradata/ORA19C/standbyredo23.log') size 2000M;
alter database add standby logfile thread 1 group 24 ('/opt/oracle/oradata/ORA19C/standbyredo24.log') size 2000M;
alter database add standby logfile thread 1 group 25 ('/opt/oracle/oradata/ORA19C/standbyredo25.log') size 2000M;

4. 主库应用pfile配置文件创建spfile
shutdown immediate;
exit;
create spfile='/opt/oracle/oradata/dbconfig/ORA19C/spfileORA19C.ora' from pfile;
startup;

5.备库应用pfile配置文件创建spfile
mkdir /opt/oracle/oradata/admin/ORA19C/adump -p

create spfile='/opt/oracle/oradata/dbconfig/ORA19CDB/spfileORA19CDB.ora' from pfile;
startup nomount;

6. 连接测试
tnsping ora19c;tnsping ora19cdb
sqlplus sys/O4bkVHCHI0Wb8h2H@ora19c as sysdba
sqlplus sys/O4bkVHCHI0Wb8h2H@ora19cdb as sysdba

7. 传数据,主库执行
rman target sys/O4bkVHCHI0Wb8h2H@ora19c auxiliary sys/O4bkVHCHI0Wb8h2H@ora19cdb nocatalog
RMAN>  duplicate target database for standby nofilenamecheck from active database;

8. 在从库开启日志应用并启动数据库
alter database recover managed standby database disconnect nodelay;
alter database recover managed standby database cancel;
alter database open read only;
alter database recover managed standby database disconnect nodelay;


9. 查询状态
select SEQUENCE#,FIRST_TIME,NEXT_TIME ,APPLIED from v$archived_log order by 1;
select database_role,db_unique_name,open_mode,protection_mode,protection_level,switchover_status from v$database; 
```

### 注意!!!!
```
1. 重启集群时，务必先shutdown immediate 关闭，然后重建docker容器，顺序为先主后从
2. 建议实例名库名都不要改变，若要在同一台服务器新建新的实例，直接新建容器，修改映射端口既可，这样主从部署极为简单，不必修改过多配置文件，只需要修改tns配置即可
3. create spfile='/opt/oracle/oradata/dbconfig/ORA19C/spfileORA19C.ora' from pfile; 生成spfile请务必使用这个命令，指定spfile路径，避免spfile软链被覆盖掉
```
