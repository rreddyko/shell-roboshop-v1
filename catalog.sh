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
    echo " system user already exists "
fi

mkdir -p /app
validate $? "creating app directory"

curl -L -o /tmp/catalog.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/catalogue-v4.zip
validate $? "downloading catalog zip"

cd /app
unzip /tmp/catalog.zip &>> $logs_file
validate $? "unzipping catalog zip"

npm install &>> $logs_file
validate $? "installing nodejs dependencies"

sed -i 's/DOMAIN_NAME/$domain_name/g' catalog.service

cp catalog.service /etc/systemd/system/catalog.service

systemctl daemon-reload &>> $logs_file
systemctl enable catalog &>> $logs_file
systemctl start catalog &>> $logs_file
validate $? "enable and start catalog service"

echo " $(timestamp) INFO script completed in $SECONDS seconds)"
echo " $(timestamp) INFO script completed execution" | tee -a $logs_file