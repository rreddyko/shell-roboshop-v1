#! /bin/bash

user_id=$(id -u)
logs_folder="/var/log/roboshop"
logs_file="${logs_folder}/${0}.log"
domain_name="rameshkotha572.online"
script_dir=$(dirname "$(realpath "$0")")

if [ $user_id -ne 0 ]; then
    echo "please run with SUDO access"
    exit 1
fi

mkdir -p $logs_folder

timestamp(){
    date "+%F %T"
}
validate(){
    if [ $1 -ne 0 ]; then
        echo -e "$(timestamp) ${2} failed " | tee -a &>>$logs_file
    else
        echo -e "$(timestamp) ${2} success " | tee -a &>>$logs_file
    fi
}

echo " $(timestamp) script started execution"

dnf module enable maven:3.9 -y &>>$logs_file
dnf install maven java-25-openjdk-devel -y &>>$logs_file
validate $? "Installing maven and java"

alternatives --set java "/usr/lib/jvm/java-25-openjdk/bin/java"
validate $? "selecting java 25 as default version"

echo "export JAVA_HOME=$(dirname $(dirname $(readlink -f /usr/bin/java)))" > /etc/profile.d/java.sh
source /etc/profile.d/java.sh
echo $JAVA_HOME

validate $? "setting home directory for maven"

id roboshop &>> $logs_file

if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "system user" roboshop &>>$logs_file
    validate $? "creating system user"
else
    echo "$(timestamp) system user already exists"
fi

rm -rf /app &>> $logs_file
validate $? "removing old files"

mkdir -p /app  $logs_file
validate $? "creating new dir"

curl -L -o /tmp/shipping.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/shipping-v4.zip &>>$logs_file
validate $? "downloading shipping data"

cd /app

unzip /tmp/shipping.zip &>> $logs_file
validate $? "unzipping shipping"

mvn clean package &>> $logs_file
validate $? "creating maven package"

mv target/shipping.jar shipping.jar

sed -i "s/DOMAIN_NAME/$domain_name" "$script_dir/shipping.service"

cp "$script_dir/shipping.service" /etc/systemd/system/shipping.service

dnf install mysql -y
validate $? "Installing mysql"

count=$(mysql -h "mysql.$domain_name" -u root -pRoboshop@1 -N -B -e "SELECT COUNT(*) FROM cities.cities;" 2>>$logs_file)

if [ -z "$count" ] || [ "$count" -eq 0 ]; then
    mysql -h "mysql.$domain_name" -u root -pRoboshop@1 < /app/db/master-data.sql
    validate $? "loading mysql data"
else
    echo "$(timestamp) master data already loaded"    
fi

mysql -h "mysql.$domain_name" -u root -pRoboshop@1 < /app/db/app-user.sql
validate $? "creating appuser i.e For shipping to access database for countries and cities"

systemctl daemon-reload &>> $logs_file
systemctl enable shipping &>> $logs_file
systemctl start shipping &>> $logs_file
systemctl restart shipping &>> $logs_file
validate $? " restart shipping service"







