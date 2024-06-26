#!/usr/bin/env bash

# Copyright (c) 2021-2024 ulmentflam
# Author: ulmentflam (ulmentflamster)
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
$STD apt-get install -y git
$STD apt-get install -y ca-certificates
$STD apt-get install -y gnupg
msg_ok "Installed Dependencies"

msg_info "Setting up Node.js Repository"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro experimental" >/etc/apt/sources.list.d/nodesource.list
msg_ok "Set up Node.js Repository"

msg_info "Installing Node.js"
$STD apt-get update
$STD apt-get install -y nodejs
msg_ok "Installed Node.js"

msg_info "Installing pnpm"
$STD npm install -g pnpm
msg_ok "Installed pnpm"

msg_info "Installing Jellyseerr (Patience)"
git clone -q https://github.com/Fallenbagel/jellyseerr.git /opt/jellyseerr
cd /opt/jellyseerr
CYPRESS_INSTALL_BINARY=0 pnpm install --frozen-lockfile &>/dev/null
$STD pnpm build
mkdir -p /etc/jellyseerr/
cat <<EOF >/etc/jellyseerr/jellyseerr.conf
PORT=5055
# HOST=0.0.0.0
# JELLYFIN_TYPE=emby
EOF
msg_ok "Installed Jellyseerr"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/jellyseerr.service
[Unit]
Description=Jellyseerr Service
Wants=network-online.target
After=network-online.target

[Service]
EnvironmentFile=/etc/jellyseerr/jellyseerr.conf
Environment=NODE_ENV=production
Type=exec
Restart=on-failure
WorkingDirectory=/opt/jellyseerr
ExecStart=/usr/bin/node dist/index.js

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now jellyseerr.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
