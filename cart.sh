 #! /bin/bash

user_id=$(id -u)
logs_folder="/var/log/roboshop"
logs_file="${logs_folder}/${0}.log"
domain_name="rameshkotha572.online"
script_dir=$(dirname "$(realpath "$0")")

if [ $user_id -ne 0 ];then
    echo "Please run with sudo access"
    exit 1
fi

mkdir -p $logs_folder

timestamp(){
    date "+%F %T"
}

validate (){
    if [ $1 -ne 0 ]; then
        echo "$(timestamp) ${2} FAILED" | tee -a $logs_file
    else
        echo "$(timestamp) ${2} SUCCESS" | tee -a $logs_file
    fi    

}

echo " $(timestamp) script started "

dnf module disable nodejs -y &>>$logs_file
dnf module enable nodejs:24 -y  &>>$logs_file
dnf install nodejs -y &>>$logs_file
validate $? "installing nodejs"

id roboshop &>>$logs_file

if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "system user" roboshop &>>$logs_file
else
    echo " system user already created"
fi

rm -rf /app
validate $? "removing old directories"

mkdir -p /app
validate $? "creating a directory for app"

curl -L -o /tmp/cart.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/cart-v4.zip &>>$logs_file
validate $? "downloading cart details provided by developer"
cd /app
unzip /tmp/cart.zip &>> $logs_file

npm install &>> $logs_file
validate $? "installing dependecies"

sed -i "s/DOMAIN_NAME/$domain_name/g" "$script_dir/cart.service"
cp "$script_dir/cart.service" /etc/systemd/system/cart.service

systemctl daemon-reload &>>$logs_file
systemctl enable cart  &>>$logs_file
systemctl start cart  &>>$logs_file

vaidate $? "enabling and starting cart"

systemctl restart cart
validate $? "reststarting cart"

echo "$(timestamp) script completed in $SECONDS seconds"
echo "$(timestamp)========SCRIPT STOPPED====="








