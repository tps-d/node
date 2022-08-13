#!/bin/sh
read -p "enter mode:" mode
time=$(date "+%Y-%m-%d %H:%M:%S")

###clear
if [ "$mode" -eq "clear" ]; then
echo "$time check docker containers logs file size " >>/root/run.log
logs=$(find /var/lib/docker/containers/ -name *-json.log)  
for log in $logs  
        do 
             du -b $log
        done
echo "$time start clean docker containers logs"  >>/root/run.log
logs=$(find /var/lib/docker/containers/ -name *-json.log)  
for log in $logs  
        do  
                echo "clean logs : $log"  
                cat /dev/null > $log  
        done
echo "$time end clean docker containers logs" >>/root/run.log
cat /root/run.log
fi 
####ping
if [ "$mode" -eq "ping" ]; then
   read -p "enter ip:" ip
   echo "$ip"


fi
tail -n 50 /root/run.log
