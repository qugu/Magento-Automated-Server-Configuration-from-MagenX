#!/bin/bash
MAILTO="MAGE_ADMIN_EMAIL"
MAILFROM="${HOSTNAME}"
SERVER_IP_ADDR=$(ip route get 1 | awk '{print $NF;exit}')
SERVICE=$1

SERVICE_STATUS=$(systemctl status ${SERVICE})

echo " ${SERVICE_STATUS} " | mail -s "${SERVICE} entered failed state on ${MAILFROM} IP:${SERVER_IP_ADDR}" ${MAILTO}
