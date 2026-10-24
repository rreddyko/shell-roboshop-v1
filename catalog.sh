#! /bin/bash

user_id=$(id -u)
logs_folder="/var/log/roboshop"
logs_file="${logs_folder}/${0}.log"

if [ $user_id -ne 0 ]; then
    echo " run with sudo access"
    exit 1
fi

mkdir -p $logs_folder

timestamp(){
    date "+%F %T"
}

validate (){
    if [ $1 -ne 0 ]; then
       echo -e "$(timestamp) ERROR ${2} FAILED " | tee -a $logs_file
       exit 1
    else
        echo -e "$(timestamp) INFO ${2} SUCCESS" | tee -a $logs_file  
    fi
}

echo " $(timestamp) INFO script started" | tee -a $logs_file

dnf module disable nodejs -y &>> $logs_file
dnf module enable nodejs:24 -y &>> $logs_file
dnf install nodejs -y &>> $logs_file
validate $? "nodejs installing"

id roboshop &>>$logs_file
if [ $? -ne 0 ]; then
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$logs_file
validate $? " creating system user"
else
    echo " roboshop user already exists "
fi

echo " $(timestamp) INFO script completed in $SECONDS seconds)"
echo " $(timestamp) INFO script completed execution" | tee -a $logs_file