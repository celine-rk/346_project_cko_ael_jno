#!/bin/bash

##############################################################################################################
# date: 12.12.2023                                                                                           #
# written by Celine König                                                                                    #
# This script facilitates the launch of an aws instance and runs a classical wordpress in it                 #
##############################################################################################################

# text formating
BOLD='\033[1m'                  # bold text
REGULAR=$(tput sgr0)            # regular text
GREEN='\033[0;32m'              # green color
NOCOLOR='\033[0m'               # no color

# variables webserver/wordpress instance
KEY_NAME="wordpress-key"        # used to create new key pair
INSTANCE_TYPE="t2.micro"        # is enough for a wordpress
SECURITY_GROUP="wordpress"      # Ändere dies zu deiner Security Group ID
IMAGE_ID="ami-08c40ec9ead489470" # Image-id of a classical ubuntu 22.04 image
REGION="us-east-1"              # standard region
INSTANCE_NAME="WPinstance"      # Instance name of the to be created instance
SSH_Path="~/.ssh/$KEY_NAME"     # path to ssh directory
EC2APACHE="ec2apache"         # path to created directory

# variables for Database server
DB_INSTANCE_NAME="WordPressDBInstance"     # Database instance name
DB_SECURITY_GROUP="database-wp"           # Security group for the database
DB_ROOT_PASSWORD="hI38sOpB20A"             # Change this to a secure root password
DB_INTERNAL_IP=""                           # Will be filled with the internal IP of the database instance

# short instruction
echo -e "This script is going to install $BOLD apache $REGULAR and initialize an $BOLD ubuntu ec2 instance $REGULAR in aws, to launch a casual worpress website"
read -p "Do you want to continue this script and configure an aws instance? [y/n]" ANSWER_CONTINUE
    if [[ "$ANSWER_CONTINUE" =~ [nN] ]]; then
        echo -e "You chose not to continue with this script, therefore the Script is closing $GREEN NOW! $NOCOLOR"
        exit 1
    fi

# creating ssh keypair 
echo -e "Creating a new ssh key-pair ..."
aws ec2 create-key-pair --key-name "$KEY_NAME" --key-type rsa --query "KeyMaterial" --output text > "$KEY_NAME.pem"

# create security group for webserver instance
aws ec2 create-security-group --group-name $SECURITY_GROUP --description "EC2-wordpress"
aws ec2 authorize-security-group-ingress --group-name $SECURITY_GROUP --protocol tcp --port 80 --cidr 0.0.0.0/0         # allow http connection
aws ec2 authorize-security-group-ingress --group-name $SECURITY_GROUP --protocol tcp --port 22 --cidr 0.0.0.0/0         # allow ssh connection

# create security group for the database
aws ec2 create-security-group --group-name $DB_SECURITY_GROUP --description "EC2-database"
aws ec2 authorize-security-group-ingress --group-name $DB_SECURITY_GROUP --protocol tcp --port 3306 --source-group "$WEB_SECURITY_GROUP"

# create a seperate directory for initial installation
echo -e "creating a new directory $BOLD ec2apache $REGULAR to make following steps easier"
if [[ -d "$EC2APACHE" ]]; then
    echo "Directory already exists directly switching into that directory"
    cd "$EC2APACHE"
elif [[ ! -d "$EC2APACHE" ]]; then
    mkdir "$EC2APACHE"
    cd "$EC2APACHE"
fi

# copying the apache.txt in the correct directory
echo -e "Where did you save the apache.txt file? Enter the $GREEN ABSOLUTE PATH $NOCOLOR to it " 
read PATH_APACHE

if [[ -f "$PATH_APACHE" ]]; then
    echo "The File exists going to move it into $EC2APACHE directory....."
    mv "$PATH_APACHE" "$EC2APACHE/apache.txt"
else 
    echo -e "The file doesn't exist or you copied the wrong path.
            Please make sure you copied the $GREEN absolute path $NOCOLOR from $GREEN apache.txt $NOCOLOR"
    while [[ ! "$changeAns" =~ [YyNn] ]]; do
        read -p "Wanna change your answer? [y/n]: " changeAns
        if [[ "$changeAns" =~ [Yy] ]]; then 
            read -p "Enter the ABSOLUTE PATH to apache.txt: " Newpath_apache
            set -- "${Newpath_apache[@]}"
            echo -e "the filepath from apache.txt has successfully been changed to $@"
            mv "$Newpath_apache" "$EC2APACHE/apache.txt"
            break
        fi
        if [[ "$changeAns" =~ [Nn] ]]; then
            echo "the filepath isn't correct, can't install apache within the instance. Going to close script now!"
            exit 1
        fi
    done
fi

# create aws webserver instance
aws ec2 run-instances --region "$REGION" --image-id "$IMAGE_ID" --instance-type "$INSTANCE_TYPE" --key-name "$KEY_NAME" --security-group-ids "$SECURITY_GROUP" --user-data file://apache.txt --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" --query 'Instances[0].InstanceId' 


# Wait until webserver instance is started
aws ec2 wait instance-running --instance-ids "$INSTANCE_ID" --region "$REGION"

# Get webserver instance information
Public_IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query 'Reservations[0].Instances[0].PublicIpAddress' --output text --region "$REGION")
  
# AWS EC2 Database-Instanz erstellen
aws ec2 run-instances --region "$REGION" --image-id "$IMAGE_ID" --instance-type "$INSTANCE_TYPE" --key-name "$KEY_NAME" --security-group-ids "$DB_SECURITY_GROUP" --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$DB_INSTANCE_NAME}]" --query 'Instances[0].InstanceId'

# Warten, bis die Datenbank-Instanz gestartet ist
aws ec2 wait instance-running --instance-ids "$db_instance_id" --region "$REGION"

# Daten db instanz abrufen 
DB_INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$DB_INSTANCE_NAME" --query 'Reservations[0].Instances[0].InstanceId' --output text)
DB_INTERNAL_IP=$(aws ec2 describe-instances --instance-ids ”$DB_INSTANCE_ID" --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text --region "$REGION")

# Konfiguration der Datenbank-Instanz
ssh -i "$KEY_NAME.pem" ubuntu@$DB_INTERNAL_IP
# MySQL-Server installieren und konfigurieren
sudo apt-get update
sudo apt-get install -y mysql-server
sudo mysql_secure_installation  # Hier wirst du nach dem sicheren Root-Passwort gefragt

# MySQL-Root-Benutzer mit sicherem Passwort erstellen
sudo mysql -e "CREATE USER 'root'@'%' IDENTIFIED BY '$DB_ROOT_PASSWORD';"
sudo mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;"
sudo mysql -e "FLUSH PRIVILEGES;"

# MySQL-Konfigurationsdatei bearbeiten, um externe Verbindungen zu ermöglichen
sudo sed -i 's/127.0.0.1/$DB_INTERNAL_IP/' /etc/mysql/mysql.conf.d/mysqld.cnf
sudo service mysql restart
EOF

# WordPress-Installationsskript an die Instanz senden und ausführen
scp -i "$KEY_NAME.pem" install-wordpress.sh ubuntu@$Public_IP:~/install-wordpress.sh
ssh -i "$KEY_NAME.pem" ubuntu@$Public_IP 'bash ~/install-wordpress.sh'

echo "WordPress-Instanz erstellt. Öffne http://$Public_IP im Browser, um die Konfiguration abzuschließen."
