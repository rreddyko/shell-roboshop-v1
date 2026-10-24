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
    if [ $1 ne 0 ]; then
       echo -e "$(timestamp) ERROR ${2} FAILED " | tee -a $logs_file
       exit 1
    else
        echo -e "$(timestamp) INFO ${2} SUCCESS" | TEE -a $logs_file  
}

echo " $(timestamp) scrip started " | tee -a $logs_file

    dnf module disable redis -y &>> $logs_file
    dnf module enable redis:7 -y &>> $logs_file
    dnf install redis -y &>> $logs_file
    
    validate $? "Installing redis"

    sed -i -e 's/127.0.0.1/0.0.0.0/g' -e 's/^protected-mode yes/protected-mode no/' /etc/redis/redis.conf

    validate $? "remote connection to redis"

    systemctl enable redis &>> $logs_file
    systemctl start redis

    validate $? "Enable and start redis"

    echo "$(timestamp) INFO script completed in $SECONDS seconds"
    echo "$(timestamp) INFO script completed execution " | tee -a $logs_file