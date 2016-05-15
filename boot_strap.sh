#!/bin/bash -e

# run inside of a virtual machine or what ever.
# ass long ass it is ubuntu

PACKAGES="build-essential vim git curl"
DEVSTACK_REPO="https://github.com/openstack-dev/devstack.git"

if [[ $# -eq 0 ]]; then

    DEVSTACK_BRANCH="stable/mitaka"

else
    DEVSTACK_BRANCH=$1
fi

# Install essential packages
echo "Installing essential packages..."
sudo apt-get update
sudo apt-get install -y $PACKAGES

# Write vim preferences
echo "Setting vim preferences..."
wget -O /root/.vimrc https://raw.githubusercontent.com/michaelrice/dot-files/master/.vimrc

echo "Setting up the git config opts"
wget -O /root/.gitconfig https://raw.githubusercontent.com/michaelrice/dot-files/master/.gitconfig

# Create the stack user
echo "Creating the stack user..."
sudo mkdir -p /home/stack
sudo useradd -g sudo -d /home/stack -s /bin/bash stack
sudo chown -R stack /home/stack

cat <<'EOF' > 50_stack_sh
stack ALL=(root) NOPASSWD:ALL
Defaults:stack secure_path=/sbin:/usr/sbin:/usr/bin:/bin:/usr/local/sbin:/usr/local/bin
Defaults:stack !requiretty
EOF
sudo su -c "mv 50_stack_sh /etc/sudoers.d/50_stack_sh"
sudo su -c "chmod 0440 /etc/sudoers.d/50_stack_sh"
sudo su -c "chown root:root /etc/sudoers.d/50_stack_sh"

# Clone devstack repo
echo "Deploying devstack..."
cd /home/stack
sudo su stack -c "git clone ${DEVSTACK_REPO}"
cd devstack
sudo su stack -c "git checkout ${DEVSTACK_BRANCH}"

sudo su stack -c "cat <<'EOF' > local.conf
[[local|localrc]]
ADMIN_PASSWORD=secrete
DATABASE_PASSWORD=secrete
RABBIT_PASSWORD=secrete
SERVICE_PASSWORD=secrete
SERVICE_TOKEN=secrete

# ceilometer
enable_plugin ceilometer https://git.openstack.org/openstack/ceilometer.git master

# horizon
enable_service horizon

# cloudkitty
enable_plugin cloudkitty https://github.com/openstack/cloudkitty master
enable_service ck-api ck-proc
EOF"

sudo su stack -c "./stack.sh"
echo "Success."
