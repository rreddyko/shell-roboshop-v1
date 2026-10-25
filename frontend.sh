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
        echo " $(timestamp) ${2} failed" | tee -a $logs_file
    else
        echo " $(timestamp) ${2} success" | tee -a $logs_file
    fi
}

echo " $(timestamp) script started "

dnf module disable nginx -y &>>$logs_file
dnf module enable nginx:1.26 -y &>>$logs_file
dnf install nginx -y &>>$logs_file
validate $? "nginx installing"

systemctl enable nginx &>>$logs_file
systemctl start nginx &>>$logs_file
validate $? "enable start nginx"

rm -rf /usr/share/nginx/html/* &>>$logs_file
validate $? "removing default content"

curl -L -o /tmp/frontend.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/frontend-v4.zip &>>$logs_file

cd /usr/share/nginx/html &>>$logs_file
unzip /tmp/frontend.zip &>>$logs_file

sed -i "s/DOMAIN_NAME/$domain_name" "$script_dir/roboshop.conf"
cp "$script_dir/roboshop.conf" /etc/nginx/default.d/roboshop.conf
validate $? "copied roboshop conf"

nginx -t & >>$logs_file
validate $? "nginx configuration"

systemctl restart nginx &>>$logs_file
validate $? "restarting nginx"

echo "$(timestamp) script took $SECONDS seconds"
echo "$(timestamp)=====script completed======"