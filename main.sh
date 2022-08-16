/home/ec2-user/.testdomain_join.sh
-----------------------------------------

#!/bin/bash
DATE=`date +%Y%m%d%R`
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/home/ec2-user/joinAD_$DATE.out 2>&1

echo "                                  "
echo "+++++++++++++++++++ # Installing packages ++++++++++++++++++"
###sudo yum -y update
sudo yum -y install sssd realmd krb5-workstation oddjob oddjob-mkhomedir adcli samba-common-tools openssl
sudo easy_install pip
sudo pip install pexpect
sudo pip install awscli
sudo yum install -y expect 
sudo yum install unzip wget -y

echo "                                                 "
echo "+++++++++++++++++++#Set SELinux to permissive mode +++++++++++++++++++++++"
sestatus | grep -i mode
sudo setenforce 0
sestatus | grep -i mode

===============
sudo vi /etc/selinux/config
SELINUX=permissive
==============


===================

###aws ec2 describe-instances --query 'Reservations[].Instances[].Tags[?Key==`Name`].Value[]'

###HOST_VAR=$(aws ec2 describe-tags --region us-east-1 --filters "Name=resource-id,Values=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)" --query 'Tags[*].Value' --output text) 

echo "                                                 "
echo "+++++++++++++++++++# Grab tag value with the 'describe-tags' action for setting server hostname ++++++++++++++++++++++"
HOST_VAR=$(aws ec2 describe-tags --region us-east-1 --filters "Name=resource-id,Values=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)" --query 'Tags[?Key==`Name`].Value[]' --output text)
echo $HOST_VAR

================

echo "                                                 "
echo "+++++++++++++++++++++++++ # Joining To Domain ++++++++++++++++++++++++++++++++"
DOMAIN_VAR=dev.abc.com
USER_VAR=SVC_LINDEVj0in@dev.abc.com
DOMAIN_ADMIN=ad_admin_group
sudo realm discover $DOMAIN_VAR --verbose


===============

sudo hostnamectl set-hostname --static $HOST_VAR

===============
echo "                                                 "
echo "++++++++++++++++++++++++++++++ # Modify Hosts file to get Differnet result for HOSTNAME and HOSTNAME -f +++++++++++++++++++++++++++++++"
IP_VAR=$(hostname -I)
echo "$IP_VAR  $HOST_VAR.$DOMAIN_VAR  $HOST_VAR " | sudo tee -a /etc/hosts > /dev/null
sudo cat /etc/hosts |grep abac.com

=================
###sudo realm join -U $USER_VAR $DOMAIN_VAR --verbose
###sudo realm join -U $USER_VAR $DOMAIN_VAR --verbose
####echo $passwd| realm join -U serviceaccount --client-software=sssd abc.com 

# ***To use to join to Specific OU****

# ****DEV - APP OU:
# sudo realm join --user=$USER_VAR --computer-ou=OU=APP,OU=AW_UNIX_SYS,OU=DEVLMAM,OU=dev,DC=dev,DC=abac,DC=com $DOMAIN_VAR --verbose


# ****DEVSS - APP OU:
# sudo realm join --user=$USER_VAR --computer-ou=OU=APP,OU=AW_UNIX_SYS,OU=DEVSSLMAM,OU=devss,DC=devss,DC=abac,DC=com $DOMAIN_VAR --verbose

# OU=APP,OU=AW_UNIX_SYS,OU=DEVSSLMAM,OU=devss,DC=devss,DC=abac,DC=com


# id $USER_VAR

# [ec2-user@OraclePRODSS1AZ3 ~]$ id $USER_VAR
# uid=423433109(aaaw8327@abac.com) gid=423400513(domain users@abac.com) groups=423400513(domain users@abac.com),423433104(lmam_duousers@abac.com),423401145(lmam_remotedesktop_users@abac.com),423433108(lmam_defaultppp@abac.com),423401164(aws delegated add workstations to domain users@abac.com),423402104(iam_administatoraccess@abac.com),423433102(lmam_djoin@abac.com),423402123(ss-linux-privs@abac.com)

========================


echo "                                                 "
echo "+++++++++++++++++++++++++++ # Backup files +++++++++++++++++++++++++++++++"
sudo cp -p /etc/cloud/cloud.cfg /etc/cloud/cloud.cfg_bkp
sudo cp -p /etc/hostname /etc/hostname_bkp
sudo cp -p /etc/ssh/sshd_config /etc/ssh/sshd_config_bkp
sudo cp -p /etc/hosts /etc/hosts_bkp
sudo cp -p /etc/sssd/sssd.conf /etc/sssd/sssd.conf_bkp
sudo cp -p /etc/sudoers /etc/sudoers_bkp
sudo cp -pR /etc/sudoers.d /etc/sudoers.d_bkp

echo "                                                 "
echo "++++++++++++++++++ # Hostname is preserved between restarts/reboots in cloud.cfg +++++++++++++++++++++++"
sudo sh -c 'echo -e "\npreserve_hostname: true" >> /etc/cloud/cloud.cfg'
sudo cat /etc/cloud/cloud.cfg |grep preserve_hostname

echo "                                                 "
echo "++++++++++++++++++++++# PasswordAuthentication set to YES in sshd_config +++++++++++++++++++++++++"
sudo sed -i '/#PasswordAuthentication yes/c\PasswordAuthentication yes' /etc/ssh/sshd_config
sudo cat /etc/ssh/sshd_config |grep PasswordAuthentication
sudo sed -i '/PasswordAuthentication no/c\#PasswordAuthentication no' /etc/ssh/sshd_config
sudo cat /etc/ssh/sshd_config |grep PasswordAuthentication

echo "                                                 "
echo "++++++++++++++++++++++++ # use_fully_qualified_names set to FALSE in sssd.conf +++++++++++++++++++++"
sudo sed -i '/use_fully_qualified_names = True/c\use_fully_qualified_names = False' /etc/sssd/sssd.conf
sudo cat /etc/sssd/sssd.conf |grep use_fully_qualified_names
sudo sed -i '/fallback_homedir = \/home\/%u@%d/c\fallback_homedir = \/home\/%u/' /etc/sssd/sssd.conf
sudo cat /etc/sssd/sssd.conf |grep fallback_homedir
sudo cat /etc/sssd/sssd.conf 


echo "                                                  "
echo "+++++++++++++++++++ #Update sudoer file with AD group and/or user ++++++++++++++++++++++++"
#sudo ls -ltr /etc/sudoers.d |grep $USER_VAR
#sudo bash -c 'echo "$USER_VAR       ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers'

sudo touch /etc/sudoers.d/$DOMAIN_ADMIN
sudo ls -ltr /etc/sudoers.d/$DOMAIN_ADMIN
sudo bash -c 'echo "# User rules for AD Admin SVC User" > /etc/sudoers.d/'$DOMAIN_ADMIN''
sudo sh -c 'echo "%dev-linux-privs ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/'$DOMAIN_ADMIN''
sudo sh -c 'echo "%dev-linux-privs@dev.abac.com ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/'$DOMAIN_ADMIN''



###sudo sh -c 'echo "%devsslmam_djoin@devss.abac.com ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/'$DOMAIN_ADMIN''
###sudo sh -c 'echo "%devlmam_djoin ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/'$DOMAIN_ADMIN''
###sudo sh -c 'echo "%devlmam_appec2_privileged ALL=(ALL) ALL" >> /etc/sudoers.d/'$DOMAIN_ADMIN''
####sudo sh -c 'echo "%devsslmam_autosys-wcc-qa-manager ALL=(ALL) ALL" >> /etc/sudoers.d/'$DOMAIN_ADMIN''
####sudo sh -c 'echo "%devss-linux-privs ALL=(ALL) ALL" >> /etc/sudoers.d/'$DOMAIN_ADMIN''
####sudo sh -c 'echo "%DEVSS-OracleDB-Linux ALL = /bin/su - oracle, !/bin/su *root*" >> /etc/sudoers.d/'$DOMAIN_ADMIN''
####sudo sh -c 'echo "%oinstall ALL=(ALL) ALL" >> /etc/sudoers.d/'$DOMAIN_ADMIN''

sudo cat /etc/sudoers.d/$DOMAIN_ADMIN
sudo chmod 440 /etc/sudoers.d/$DOMAIN_ADMIN
sudo chown root:root /etc/sudoers.d/$DOMAIN_ADMIN
sudo ls -ltr /etc/sudoers.d/$DOMAIN_ADMIN
sudo cat /etc/sudoers.d/$DOMAIN_ADMIN
