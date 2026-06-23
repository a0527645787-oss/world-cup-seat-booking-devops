#!/bin/bash
set -Eeuo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y ca-certificates curl gnupg git

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

. /etc/os-release
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu

REPO_URL="https://github.com/a0527645787-oss/world-cup-seat-booking-devops.git"
APP_DIR="/home/ubuntu/seat-booking-devops"

if [ -d "${APP_DIR}/.git" ]; then
  git -C "${APP_DIR}" pull --ff-only
elif [ -d "${APP_DIR}" ]; then
  echo "${APP_DIR} exists but is not a Git repository; skipping clone"
else
  git clone "${REPO_URL}" "${APP_DIR}"
fi

chown -R ubuntu:ubuntu "${APP_DIR}"

docker --version
docker compose version
git --version
