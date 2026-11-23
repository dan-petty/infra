#!/usr/bin/env bash
# bootstrap-ansible-user.sh — Provision dedicated Ansible user on a Debian node
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <user> '<public key>' ['<public key>' ...]" >&2
  exit 2
fi

AUTOMATION_USER="$1"
shift
AUTOMATION_SHELL="${AUTOMATION_SHELL:-/bin/bash}"
PUBKEYS=("$@")

echo "==> [1/5] Ensuring OpenSSH server is installed and active..."
if ! command -v sshd >/dev/null 2>&1; then
  apt-get update && apt-get install -y openssh-server
fi
systemctl enable --now ssh || systemctl enable --now sshd

echo "==> [2/5] Ensuring python3 and sudo are installed..."
if ! command -v python3 >/dev/null 2>&1 || ! command -v sudo >/dev/null 2>&1; then
  apt-get update && apt-get install -y python3 sudo
fi

echo "==> [3/5] Provisioning ${AUTOMATION_USER} user..."
if ! id "${AUTOMATION_USER}" >/dev/null 2>&1; then
  useradd -m -s "${AUTOMATION_SHELL}" -G sudo "${AUTOMATION_USER}"
else
  usermod -aG sudo -s "${AUTOMATION_SHELL}" "${AUTOMATION_USER}"
fi

echo "==> [4/5] Configuring passwordless sudo for ${AUTOMATION_USER}..."
echo "${AUTOMATION_USER} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${AUTOMATION_USER}"
chmod 0440 "/etc/sudoers.d/${AUTOMATION_USER}"
visudo -cf "/etc/sudoers.d/${AUTOMATION_USER}"

echo "==> [5/5] Deploying authorized SSH public keys..."
USER_HOME=$(getent passwd "${AUTOMATION_USER}" | cut -d: -f6)
SSH_DIR="${USER_HOME}/.ssh"
mkdir -p "${SSH_DIR}"
chmod 0700 "${SSH_DIR}"

AUTH_KEYS="${SSH_DIR}/authorized_keys"
touch "${AUTH_KEYS}"
for key in "${PUBKEYS[@]}"; do
  if ! grep -qF "${key}" "${AUTH_KEYS}" 2>/dev/null; then
    echo "${key}" >> "${AUTH_KEYS}"
  fi
done
chmod 0600 "${AUTH_KEYS}"
chown -R "${AUTOMATION_USER}:${AUTOMATION_USER}" "${SSH_DIR}"

echo "==> Ansible automation user '${AUTOMATION_USER}' successfully provisioned."
