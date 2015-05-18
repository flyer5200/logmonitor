#!/bin/sh

cat <<EOF >/usr/lib/systemd/system/kibana.service
[Unit]
Description=kibana Service
Requires=network.service elasticsearch.service

[Service]
ExecStart=/opt/logmonitor/kibana-4.0.2-linux-x64/bin/kibana
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl stop kibana
systemctl enable kibana
systemctl start kibana
