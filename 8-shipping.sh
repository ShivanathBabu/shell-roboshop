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

dnf install maven -y &>>$script_file
validate $? "Installing maven and java"

id roboshop
if [ $? -ne 0 ]
then
useradd --system --home /app --shell /sbin/nologin --comment "roboshop user" roboshop &>>$script_file
validate $? "creating user"
else
echo -e "already created user $y skipping $n"
fi

mkdir -p /app/ &>>$script_file
validate $? "creating app directory"

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$script_file
validate $? "downoading shipping"

rm -rf /app/*
cd /app
unzip /tmp/shipping.zip &>>$script_file
validate $? "unzipping shipping"

mvn clean package &>>$script_file
validate $? "paccking the shipping application"

mv target/shipping-1.0.jar shipping.jar &>>$script_file
validate $? "moving and renaming jar files"

cp $script_dir/shipping.service /etc/systemd/system/shipping.service &>>$script_file
validate $? "copying"

systemctl daemon-reload &>>$script_file
validate $? "reload shipping"

systemctl enable shipping.service &>>$script_file
validate $? "enable shipping.service"

systemctl start shipping.service &>>$script_file
validate $? "starting shipping.service"

dnf install mysql -y &>>$script_file
validate $? "installing sql"

mysql -h mysql.blackweb.agency -u root -p$MYSQL_ROOT_PASSWORD -e 'use cities' &>>$script_file
if [ $? -ne 0 ]
then
mysql -h mysql.blackweb.agency -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/schema.sql &>>$script_file
mysql -h mysql.blackweb.agency -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/app-user.sql &>>$script_file
mysql -h mysql.blackweb.agency -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/master-data.sql &>>$script_file
else
    echo -e "Data is already loaded into MySQL ... $Y SKIPPING $N"
fi

systemctl restart shipping 
validate $? "restarting shipping"


END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $starttime ))

echo -e "Script exection completed successfully, $y time taken: $TOTAL_TIME seconds $n" | tee -a $script_file