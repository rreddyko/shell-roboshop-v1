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

cp rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
validate $? "repo of rabbit mq added"

dnf install erlang rabbitmq-server -y &>> $logs_file
validate $? "RabbitMQ installation"

systemctl enable rabbitmq-server &>> $logs_file
systemctl start rabbitmq-server &>> $logs_file
validate $? "Enable and start rabbitmq-server"

rabbitmqctl add_user roboshop Roboshop@1 &>> $logs_file
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>> $logs_file
validate $? "setting user permission"

echo "$(timestamp) INFO script completed in $SECONDS seconds"
echo "$(timestamp) INFO script completed execution " | tee -a $logs_file
