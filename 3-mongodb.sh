#!/bin/bash
userid=$(id -u)
r="\e[31m"
g="\e[32m"
y="\e[33m"
n="\e[0n"

logs_folder="/var/log/front.log"
script_name=$(echo $0 | cut -d "." -f1)
script_file="$logs_folder/$script_name.log"
script_dir=$PWD

mkdir -p $logs_folder
if [ $userid -ne 0 ]
then
  echo -e "$r ERROR: Please run wuth sudo access $n" | tee -a $script_file
  exit 1
else
   echo -e "$g Running with sudo access $n" | tee -a $script_file
fi

validate() {
    if [ $1 -eq 0 ]
    then
      echo -e "$2 is .... $g success $n" | tee -a $script_file
      else
      echo -e "$2 is... $r failure $n" | tee -a $script_file
      exit 1
      fi
}

cp mongodb.repo /etc/yum.repos.d/mongodb.repo
validate $? "Copying mongodb repo"

dnf install mongodb-org -y 
validate $? "Install mongodb server"

systemctl enable mongod
validate $? "Enabling Mongodb"

systemctl start mongod 
validate $? "start mongod"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
validate $? "editing mongod file"

systemctl restart mongod
validate $? "Restarting mongoDB"