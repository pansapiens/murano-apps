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

sudo apt-get update
sudo iptables -I INPUT 1 -p tcp -m tcp --dport 22 -j ACCEPT -m comment --comment "by murano, BioAnsible"

sudo apt-get -y -q install python-dev python-pip
sudo pip install ansible markupsafe
cd /home/ubuntu
# sudo git clone https://github.com/MonashBioinformaticsPlatform/bio-ansible.git
sudo git clone https://github.com/pansapiens/bio-ansible.git
cd bio-ansible
# sudo ansible-galaxy install -r requirements.yml -p roles/
sudo ansible-playbook --become-user=root --become -u ubuntu -i "localhost," --connection=local main.yml
# TODO: pull references and BLAST databases (existing scripts or somewhere else ?)
# TODO: deal with GATK download - this probably needs to be a post install message in the terminal upon
#       first login (eg, "please go here, download GATK to tarballs/ then run XXX")
# sudo reboot
