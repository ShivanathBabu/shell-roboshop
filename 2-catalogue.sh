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

dnf module disable nodejs -y  &>>$script_file
validate $? "disabling nodejs"

dnf module enable nodejs:20 -y &>>$script_file
validate $? "enabling nodejs:20"

dnf install nodejs -y &>>$script_file
validate $? "Install nodejs"

id roboshop
if [ $? -ne 0 ]
then
echo -e "$r system user not yet created...$n $g creating user $n"
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop  &>>$script_file
else
echo -e "system user roboshop already created ... $y skipping $n"
fi

mkdir -p /app
validate $? "creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$script_file
validate $? "downloading content"

rm -rf /app/*
cd /app
unzip /tmp/catalogue.zip &>>$script_file
validate $? "unzipping catalogue"

npm install &>>$script_file
validate $? "install npm"

cp $script_dir/catalogue.service /etc/systemd/system/catalogue.service 
validate $?  "copying"

systemctl daemon-reload catalogue.service &>>$script_file 
systemctl enable catalogue.service &>>$script_file
systemctl start catalogue.service
validate $? "starting catalogue"

cp $script_dir/mongodb.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongosh -y  &>>$script_file
validate $? "Installing Mongodb clinet"

status=$(mongosh --host mongodb.blackweb.agency --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ $status -lt 0 ]
then
  mongosh --host mongodb.blackweb.agency </app/db/master-data.js  &>>$script_file
  validate $? "Loading data into Mongodb"
else
 echo -e "Data is already loaded....$y skipping $n"
 fi
