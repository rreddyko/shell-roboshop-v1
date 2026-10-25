#! /bin/bash

user_id=$(id -u)
logs_folder="/var/log/roboshop"
logs_file="${logs_folder}/${0}.log"
domain_name="rameshkotha572.online"
script_dir=$(dirname "(realpath "$0")")

if [ $user_id -ne 0 ]; then
    echo "please run with sudo access"
    exit 1
fi

mkdir -p $logs_folder

timestamp(){
    date "+%F %T"
}

validate(){

    if [ $1 ne 0 ];then
        echo " $(timestamp) ${2} FAILED" | tee -a $logs_file
    else
        echo " $(timestamp) ${2} SUCCESS" | tee -a $logs_file
    fi
}

echo "$(timestamp) script started "

dnf install python3.14 python3.14-pip -y &>> $logs_file
validate $? "Installing python 3.14"

id roboshop &>> $logs_file

if [ $? ne 0 ];
    useradd --system --home /app --shell /sbin/nologin --comment "system user" roboshop &>> $logs_file
    validate $? "creating system user"
else
    echo " provided user already exists"
fi

rm -rf /app
validate $? "removing old dir"

mkdir -p /app
validate $? "creating new app dir"

curl -L -o /tmp/payment.zip "creating app"https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/payment-v4.zip &>> $logs_file

cd /app

unzip /tmp/payment.zip
validate $? "unzipping payment"

python3.14 -m venv /app/.venv &>> $logs_file
validate $? "creating virtual env"

/app/.venv/bin/pip install -r requirements.txt &>> $logs_file
validate $? "installing dependecies"

sed -i "s/DOMAIN_NAME/$domain_name/g" "$script_dir/payment.service"

cp "$scripts_dir/payment.service" /etc/systemd/system/payment.service

systemctl daemon-reload &>> $logs_file
systemctl enable payment &>> $logs_file
systemctl restart payment &>> $logs_file
validate $? " restarting payment service"

echo "$(timestamp) script took $SECONDS seconds"
echo "$(timestamp)==========script completed======="



