#!/usr/bin/env bash

### Script To Generate CIS Report and Copy the Report to S3 Bucket ###



### Variable Declarations ###
SERVER=`/usr/bin/wget -q -O - http://169.254.169.254/latest/meta-data/instance-id`
REGION=`/usr/bin/wget -qO- http://169.254.169.254/latest/meta-data/placement/availability-zone | rev | cut -c 2- | rev`
VPCID=`/usr/bin/sudo /usr/bin/aws ec2 describe-instances --instance-id $SERVER --region $REGION | grep VpcId | head -1 | cut -d "\"" -f 4`
VPCNAME=`/usr/bin/sudo /usr/bin/aws ec2 describe-vpcs --vpc-ids $VPCID --region $REGION | grep -B 1 Name | head -1 | awk -F':' '{print $2}' | cut -d "\"" -f 2`
ACCNAME=`aws iam list-account-aliases --region $REGION | sed -n '3p' | awk '{print $1}' | cut -d "\"" -f 2`

LOGDIR="/var/log/cisreports"
SSH_KEY="/cloudops/scripts/sme-cloud.pem"
ERROR_FILE="/tmp/error"
EXE_SCRIPT="/tmp/app_cis_rep_gen.sh"
CIS_DIR="/cloudops/cis-cat-full"
CIS_SCRIPT="/cloudops/cis-cat-full/CIS-CAT.sh"
CIS_BENCH="/cloudops/cis-cat-full/benchmarks/CIS_Amazon_Linux_Benchmark_v2.0.0-xccdf.xml"
ENV="/bin/sh"
HOST_FILE="/cloudops/hosts"

### SSH Connection Try ###
ssh_con_check(){
	ssh  -i ${SSH_KEY} -o StrictHostKeyChecking=no -o ConnectTimeout=2 ec2-user@${HST} "ls ${CIS_DIR} >/dev/null" 2>${ERROR_FILE}
	EXIT_CODE=$?
	ERROR=`tail -n -1 ${ERROR_FILE} | awk '{print $2}'`
}


### Copying CIS Directory to Server ###
#sync_cis_dir(){
#	if [[ ${ERROR} == 'cannot' ]]; then
#		rsync -a -e "ssh -i ${SSH_KEY}" ${CIS_DIR} ec2-user@${HST}:${CIS_DIR}
#		ssh -q -i ${SSH_KEY} -o StrictHostKeyChecking=no ec2-user@${HST} < ${EXE_SCRIPT}
#		scp -q -i ${SSH_KEY} -o StrictHostKeyChecking=no ec2-user@${HST}:${LOGDIR}/* ${LOGDIR}
#	fi
#}


### Report Generating Script ###
cis_gen(){
	cat > ${EXE_SCRIPT} << END
	sudo rm -rf ${LOGDIR}
	sudo mkdir -p ${LOGDIR}
	cd ${CIS_DIR}
	sudo ${ENV} ${CIS_SCRIPT} -a -b ${CIS_BENCH} -r ${LOGDIR} >/dev/null
	sudo chmod -R 755 ${LOGDIR}
END
}

### Generating CIS Report of APP Servers ###
app_server_report(){
	for HST in `cat ${HOST_FILE}`; do
		ssh_con_check
		if [[ $EXIT_CODE -eq 0 ]]; then
			ssh -q -i ${SSH_KEY} -o StrictHostKeyChecking=no ec2-user@${HST} < ${EXE_SCRIPT}
			scp -q -i ${SSH_KEY} -o StrictHostKeyChecking=no ec2-user@${HST}:${LOGDIR}/* ${LOGDIR} 
		fi			
	done
	sudo rm -rf ${EXE_SCRIPT}	

}

bast_server_report(){
	${ENV} ${EXE_SCRIPT}
}


report_gen(){
	FILES=`ls ${LOGDIR}`
	sudo mkdir -p ${LOGDIR}/report
	for NAME in ${FILES}; do
		ServerName=`awk 'NR==372' ${LOGDIR}/${NAME} | cut -d "/" -f 2 | cut -c 6- | cut -d "<" -f 1`
		Percentage=`awk 'NR==843' ${LOGDIR}/${NAME} | cut -d ">" -f 2 | cut -d "%" -f 1 `
		echo ${ServerName}:${Percentage} >> ${LOGDIR}/report/report.${VPCID}
		echo -e "$ServerName,$ACCNAME,$VPCNAME,$REGION,$Percentage\t" >> ${LOGDIR}/report/cisreport.${VPCNAME}
	done
	#awk -F ':' '{ if ($2 < 90) print $2,"   "$1;}' ${LOGDIR}/report.${VPCID} >> ${LOGDIR}/cisreport.${VPCNAME}-below-90
}



cis_gen
bast_server_report
app_server_report
report_gen


