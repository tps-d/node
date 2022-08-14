#!/bin/bash

############################
##  Methods
############################

usage() {
    echo ""
    echo -e "SYNOPSIS\n  $0 [OPTION] [STRING]\nDESCRIPTION\n  -a  要执行的命令 \n  -i  ip字符串\n  \nEXAMPLES\n  $0 -a ping -i 192.168.0.1/24\n  $0 -a nmap -i 192.168.0.1/24 10.10.0.0/28\n"
    exit
}

ip_valid() {
  # Set up local variables
  local ip=${1:-1.2.3.4}
  local IFS=.; local -a a=($ip)
  # Start with a regex format test
  [[ $ip =~ ^[0-9]+(\.[0-9]+){3}$ ]] || return 1
  # Test values of quads
  local quad
  for quad in {0..3}; do
    [[ "${a[$quad]}" -gt 255 ]] && return 1
  done
  return 0
}

netmask_valid() {

    IP_MASK=$1

    IP=`echo $IP_MASK |sed -En 's/^(.*)\/([0-9]{1,2})/\1/p'`
    NET_MASK=`echo $IP_MASK |sed -En 's/^(.*)\/([0-9]{1,2})/\2/p'`

    [[ -z $IP || -z $NET_MASK ]] && return 1

    if [[ $IP =~ ^(([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$ ]];then
        #netmask should be in 0-32
        [ $NET_MASK -gt 32 -o $NET_MASK -lt 0 ] && return 1

        return 0
    else
        return 1
    fi
}

network_address_to_ips() {
  # create array containing network address and subnet
  local network=(${1//\// })
  # split network address by dot
  local iparr=(${network[0]//./ })
  # if no mask given it's the same as /32
  local mask=32
  [[ $((${#network[@]})) -gt 1 ]] && mask=${network[1]}

  # convert dot-notation subnet mask or convert CIDR to an array like (255 255 255 0)
  local maskarr
  if [[ ${mask} =~ '.' ]]; then  # already mask format like 255.255.255.0
    maskarr=(${mask//./ })
  else                           # assume CIDR like /24, convert to mask
    if [[ $((mask)) -lt 8 ]]; then
      maskarr=($((256-2**(8-mask))) 0 0 0)
    elif  [[ $((mask)) -lt 16 ]]; then
      maskarr=(255 $((256-2**(16-mask))) 0 0)
    elif  [[ $((mask)) -lt 24 ]]; then
      maskarr=(255 255 $((256-2**(24-mask))) 0)
    elif [[ $((mask)) -lt 32 ]]; then
      maskarr=(255 255 255 $((256-2**(32-mask))))
    elif [[ ${mask} == 32 ]]; then
      maskarr=(255 255 255 255)
    fi
  fi

  # correct wrong subnet masks (e.g. 240.192.255.0 to 255.255.255.0)
  [[ ${maskarr[2]} == 255 ]] && maskarr[1]=255
  [[ ${maskarr[1]} == 255 ]] && maskarr[0]=255

  # generate list of ip addresses
  local bytes=(0 0 0 0)
  for i in $(seq 0 $((255-maskarr[0]))); do
    bytes[0]="$(( i+(iparr[0] & maskarr[0]) ))"
    for j in $(seq 0 $((255-maskarr[1]))); do
      bytes[1]="$(( j+(iparr[1] & maskarr[1]) ))"
      for k in $(seq 0 $((255-maskarr[2]))); do
        bytes[2]="$(( k+(iparr[2] & maskarr[2]) ))"
        for l in $(seq 1 $((255-maskarr[3]))); do
          bytes[3]="$(( l+(iparr[3] & maskarr[3]) ))"
          printf "%d.%d.%d.%d " "${bytes[@]}"
        done
      done
    done
  done
}

#######################
##  MAIN
#######################

declare -a all_ip_address

OPTIND=1;

while getopts ":i:a:" o; do
    case "${o}" in
        i)
            INPUT=${OPTARG}
            ;;
        a)
            ACTION=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${INPUT}" ] || [ -z "${ACTION}" ]; then
    usage
fi

lines=($INPUT)

for ip in ${lines[@]}; do

    if ip_valid "$ip"; then
        all_ip_address=("${all_ip_address[@]}" $ip)
    elif netmask_valid "$ip"; then
        
        network_ips=($(network_address_to_ips $ip))
        #echo ${network_ips[*]}
        all_ip_address=("${all_ip_address[@]}" "${network_ips[@]}")
    else
        echo "unknow ip $ip"
        continue
    fi

done

# 去重
all_ip_address=($(awk -v RS=' ' '!a[$1]++' <<< ${all_ip_address[@]}))


#执行命令
case $ACTION in
    ping)
        COMMAND=""
        for ip in ${all_ip_address[@]}
        do {
            ping -c1 -s1 $ip 2>&1 1>/dev/null &&
            echo -e ping -c 2 $ip is "\033[32;49;1m online！ \033[39;49;0m" || 
            echo -e ping -c 2 $ip is "\033[31;49;1m offline！ \033[39;49;0m"
        } &
        done
        wait
        ;;
    nmap)
        for ip in ${all_ip_address[@]}
        do {
            eval nmap -c 20 \$ip
        } &
        done
        wait
        ;;
    *)
        echo "unknow action"
        ;;
esac
