#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/tteck/Proxmox/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
    ____                            __  __                   
   / __ \_________  ____ ___  ___  / /_/ /_  ___  __  _______
  / /_/ / ___/ __ \/ __  __ \/ _ \/ __/ __ \/ _ \/ / / / ___/
 / ____/ /  / /_/ / / / / / /  __/ /_/ / / /  __/ /_/ (__  ) 
/_/   /_/   \____/_/ /_/ /_/\___/\__/_/ /_/\___/\__,_/____/  
 
EOF
}
header_info
echo -e "Loading..."
APP="Loki"
var_disk="4"
var_cpu="1"
var_ram="512"
var_os="debian"
var_version="12"
variables
color
catch_errors

function default_settings() {
  CT_TYPE="1"
  PW=""
  CT_ID=$NEXTID
  HN=$NSAPP
  DISK_SIZE="$var_disk"
  CORE_COUNT="$var_cpu"
  RAM_SIZE="$var_ram"
  BRG="vmbr0"
  NET="dhcp"
  GATE=""
  APT_CACHER=""
  APT_CACHER_IP=""
  DISABLEIP6="no"
  MTU=""
  SD=""
  NS=""
  MAC=""
  VLAN=""
  SSH="no"
  VERB="no"
  echo_default
}

function update_script() {
header_info
if [[ ! -f /etc/systemd/system/loki.service ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
RELEASE=$(curl -s https://api.github.com/repos/grafana/loki/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
  msg_info "Stopping ${APP}"
  systemctl stop loki promtail
  msg_ok "Stopped ${APP}"
  
  msg_info "Updating ${APP} to ${RELEASE}"
  wget -q https://github.com/grafana/loki/releases/download/v${RELEASE}/loki-linux-amd64.zip
  unzip loki-linux-amd64.zip
  mv loki-linux-amd64 /usr/local/bin/loki
  rm loki-linux-amd64.zip

  wget -q -O /etc/loki/loki.yaml https://raw.githubusercontent.com/grafana/loki/v${RELEASE}/cmd/loki/loki-local-config.yaml

  wget -q https://github.com/grafana/loki/releases/download/v${RELEASE}/promtail-linux-amd64.zip
  unzip promtail-linux-amd64.zip
  mv promtail-linux-amd64 /usr/local/bin/promtail
  rm promtail-linux-amd64.zip

  wget -q -O /etc/loki/promtail.yaml https://raw.githubusercontent.com/grafana/loki/v${RELEASE}/clients/cmd/promtail/promtail-local-config.yaml

  echo "${RELEASE}" >/opt/${APP}_version.txt
  msg_ok "Updated ${APP} to ${RELEASE}"

  msg_info "Starting ${APP}"
  systemctl start loki promtail
  msg_ok "Started ${APP}"
  msg_ok "Updated Successfully"
else
  msg_ok "No update required. ${APP} is already at ${RELEASE}"
fi
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:3100${CL} \n"
