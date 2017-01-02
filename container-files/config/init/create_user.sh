#!/bin/bash
user=$USER
pwd=$PASSWORD
# Comments supose $user is www
# Creating the www user only if it does not exist
ret=false
getent passwd $user >/dev/null 2>&1 && ret=true
mkdir -p /home/$user
if $ret; then
echo "user already exists";
else
useradd $user -d /home/$user
# Setting password for the www user
echo "${user}:${pwd}" | chpasswd
# Add 'www' user to sudoers
echo "${user}  ALL=(ALL)  NOPASSWD: ALL" > /etc/sudoers.d/$user
echo "user created"
fi
cp /etc/skel/.b* /home/$user

