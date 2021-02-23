### 宿主机创建数据目录添加权限，以便容器能够正常创建文件和目录
```
chown 54321:54322 data/ && chown 54321:54321 exp_dir/
scripts目录可以不加权限
```

### 生成镜像命令和打补丁命令,提前把19c安装包和补丁包放置到对应目录
```
#生成镜像: oracle/database:19.3.0-ee
cd  dockerfiles
./buildContainerImage.sh  -v 19.3.0 -e
#生成镜像: oracle/database:19.3.0-ee-patch
cd applypatch-19.3
./buildPatchedDockerImage.sh -v 19.3.0 -e -p patch

select description, status from DBA_REGISTRY_SQLPATCH;
#打完补丁后可以把docker-compose文件里面的镜像改成新的，如果已经初始化建库，建议删掉，重建，这样新建的库不会有一些版本问题
```

### 可以手动开启归档,闪回，设置SAG,PGA，以及db_recovery_file;自动清理归档脚本自动添加好，可以手动验证下
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
create tablespace op_tbs datafile '/opt/oracle/oradata/MARKTEST/op_tbs01.dbf' size 2000m autoextend on next 200m maxsize 20000m;
alter tablespace op_tbs add datafile '/opt/oracle/oradata/MARKTEST/op_tbs02.dbf' size 2000m autoextend on next 2000m maxsize 20000m;
alter tablespace op_tbs add datafile '/opt/oracle/oradata/MARKTEST/op_tbs03.dbf' size 2000m autoextend on next 2000m maxsize 20000m;
alter tablespace op_tbs add datafile '/opt/oracle/oradata/MARKTEST/op_tbs04.dbf' size 2000m autoextend on next 2000m maxsize 20000m;
alter tablespace op_tbs add datafile '/opt/oracle/oradata/MARKTEST/op_tbs05.dbf' size 2000m autoextend on next 2000m maxsize 20000m;
......

create user marktest identified by O4bkVHCHI0Wb8h2H default tablespace op_tbs;
grant connect,resource to marktest;
create directory exp_dir as '/home/oracle/exp_dir';
Grant read,write on directory exp_dir to marktest;
alter user marktest account unlock ;
ALTER USER marktest QUOTA unlimited ON op_tbs;

expdp marktest/O4bkVHCHI0Wb8h2H schemas=marktest directory=exp_dir dumpfile=test20200101.dmp
impdp marktest/O4bkVHCHI0Wb8h2H  remap_schema=marktest:marktest directory=exp_dir  dumpfile=test20200101.dump full=y

drop user marktest cascade; #删除用户及数据

```

