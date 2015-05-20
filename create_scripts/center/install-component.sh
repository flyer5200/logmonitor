#!/bin/bash

MY_IP=$(hostname -I | awk '{print $1}')

REDIS_SERVER=112.74.64.178
REDIS_SERVER_PORT=6379

INSTALL_PATH=/opt/logmonitor

LOGSTASH_PATH=${INSTALL_PATH}/logstash-1.5.0
LOGSTASH_CONFIG_PATH=${LOGSTASH_PATH}/conf
LOGSTASH_CONFIG_FILE=${LOGSTASH_CONFIG_PATH}/central.conf
LOGSTASH_STDOUT=${LOGSTASH_PATH}/logs/stdout.log


downloadArchive(){
   ! test -d ${INSTALL_PATH} && mkdir -p ${INSTALL_PATH}
   ! test -f ${INSTALL_PATH}/elasticsearch.tar.gz && wget https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-1.5.2.tar.gz -O ${INSTALL_PATH}/elasticsearch.tar.gz
   ! test -f ${INSTALL_PATH}/logstash.tar.gz && wget http://download.elastic.co/logstash/logstash/logstash-1.5.0.tar.gz -O ${INSTALL_PATH}/logstash.tar.gz
   ! test -f ${INSTALL_PATH}/kibana.tar.gz && wget https://download.elastic.co/kibana/kibana/kibana-4.0.2-linux-x64.tar.gz -O ${INSTALL_PATH}/kibana.tar.gz
}

uncompression(){
	cd ${INSTALL_PATH}
	tar -vxzf ${INSTALL_PATH}/elasticsearch.tar.gz
	tar -vxzf ${INSTALL_PATH}/logstash.tar.gz
	tar -vxzf ${INSTALL_PATH}/kibana.tar.gz
}

replaceDefaultConfig(){
	! test -d ${LOGSTASH_CONFIG_PATH} && mkdir -p ${LOGSTASH_CONFIG_PATH}
	! test -d ${LOGSTASH_PATH}/logs && mkdir -p ${LOGSTASH_PATH}/logs

	if [ ! -f ${LOGSTASH_CONFIG_FILE} ]; then

		cat >${LOGSTASH_CONFIG_FILE}<<-EOF

 		  input {
		       	 redis {
	                	host => "${REDIS_SERVER}"
		                port => ${REDIS_SERVER_PORT}
		                type => "redis-input"
	        	        data_type => "list"
	                	key => "erongdu_logmonitor"
	        	 	}
			  }

		output {
	        	stdout {}
		        elasticsearch {
		                cluster => "elasticsearch"
	        	        host => "${MY_IP}"
	                	codec => "json"
	 	                protocol => "http"
	 	       }
		}
		EOF
	fi

	#change kibana default port to 8080

	if [ -f ${INSTALL_PATH}/kibana-4.0.2-linux-x64/config/kibana.yml ];then
	   sed -i "s/5601/8080/g" ${INSTALL_PATH}/kibana-4.0.2-linux-x64/config/kibana.yml			
	fi

	#apply iptables rule

	appendIptablesRule
}

appendIptablesRule(){
	iptables -I INPUT -p tcp --dport 8080 -j ACCEPT
	iptables -I OUTPUT -p tcp --dport 8080 -j ACCEPT
	iptables-save > /etc/sysconfig/iptables	
	systemctl restart iptables
}

create-elasticsearch-service(){
	BASE_PATH=${INSTALL_PATH}/elasticsearch-1.5.2

	cat <<-EOF >/usr/lib/systemd/system/elasticsearch.service
		[Unit]
		Description=elasticsearch Service
		Requires=network.service

		[Service]
		ExecStart=${BASE_PATH}/bin/elasticsearch
		Restart=on-failure

		[Install]
		WantedBy=multi-user.target
	EOF

	systemctl daemon-reload
	systemctl stop elasticsearch
	systemctl enable elasticsearch
	systemctl start elasticsearch
}

create-logstash-service(){
	cat <<-EOF >/usr/lib/systemd/system/logstash.service
		[Unit]
		Description=logstash Service
		Requires=network.service elasticsearch.service

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

create-kibana-service(){

	KIBANA_PATH=${INSTALL_PATH}/kibana-4.0.2-linux-x64

	cat <<-EOF >/usr/lib/systemd/system/kibana.service
		[Unit]
		Description=kibana Service
		Requires=network.service elasticsearch.service

		[Service]
		ExecStart=${KIBANA_PATH}/bin/kibana
		Restart=on-failure

		[Install]
		WantedBy=multi-user.target
	EOF

	systemctl daemon-reload
	systemctl stop kibana
	systemctl enable kibana
	systemctl start kibana
}

#check java is available in this session
function hasJava {
    v=`java -version 2>&1`

    echo 'check java platform...'

    pos=`expr match "$v" 'java version \"1.6.0_35\"'`
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
	yum -y install java-1.8.0
  fi
  
  create-elasticsearch-service
  create-logstash-service
  create-kibana-service
}


downloadArchive

uncompression

replaceDefaultConfig

installService
