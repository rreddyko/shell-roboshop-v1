#! /bin/bash

user_id=$(id -u)
logs_folder="/var/log/roboshop"
logs_file="${logs_folder}/${0}.log"
domain_name="rameshkotha572.online"
script_dir=$(dirname "$(realpath "$0")")

if [ $user_id -ne 0 ]; then
    echo "please run with sudo access"
    exit 1
fi

mkdir -p $logs_folder

timestamp(){
    date "+%F %T"
}

validate(){
    if [ $1 -ne 0 ]; then
    echo -e "$(timestamp) ${2} FAILED" | tee -a $logs_file
    else
    echo -e "$(timestamp) ${2} SUCCESS" | tee -a $logs_file
    fi
}

echo "$(timestamp)=====SCRIPT STARTED======"

dnf module disable nodejs -y &>> $logs_file
dnf module enable nodejs:24 -y &>> $logs_file
dnf install nodejs -y &>> $logs_file
validate $? "node js:24 installation"

id roboshop &>>$logs_file

if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "system user" roboshop &>>$logs_file
    valite $? "system user creation"
else
    echo " $(timestamp) provided system user already exists"
fi

rm -rf /app
validate $? "removed old file"

mkdir -p /app
validate $? "creating app directory"

curl -L -o /tmp/user.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/user-v4.zip &>>$logs_file

validate $? "downloading user provided by developer"

cd /app

unzip /tmp/user.zip &>> $logs_file

npm install &>> $logs_file

validate $? "installing dependecies"

sed -i "s/DOMAIN_NAME/$domain_name/g" "$script_dir/user.service"

cp "$script_dir/user.service" /etc/systemd/system/user.service

systemctl daemon-reload  &>>$logs_file
systemctl enable user &>>$logs_file
systemctl start user &>>$logs_file
validate $? "enabling and starting user"

systemctl restart user &>>$logs_file
validate $? "restarting user"

echo "$(timestamp) script completed in $SECONDS seconds"
echo "$(timestamp)====USER SCRIPT COMPLETED====="







