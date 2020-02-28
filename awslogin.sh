#!/bin/bash

ENV="$1"
NAME="$2"
ACCEPTED_ENVS=( dev qa prod )
is_valid_env=0

for i in "${ACCEPTED_ENVS[@]}"
do
  if [ "$i" == "$ENV" ]; then
    is_valid_env=1
    break
  fi
done

if [ $is_valid_env -ne 1 ]; then
  echo "Invalid environment"
  exit
fi

echo -e "Found matches for: $ENV-$NAME"

tsh_error=$(tsh ls 2>&1 | awk '{print $3}')

if [[ $tsh_error == 'oidc' ]] || [[ $tsh_error == 'proxy' ]]; then
  tsh login --proxy=teleport.aetnd.com --auth=centrify 
  sleep 2
fi

servers_found=$( tsh ls | grep $ENV-$NAME )

server_ips=()
server_names=()

if [ "$servers_found" != "" ]; then

  i=0

  #servers_found could be mutiple lines of output. parse and save to arrays
  while IFS= read -r line;
  do
    server_ip=$( echo $line | cut -d ' ' -f 1 );
    server_ips+=($server_ip);
    server_name=$( echo $line | cut -d ' ' -f 4 | cut -d ',' -f 2 );
    server_names+=($server_name);
    echo "($i) $server_ip";
    let "i++";
  done <<< "$servers_found"

  name_picked=${server_names[0]}
  name_picked=$( echo $name_picked | cut -d '[' -f 1 | cut -d '=' -f 2 )

  if [ ${#server_ips[@]} -gt 1 ]; then
    echo "Enter a number from the list above to login into: $name_picked"

    #prompt user
    read userchoice
  else
    echo "Stack found: $name_picked"

    #auto-login if only 1 choice
    userchoice=0
  fi

  server_picked=${server_ips[$userchoice]}
  server_picked=$( echo $server_picked | cut -d '[' -f 1 )

  login=root@$server_picked

  echo "Logging in as: $login"

  tsh ssh $login

else
  
  echo "Not found"

fi
