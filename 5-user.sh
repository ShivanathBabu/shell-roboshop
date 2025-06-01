#!/bin/bash
starttime=$(date +%s)
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
echo "script started executing at: $(date)" | tee -a $script_file
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

dnf module disable nodejs -y &>>$script_file
validate $? "disable nginx"

dnf module enable nodejs:20 -y &>>$script_file
validate $? "enable nodejs:20"

dnf install nodejs -y &>>$script_file
validate $? "install nodejs"

id roboshop
if [ $? -ne 0 ]
then
echo -e "$r roboshop not yet installed.. $n $g installing please wait $n"
useradd --system --home /app --shell sbin/nologin --comment "roboshop user" roboshop &>>$script_file 
validate $? "creating system user"
else
echo -e "already created...$y already created $n"  
fi

mkdir -p /app   &>>$script_file
validate $? "creating app directory"

curl -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip
validate $? "downloading user content"

rm -rf /app/*  &>>$script_file
cd /app  &>>$script_file
unzip /tmp/user.zip &>>$script_file
validate $? "unzipping user" &>>$script_file

npm install &>>$script_file
validate $? "npm install"

cp $script_dir/user.service /etc/systemd/system/user.service &>>$script_file
validate $? "copying user.service"

systemctl daemon-reload  &>>$script_file
systemctl enable user.service &>>$script_file
systemctl start user.service &>>$script_file

endtime=$(date +%s) 
totaltime=$(( $endtime-$starttime ))
echo -e "Script exection completed successfully, $y time taken: $totaltime seconds $n" | tee -a $script_file
