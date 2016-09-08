#!/bin/bash
MAILTO="MAGEADMINEMAIL"
MAILFROM="DOMAINNAME"
SERVER_IP_ADDR=$(ip route get 1 | awk '{print $NF;exit}')
SERVICE=$1

SERVICE_STATUS=$(systemctl status ${SERVICE})

sendmail ${MAILTO} <<EOF
From:${MAILFROM}
To:${MAILTO}
Subject:[ ! ALERT ! ] - ${SERVICE} failed to start on ${MAILFROM} ${SERVER_IP_ADDR}
Importance: High
Content-type: text/plain

Status report for unit: ${SERVICE}

${SERVICE_STATUS}
EOF
