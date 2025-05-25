#!/bin/bash
userid=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

logs_folder="/var/log/roboshop-logs"
script_name=$(echo $0 | cut -d "." -f1)
LOG_FILE="$logs_folder/$script_name.log"
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

cp mongodb.repo /etc/yum.repos.d/mongodb.repo &>>$LOG_FILE
validate $? "copying Mongodb repo"

dnf install mongodb-org -y &>>$LOG_FILE
validate $? "mongodb"

systemctl enable mongod  &>>$LOG_FILE
validate $? "enabling mongodb"

systemctl start mongod &>>$LOG_FILE
validate $? "starting mongodb"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf &>>$LOG_FILE
validate $? "Editing remote file of mongodb"

systemctl restart mongod &>>$LOG_FILE
validate $? "Restarting MongoDB"



