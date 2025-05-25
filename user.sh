#!/bin/bash
start_time=$(date +%s)
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

dnf module disable nodejs -y
validate $? "disabling nodejs"

dnf module enable nodejs:20 -y
validate $? "enabling nodejs"

dnf install nodejs -y
validate $? "installing nodejs"

id roboshop
if [ $? -ne 0 ]
then 
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
else
echo -e "system user roboshop alreday create $Y skipping $N"
fi

mkdir -p /app
validate $? "creating app directory"

curl -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>>$LOG_FILE
validate $? "Downloading user"

rm -rf /app/*
cd /app
unzip /tmp/user.zip
validate $? "uNZIPPING USER"

npm install  &>>$LOG_FILE
validate $? "Installing Dependencies"

cp $script_dir/user.service /etc/systemd/system/user.service
validate $? "copying user directory"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable user &>>$LOG_FILE
systemctl start user &>>$LOG_FILE
validate $? "starting user"

End_Time=$(date +%s) &>>$LOG_FILE
TOTAL_TIME=$(( $End_Time - $start_time )) &>>$LOG_FILE
echo -e "Script exection completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE

