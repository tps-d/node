#!/bin/sh

echo "======== docker containers logs file size ========" >>/root/run.log

logs=$(find /var/lib/docker/containers/ -name *-json.log)  

for log in $logs  
        do  
             du -b $log
        done
echo "======== start clean docker containers logs ========"  >>/root/run.log

logs=$(find /var/lib/docker/containers/ -name *-json.log)  

for log in $logs  
        do  
                echo "clean logs : $log"  
                cat /dev/null > $log  
        done  

echo "======== end clean docker containers logs ========" >>/root/run.log
cat /root/run.log
