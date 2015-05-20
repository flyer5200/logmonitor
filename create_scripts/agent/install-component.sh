#!/bin/bash

DOWNLOAD_SERVER=http://10.0.0.213

JAVA_VERSION=1.7.0_80

MY_IP=$(hostname -I | awk '{print $1}')

REDIS_SERVER=112.74.64.178
REDIS_SERVER_PORT=6379

INSTALL_PATH=/opt/logmonitor

LOGSTASH_PATH=${INSTALL_PATH}/logstash-1.5.0
LOGSTASH_CONFIG_PATH=${LOGSTASH_PATH}/conf
LOGSTASH_CONFIG_FILE=${LOGSTASH_CONFIG_PATH}/agent.conf
LOGSTASH_STDOUT=${LOGSTASH_PATH}/logs/stdout.log


downloadArchive(){
   ! test -d ${INSTALL_PATH} && mkdir -p ${INSTALL_PATH}
   ! test -f ${INSTALL_PATH}/logstash.tar.gz && wget http://10.0.0.213/cloud_repository/logmonitor/archives/logstash-1.5.0.tar.gz -O ${INSTALL_PATH}/logstash.tar.gz
}

uncompression(){
	cd ${INSTALL_PATH}
	tar -vxzf ${INSTALL_PATH}/logstash.tar.gz
}

replaceDefaultConfig(){
	! test -d ${LOGSTASH_CONFIG_PATH} && mkdir -p ${LOGSTASH_CONFIG_PATH}
	! test -d ${LOGSTASH_PATH}/logs && mkdir -p ${LOGSTASH_PATH}/logs

	if [ ! -f ${LOGSTASH_CONFIG_FILE} ]; then

		cat >${LOGSTASH_CONFIG_FILE}<<-EOF

 		input {
		       	file {
					type => "type_count"
					path => ["/opt/bin/apache-tomcat-8.0.22/logs/catalina.out"]
         			sincedb_path => "${INSTALL_PATH}/logstash-1.5.0/sincedb-access"
					exclude => ["*.txt"]
				} 
		}

		output {
			stdout {}
			redis {
				host => "${REDIS_SERVER}"
				port => ${REDIS_SERVER_PORT}
				data_type => "list"
				key => "erongdu_logmonitor"
			}   
		}
		EOF
	fi
}


create-logstash-service(){
	cat <<-EOF >/usr/lib/systemd/system/logstash.service
		[Unit]
		Description=logstash Service
		Requires=network.service

		[Service]
		ExecStart=${LOGSTASH_PATH}/bin/logstash agent --verbose --config ${LOGSTASH_CONFIG_FILE} --log ${LOGSTASH_STDOUT}
		Restart=on-failure
	
		[Install]
		WantedBy=multi-user.target
	EOF

	systemctl daemon-reload
	systemctl stop logstash
	systemctl enable logstash
	systemctl start logstash
}

#check java is available in this session
function hasJava {
    v=`java -version 2>&1`

    echo 'check java platform...'

    pos=`expr match "$v" 'java version \"${JAVA_VERSION}\"'`
    if [ $pos -gt 0 ]
    then
	return 1
    else
	return 0
    fi
}

installService(){
  hasJava
  r=$?

  if [ $r -eq 1 ]; then
	echo "java was installed"
  else
	wget ${DOWNLOAD_SERVER}/cloud_repository/logmonitor/archives/jre-7u80-linux-x64.rpm
	rpm -ivh jre-7u80-linux-x64.rpm
  fi
  
  create-logstash-service
}


downloadArchive

uncompression

replaceDefaultConfig

installService
