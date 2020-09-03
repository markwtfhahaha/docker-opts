#!/bin/bash
#java jboss工程更新脚本#

if [ $# -ne 1 ]
then
    echo "Usage: "
    echo "    sh update_project.sh projectname"
    exit 1
fi

project=$1  #工程名
#statichtml配置,主要用于CDN访问
htmlstaticip=172.16.10.153
htmlstaticdir=/home/www/html

standalonedir=/home/opts
ftpdir=/home/opts/base-vsftpd/data/ftpuser/test  

getmark() {
    echo "************************************************************************************************************************"
}

#生成yml文件
getmark
cd /home/opts
echo "$project" yaml----------
./getxmlresult yml $project
getmark
echo "$project" nginx proxy----------
./getxmlresult nginx $project

datedir=`date +%Y%m%d`
javaname=`./getxmlresult xml $project | awk -F "|" '{print $2}'`
ips=`./getxmlresult xml $project | awk -F "|" '{print $4}'`
p_type=`./getxmlresult xml $project | awk -F "|" '{print $3}'`


getmark

if [ "$p_type" == "jboss" ]
then
    i=0
    for ip in `echo $ips | awk -F "," '{for( i=1; i<=NF; i++) print $i}'`
    do
        srcdir=$ftpdir/$ip/jboss/$project/$datedir  #源目录
        destdir=/home/opts/$project  #目标目录
        echo "拷贝工程:$project/$javaname"
        echo "源目录: $srcdir"
        echo "目标目录: $destdir"
        
        #执行更新拷贝并且重启容器
        echo "执行更新拷贝并且重启容器,$ip"
        ansible $ip -m shell -a "ls $destdir || mkdir -p $destdir"
        ansible $ip -m synchronize -a "src=$standalonedir/standalone.conf dest=$destdir/standalone.conf"
        ansible $ip -m synchronize -a "src=$srcdir/$javaname dest=$destdir/$javaname"
        
        
        if [ $i == 0 ]
        then
            echo "Restarting container: $project""_wildfly_1"
            ansible $ip -m shell -a "docker restart $project'_wildfly_1'"
        else
            echo "Restarting container: $project$i""_wildfly_1"
            ansible $ip -m shell -a "docker restart $project$i'_wildfly_1'"
        fi
        i=$[$i+1]
        getmark
    done
fi
if [ "$p_type" == "jar" ]
then
    i=0
    for ip in `echo $ips | awk -F "," '{for( i=1; i<=NF; i++) print $i}'`
    do
        srcdir=$ftpdir/$ip/java/$project/$datedir  #源目录
        destdir=/home/opts/$project  #目标目录
        echo "拷贝工程:$project/$javaname"
        echo "源目录: $srcdir"
        echo "目标目录: $destdir"
    
        #执行更新拷贝并且重启容器
        echo "执行更新拷贝并且重启容器,$ip"
        ansible $ip -m shell -a "ls $destdir || mkdir -p $destdir"
        ansible $ip -m shell -a "rm -fr $destdir/*"
        ansible $ip -m synchronize -a "src=$srcdir/$javaname dest=$destdir/$javaname"
        if [ $i == 0 ]
        then
            echo "Restarting container: $project""_wildfly_1"
            ansible $ip -m shell -a "docker restart $project'_wildfly_1'"
        else
            echo "Restarting container: $project$i""_wildfly_1"
            ansible $ip -m shell -a "docker restart $project$i'_wildfly_1'"
        fi
        i=$[$i+1]
        getmark
    done
fi
if [ "$p_type" == "target.zip" ]
then
    i=0
    for ip in `echo $ips | awk -F "," '{for( i=1; i<=NF; i++) print $i}'`
    do
        srcdir=$ftpdir/$ip/java/$project/$datedir  #源目录
        destdir=/home/opts/$project  #目标目录
        echo "拷贝工程:$project/$javaname"
        echo "源目录: $srcdir"
        echo "目标目录: $destdir"
    
        #执行更新拷贝并且重启容器
        echo "执行更新拷贝并且重启容器,$ip"
        ansible $ip -m shell -a "ls $destdir || mkdir -p $destdir"
        ansible $ip -m shell -a "rm -fr $destdir/*"
        ansible $ip -m copy -a "src=$srcdir/target.zip dest=$destdir/target.zip"
        ansible $ip -m shell -a "cd $destdir && unzip target.zip"
        if [ $i == 0 ]
        then
            echo "Restarting container: $project""_wildfly_1"
            ansible $ip -m shell -a "docker restart $project'_wildfly_1'"
        else
            echo "Restarting container: $project$i""_wildfly_1"
            ansible $ip -m shell -a "docker restart $project$i'_wildfly_1'"
        fi
        i=$[$i+1]
        getmark
    done
fi
if [ "$p_type" == "html" ]
then
    i=0
    for ip in `echo $ips | awk -F "," '{for( i=1; i<=NF; i++) print $i}'`
    do
        srcdir=$ftpdir/html/$project/$datedir  #源目录
        destdir=/home/opts/$project  #目标目录
        echo "拷贝静态代码:$project"
        echo "源目录: $srcdir"
        echo "目标目录: $destdir"

        #执行更新拷贝
        echo "执行更新拷贝 $ip"
        ansible $ip -m shell -a "ls $destdir || mkdir -p $destdir"
        ansible $ip -m synchronize -a "src=$srcdir/ dest=$destdir/"
        #更新到statichtml,相当于总配置
        echo "更新到statichtml,相当于总配置 $htmlstaticip"
        ansible $htmlstaticip -m shell -a "ls $htmlstaticdir/$project || mkdir -p $htmlstaticdir/$project"
        ansible $htmlstaticip -m synchronize -a "src=$srcdir/ dest=$htmlstaticdir/$project/ delete=yes"
        ansible $htmlstaticip -m file -a "dest=$htmlstaticdir owner=nginx group=nginx recurse=yes"

        i=$[$i+1]
        getmark
    done
fi
getmark