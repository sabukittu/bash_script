#!/usr/bin/env bash

arg=$1

file_check() {
  if [[ -e /cloudops/hosts ]]; then
    hosts=`cat /cloudops/hosts`
    echo -e "\n${hosts}\n"
  else
    echo "/cloudops/hosts file not found"
    exit 1
  fi
}

input_check() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: $0 'check' or 'execute'"
  fi
}

main_fun() {
  if [[ ${arg} == 'check' ]]; then
    read -p 'Enter the username: ' user
    echo -e "\n Bastion: `id ${user} 2>/dev/null`\n"
    for mac in ${hosts}; do
      echo -n " ${mac}:  "
      ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no ${mac} "id ${user}" 2>/tmp/error
      if [[ ! $? -eq 0 ]]; then
        echo -en "\e[31m`tail -n 1 /tmp/error`\e[0m\n" && rm -rf /tmp/error
      fi
    done
    echo ""
  elif [[ ${arg} == 'execute' ]]; then
    read -p 'Enter the username: ' user
    sudo userdel -r ${user}
    for mac in ${hosts}; do
      ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no ${mac} "sudo userdel -r ${user}" 2>/dev/null
    done
  else
    input_check
  fi
}

file_check
main_fun
