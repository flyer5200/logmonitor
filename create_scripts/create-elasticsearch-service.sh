#!/bin/sh

BASE_PATH=/opt/logmonitor/elasticsearch-1.5.2

cat <<EOF >/usr/lib/systemd/system/elasticsearch.service
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
