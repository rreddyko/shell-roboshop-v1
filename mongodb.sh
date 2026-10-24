#! /bin/bash

user_id=$(id -u)
logs_folder="/var/log/roboshop"
logs_file="${logs_folder}/${0}.log"

if [ $user_id -ne 0 ]; then
    echo " Run with sudo access"
    exit 1
fi

mkdir -p $logs_folder

echo "script started at $(date +"%F %T")"

validate () {
    if [ $1 -ne 0 ]; then
        echo -e " $2  failed " | tee -a $logs_file
        exit 1
    else
        echo -e " $2 success " | tee -a $logs_file
    fi
}

cp mongo.repo /etc/yum.repos.d/mongo.repo
validate $? "Adding mongo repo"

dnf install mongodb-org -y
validate $? "Install mongodb"

systemctl enable mongod
systemctl start mongod
validate $? "enable and start monogodb"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
systemctl restart mongod
