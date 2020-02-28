#!/bin/bash

echo '' > a.txt
echo -e "\"IPAddress\",\"Hits\"" > result.txt

if [[ $# -eq 2 ]]; then

	b=$(find $1 -type f | xargs zgrep index | awk '{print $4}' | tee b.txt)

	for x in $b ; do

		err=$(grep $x a.txt)
		echo $x >> a.txt

		if [ -z "$err" ] ; then

			echo added_$x
			sleep 1
			echo "\"$x\",\"$(grep $x b.txt | wc -w)\"" >> result.txt
			
		fi

	done
	
	declare -i i=$(sed '1,1d' result.txt | wc -l)
	echo -e "\"Total IP's - $i\",\"=SUM(B2:B$[ $i + 1 ])\"" >> result.txt
	cp result.txt ~/Desktop/IP_Hits\("$2"\).csv
	rm -rf a.txt b.txt result.txt

else 

	echo "Usage : $0 <LOG_DIR> <DATE>"

fi
