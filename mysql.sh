#! /bin/bash

user_id=$(id -u)
logs_folder="/var/log/roboshop"
logs_file="${logs_folder}/${0}.log"

if [ $user_id -ne 0 ]; then
    echo " run with sudo access"
    exit 1
fi

mkdir -p $logs_folder

validate () {
    if [ $1 -ne 0 ]; then
        echo -e " $2  failed " | tee -a $logs_file
        exit 1
    else
        echo -e " $2 success " | tee -a $logs_file
    fi
}

timestamp(){
    date "+%F %T"
}

echo " $(timestamp) script started " | tee -a $logs_file
 
    dnf module enable mysql:8.0 -y &>> $logs_file
    dnf install mysql-server -y &>> $logs_file
    validate $? "Installing mysql server"

    systemctl enable mysqld &>> $logs_file
    systemctl start mysqld &>> $logs_file
    validate $? "Enable and start mysql server"

    mysql_secure_installation --set-root-pass 'Roboshop@1' &>> $logs_file
    validate $? "mysql_secure_installation"
    
    echo " $(timestamp) script completed in $SECONDS seconds"
    echo " $(timestamp) script completed execution " | tee -a $logs_file