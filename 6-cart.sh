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
validate $? "disable nodejs"

dnf module enable nodejs:20 -y &>>$script_file
validate $? "enable nodejs:20"

dnf install nodejs -y &>>$script_file
validate $? "install nodejs"

id roboshop
if [ $? -ne 0 ]
then
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop user" roboshop &>>$script_file
   validate $? "creating roboshop"
   else
   echo -e "already created $y skipping $n"
    fi

   mkdir -p /app &>>$script_file
   validate $? "creating app directory"

   curl -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>$script_file
   validate $? "downloading cart"

   rm -rf /app/* &>>$script_file
   cd /app &>>$script_file
   unzip /tmp/cart.zip  &>>$script_file
   validate $? "unzipping cart"

   npm install &>>$script_file
   validate $? "install npm"

   cp $script_dir/cart.service /etc/systemd/system/cart.service &>>$script_file
   validate $? "copying cart.service"

   systemctl daemon-reload &>>$script_file
   systemctl enable cart.service &>>$script_file
   systemctl start cart.service &>>$script_file
   validate $? "starting cart" &>>$script_file
 
   END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $starttime ))

echo -e "Script exection completed successfully, $y time taken: $TOTAL_TIME seconds $n" | tee -a $script_file

  