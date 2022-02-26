#!/bin/bash -e

cd ${0%/*}
cd ..

if [ -z "${1}" ]; then
  echo "Usage: keygen.sh <name>"
  exit 1
fi

ssh-keygen -t ed25519 -f ansible/keys/${1} -q -N "" -C "${1}@lakitu"

PRIVATE="ansible/keys/${1}"
PUBLIC="${PRIVATE}.pub"

chmod 0600 "${PRIVATE}"
chmod 0644 "${PUBLIC}"

mv ${PRIVATE} ansible/keys/private/
mv ${PUBLIC} ansible/keys/public/

