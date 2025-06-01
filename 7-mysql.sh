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

dnf install mysql-server &>>$script_file
validate $? "installing mysql"

systemctl enable mysqld &>>$script_file
validate $? "enabling mysqld"

systemctl start mysqld &>>$script_file
validate $? "starting mysql"

mysql_secure_installation --set-root-pass $MYSQL_ROOT_PASSWORD &>>$script_file
validate $? "setting root password"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $starttime ))

echo -e "Script exection completed successfully, $y time taken: $TOTAL_TIME seconds $n" | tee -a $script_file