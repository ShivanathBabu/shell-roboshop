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

dnf module disable nginx -y &>>$LOG_FILE
validate $? "disabling nginx"

dnf module enable nginx:1.24 -y &>>$LOG_FILE
validate $? "enabling nginx"

dnf install nginx -y &>>$LOG_FILE
validate $? "install nginx"

rm -rf /usr/share/nginx/html/* &>>$LOG_FILE
validate $? "Removing default content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading frontend"

cd /usr/share/nginx/html
unzip /tmp/frontend.zip 
validate $? "unzipping frontend"

rm -rf /etc/nginx/nginx.conf &>>$LOG_FILE
validate $? "remove default nginx"

cp $script_dir/nginx.conf /etc/nginx/nginx.conf  
validate $? "copying nginx.conf"

systemctl restart nginx &>>$LOG_FILE
validate $? "Restarting nginx"
