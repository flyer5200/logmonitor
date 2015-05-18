#!/bin/sh


LOGSTASH_CONFIG=/opt/logmonitor/logstash-1.5.0/conf/central.conf
LOGSTASH_STDOUT=/opt/logmonitor/logstash-1.5.0/logs/stdout.log

cat <<EOF >/usr/lib/systemd/system/logstash.service
[Unit]
Description=logstash Service
Requires=network.service elasticsearch.service

[Service]
ExecStart=/opt/logmonitor/logstash-1.5.0/bin/logstash agent --verbose --config ${LOGSTASH_CONFIG} --log ${LOGSTASH_STDOUT}
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl stop logstash
systemctl enable logstash
systemctl start logstash
