job "ssh-sample" {
  datacenters = ["mushroom-kingdom"]

  type = "batch"

  group "hello" {
    count = 1

    network {
      port "ssh" {
      }
    }

    service {
      name = "ssh"
      port = "ssh"
    }

    # This is split out so that the main task can restart without recreating users
    task "create-user" {
      driver = "raw_exec"

      lifecycle {
        hook = "prestart"
      }

      config {
        command = "bash"

        args = [
          "-c", 
          <<EOF
mkdir -p /opt/ssh-access/keys/

# Careful if someone names a job "root" or some other existing username...
SSH_USERNAME="ssh-${NOMAD_JOB_NAME}"

# Just in case, try to remove an old copy... should be fresh each time, and
# ideally this should never actually need to run as names should be dynamic
# and the cleanup task should handle this, but sometimes things break!
deluser $SSH_USERNAME --remove-all-files &> /dev/null

# No password, only SSH key
adduser $SSH_USERNAME --shell $(which bash) --disabled-password

# Generate fresh SSH key to connect with
rm -rf /opt/ssh-access/keys/$SSH_USERNAME.key*
ssh-keygen -N '' -f /opt/ssh-access/keys/$SSH_USERNAME.key -t rsa -b 4096

# Copy the key so that the user can download it via nomad alloc fs
cp /opt/ssh-access/keys/$SSH_USERNAME.key connect.key
EOF
        ]
      }
    }

    task "cleanup-user" {
      driver = "raw_exec"

      lifecycle {
        hook = "poststop"
      }

      config {
        command = "bash"

        args = [
          "-c", 
          <<EOF
# Careful if someone names a job "root" or some other existing username...
SSH_USERNAME="ssh-${NOMAD_JOB_NAME}"

deluser $SSH_USERNAME --remove-all-files

rm -rf /opt/ssh-access/keys/$SSH_USERNAME.key*
          EOF
        ]
      }
    }

    task "ssh-sandbox" {
      driver = "raw_exec"

      template {
        destination = "sshd.config"

        data = <<EOF
AuthorizedKeysFile /opt/ssh-access/keys/%u.key.pub
ListenAddress {{ env "NOMAD_ADDR_ssh" }}
PasswordAuthentication no
        EOF
      }

      config {
        command = "bash"

        args = [
          "-c", 
          <<EOF
# Careful if someone names a job "root" or some other existing username...
SSH_USERNAME="ssh-${NOMAD_JOB_NAME}"

# Copy the key so that the user can download it via nomad alloc fs
cp /opt/ssh-access/keys/$SSH_USERNAME.key connect.key

echo ''

# Print instructions
echo "TODO: This should use Vault's SSH stuff so we can auth with Vault instead,"
echo "this is NOT currently secure... just a proof of concept!"
echo "--------------------------------------------------------------------------"
echo "Run the following commands to fetch the key, save it locally, and connect:"
echo "nomad alloc fs ${NOMAD_ALLOC_ID} ssh-sandbox/connect.key > demokey.key"
echo "chmod 0600 demokey.key"
echo "ssh $SSH_USERNAME@${NOMAD_IP_ssh} -p ${NOMAD_PORT_ssh} -i demokey.key"

# Actually run
/usr/sbin/sshd -d -f sshd.config
          EOF
        ]
      }
    }
  }
}
