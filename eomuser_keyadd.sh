#!/usr/bin/env bash

mac=$1
usr=$2
eom_users=`sudo cat /etc/passwd |grep '2017' | awk '{print $1}'`
eom_users_app=`ssh ${mac} "sudo cat /etc/passwd |grep '2017'" 2>/dev/null`


for x in ${eom_users}; do
  echo -ne "\e[32m"
  echo  "${eom_users_app}" | grep "$x"
  error="$?"
  echo -ne "\e[0m"
  if [[ $error -ne 0 ]]; then
     echo -ne "\e[31m"
     echo $x
     echo -ne "\e[0m"
  fi
done


if [[ -z ${usr} ]]; then
	echo "User input is Null"
else
	sudo ls /home/${usr}/.ssh/id_rsa.pub &>/dev/null
	err=$?
	if [[ ${err} -eq 0 ]]; then
		sudo bash -c "scp -i /home/nand006/.ssh/id_rsa /home/${usr}/.ssh/id_rsa.pub nand006@${mac}:/tmp/${usr}" 2>/dev/null
		ssh ${mac} "sudo cp -rf /home/${usr}/.ssh/authorized_keys /tmp/${usr}_authorized_keys && sudo bash -c 'cat /tmp/${usr} >> /home/${usr}/.ssh/authorized_keys'" 2>/dev/null
	else
		echo "Public Key Not Found"
		sleep 5s
		sudo su - ${usr}
	fi
fi


