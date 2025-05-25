#!/bin/bash
userid=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
logs_folder="/var/log/roboshop-logs"
script_name=$(echo $0 | cut -d "." -f1)
LOG_FILE="$logs_folder/$script_name"
script_dir=$PWD
mkdir -p $logs_folder

if [ $userid -ne 0 ]
then
echo -e "$R ERROR: run with root access $N" | tee -a $LOG_FILE
exit 1
else
echo -e "$G You are running with root access $N" | tee -a $LOG_FILE
fi

validate()
{
    if [ $1 -eq 0 ]
    then
    echo -e "$G $2 success $N" | tee -a $LOG_FILE
    else
    echo -e "$R $2 failed $N"  | tee -a $LOG_FILE
    exit 1
    fi

}

dnf module disable nodejs  &>>$LOG_FILE
validate $? "disabling nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
validate $? "enabling nodejs:20"

dnf install nodejs -y &>>$LOG_FILE
validate $? "installing nodejs"

mkdir -p /app 
validate $? "creating directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
validate $? "downloading catalogue"

rm-rf /app/* 
cd /app
unzip /tmp/catalogue.zip &>>$LOG_FILE
validate $? "unzipping catalogue"

npm install  &>>$LOG_FILE
validate $? "npm install"

cp $script_dir/catalogue.service /etc/systemd/system/catalogue.service 
validate $? "copying catalogue service"

systemctl daemon-reload catalogue.service &>>$LOG_FILE
systemctl enable catalogue.service &>>$LOG_FILE
systemctl start catalogue.service 
validate $? " starting catalogue"

cp $script_dir/mongodb.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongosh -y &>>$LOG_FILE
validate $? "Installing MongoDB Client"

STATUS=$(mongosh --host mongodb.blackweb.agency --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ $STATUS -ne 0 ]
then
   mongosh --host mongodb.blackweb.agency </app/db/master-data.js &>>$LOG_FILE
   validate $? "Loading data in to MongoDB"
   else
   echo -e "Data already loaded....$Y skipping $N"
   fi
