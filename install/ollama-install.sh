#!/usr/bin/env bash

# Copyright (c) 2021-2024 ulmentflam
# Author: ulmentflam (ulmentflamster)
# Co-Author: ulmentflam
# License: MIT
# https://github.com/ulmentflam/Proxmox/raw/experimental/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
msg_ok "Installed Dependencies"

msg_info "Installing Ollama"
$STD curl -L https://ollama.com/download/ollama-linux-amd64 -o /usr/bin/ollama
$STD chmod +x /usr/bin/ollama
msg_ok "Installed Ollama"

msg_info "Creating Service"
service_path="/etc/systemd/system/ollama.service"
echo "[Unit]
Description=Ollama Service
Documentation=man:ollama
After=network-online.target

[Service]
Type=simple
Environment=OLLAMA_HOST=0.0.0.0:11434
ExecStart=/usr/bin/ollama serve
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target" >$service_path
systemctl -q daemon-reload
systemctl enable -q --now ollama.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
