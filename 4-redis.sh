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

dnf module disable redis -y &>>$script_file
validate $? "disable redis"

dnf module enable redis:7 -y &>>$script_file
validate $? "enable redis"

dnf install redis -y &>>$script_file
validate $? "install redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf  &>>$script_file
validate $? "Edited redis.conf"

systemctl enable redis  &>>$script_file
validate $? "Enabling redis"

systemctl start redis &>>$script_file
validate $? "start redis"

endtime=$(date +%s)
totaltime=$(( $endtime - $starttime))
echo -e "Script exection completed successfully, $Y time taken: $totaltime seconds $N" | tee -a $script_file
