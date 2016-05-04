#!/bin/bash
#  Licensed under the Apache License, Version 2.0 (the "License"); you may
#  not use this file except in compliance with the License. You may obtain
#  a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#  License for the specific language governing permissions and limitations
#  under the License.

# BIOANSIBLE_REPO=https://github.com/MonashBioinformaticsPlatform/bio-ansible.git
BIOANSIBLE_REPO=https://github.com/pansapiens/bio-ansible.git
# this should match the sw-installer user used in the Ansible playbook
SW_INSTALLER_USER=sw-installer
# zero = don't automatically download reference genomes and databases
DOWNLOAD_REFERENCES=1

sudo apt-get update
sudo iptables -I INPUT 1 -p tcp -m tcp --dport 22 -j ACCEPT -m comment --comment "by murano, BioAnsible"

sudo apt-get -y -q install python-dev python-pip git build-essential
sudo pip install ansible markupsafe

# /software and /references live on an external volume (they are symlinks to /mnt/).
# /software/source lives on the ephemeral volume.
sudo mkdir -p /mnt/software
chown -R ${SW_INSTALLER_USER}.adm /software
sudo ln -shf /mnt/software /software
sudo mkdir -p /mnt/references
chown -R ${SW_INSTALLER_USER}.adm /references
sudo ln -shf /mnt/references /references

# The contents of /software/source may be pre-populated before Ansible runs by
# moving a special directory of packages baked into the image. If the special
# directory containing source packages existing in the image, we move it to
# where bio-ansible will expect it.
#if [-d "/bioansible_source_packages" ]; then
#  sudo mv -f /bioansible_source_packages /software/source
#fi

cd /home/ubuntu
# clone or pull the latest version of bioansible
if [ ! -d "/home/ubuntu/bio-ansible" ]; then
  git clone ${BIOANSIBLE_REPO}
  cd bio-ansible
else
  cd bio-ansible
  git fetch --all
  git reset --hard origin/master
  git pull origin master
fi

cat << EOF >ansible.cfg
[defaults]
roles_path = galaxy-roles/
log_path=/home/ubuntu/bio-ansible/ansible.log
EOF

mkdir -p galaxy-roles
ansible-galaxy install -r requirements.yml -p galaxy-roles/

sudo nohup ansible-playbook --become-user=root --become -u ubuntu -i "localhost," --connection=local main.yml 2>&1 | tee ansible.out &
#sudo ansible-playbook --become-user=root --become -u ubuntu -i "localhost," --connection=local main.yml 2>&1 | tee ansible.out
# just retry once if exit code is non-zero
#if [ $? -ne 0 ]; then
#  sudo ansible-playbook --become-user=root --become -u ubuntu -i "localhost," --connection=local main.yml 2>&1 | tee ansible.out
#fi

# TODO: deal with GATK download - this probably needs to be a post install message in the terminal upon
#       first login (eg, "please go here, download GATK to tarballs/ then run XXX")

if [ ${DOWNLOAD_REFERENCES} -eq 0 ]; then
  # Download databases and reference genomes
  cd scripts
  sudo -u ${SW_INSTALLER_USER} download-gencode.sh
  sudo -u ${SW_INSTALLER_USER} download-igenomes.sh
  sudo -u ${SW_INSTALLER_USER} download-uniprot.sh
  sudo -u ${SW_INSTALLER_USER} download-rseqc-ref.sh /references/RSeQC

  # Download NCBI-BLAST databases
  source /software/apps/lmod/lmod/init/bash
  mkdir /references/blast
  chown sw-installer.adm /references/*
  cd /references/blast
  sudo -u ${SW_INSTALLER_USER} $(which update_blastdb.pl) --passive --verbose '.*'
fi

# sudo reboot
