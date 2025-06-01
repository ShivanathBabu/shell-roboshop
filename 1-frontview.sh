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

dnf module disable nginx -y &>>$script_file
validate $? "disable nginx"

dnf module enable nginx:1.24 -y &>>$script_file
validate $? "enable nginx:1.24"

dnf install nginx -y  &>>$script_file
validate $? "install nginx"

systemctl enable nginx &>>$script_file
validate $? "enable nginx"

systemctl start nginx &>>$script_file
validate $? "start nginx"

rm -rf /usr/share/nginx/html/* &>>$script_file
validate $? "removing default content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_FILE
validate $? "Downloading frontend"

cd /usr/share/nginx/html
unzip /tmp/frontend.zip &>>$script_file
validate $? "unzipping content"

rm -rf /etc/nginx/nginx.conf &>>$script_file
validate $? "removing default content"

cp $script_dir/nginx.conf /etc/nginx/nginx.conf &>>$script_file
validate "copying nginx"

systemctl restart nginx &>>$script_file
validate $? "Restarting nginx"
