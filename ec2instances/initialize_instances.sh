#!/bin/bash

##############################################################################################################
# date: 15.12.2023                                                                                           #
# written by Celine König                                                                                    #
# This script facilitates the launch of ec2 instances with a wordpress on top. In total there will be        # 
# instances, one for the database and another for the webserver                                              #
##############################################################################################################

# Textformatierung
BOLD='\033[1m'                  # fett gedruckter Text
REGULAR=$(tput sgr0)            # normaler Text
GREEN='\033[0;32m'              # grüne Farbe
NOCOLOR='\033[0m'               # keine Farbe

# Region für beide Instanzen
REGION="us-east-1"

# Abbildungs-ID für Ubuntu 22.04
IMAGE_ID="ami-08c40ec9ead489470"

# Instanztyp für die EC2-Instanzen
INSTANCE_TYPE="t2.micro"

# Name für den EC2-Schlüsselpaar
KEY_NAME="wordpress-key"

# Sicherheitsgruppen für die Webserver-Instanz und die Datenbank-Instanz
WP_SECURITY_GROUP="wp-sec-group"
DB_SECURITY_GROUP="db-sec-group"

# Name für die Datenbank-Instanz und die Webserver-Instanz
DB_INSTANCE_NAME="DB-Wordpress"
WP_INSTANCE_NAME="WP-Webserver"

# private ip für db instanz
DB_PRIVATE_IP="172.31.64.10"

# Erster Check, ob AWS CLI installiert ist
if command -v aws &> /dev/null; then
    echo -e "AWS CLI is installed. $GREEN NEXT STEP: $NOCOLOR initializing instances for wordpress."
    aws --version
else
    echo -e "AWS CLI is not installed. Should this script install the $GREEN AWS CLI $NOCOLOR for you? [y/n]: "
    read INSTALL_AWS
    if [[ "$INSTALL_AWS" =~ [yY] ]]; then
        # Installiere AWS CLI
        echo -e "Installing AWS CLI..."
        sudo apt-get install awscli
        echo -e "AWS CLI installed successfully."
    else
        echo -e "AWS CLI is required for this script. Please install it manually and rerun the script. Exiting now."
        exit 1
    fi
fi

# Kurze Einführung
echo -e "This script is going to install $BOLD Apache $REGULAR and initialize an $BOLD Ubuntu EC2 instance $REGULAR in AWS to launch a casual WordPress website."
read -p "Do you want to continue this script and configure an AWS instance? [y/n]" ANSWER_CONTINUE
if [[ "$ANSWER_CONTINUE" =~ [nN] ]]; then
    echo -e "You chose not to continue with this script. Therefore, the script is closing $GREEN NOW! $NOCOLOR"
    exit 1
fi

# Erstellen des SSH-Schlüsselpaars
echo -e "Creating a new SSH key-pair..."
aws ec2 create-key-pair --key-name "$KEY_NAME" --key-type rsa --query "KeyMaterial" --output text > "$KEY_NAME.pem"

# Sicherheitsgruppen für die Webserver-Instanz erstellen
aws ec2 create-security-group --group-name "$WP_SECURITY_GROUP" --description "EC2-wordpress"
aws ec2 authorize-security-group-ingress --group-name "$WP_SECURITY_GROUP" --protocol tcp --port 80 --cidr 0.0.0.0/0  # HTTP-Verbindung erlauben
aws ec2 authorize-security-group-ingress --group-name "$WP_SECURITY_GROUP" --protocol tcp --port 22 --cidr 0.0.0.0/0  # SSH-Verbindung erlauben

# Sicherheitsgruppen für die Datenbank-Instanz erstellen
aws ec2 create-security-group --group-name "$DB_SECURITY_GROUP" --description "EC2-database"
aws ec2 authorize-security-group-ingress --group-name "$DB_SECURITY_GROUP" --protocol tcp --port 3306 --source-group "$WP_SECURITY_GROUP"

# Elastic Network Interface (ENI) für die Datenbank-Instanz erstellen
ENI_ID=$(aws ec2 create-network-interface --subnet-0fcde7cae9536c1ab --private-ip-address "$DB_PRIVATE_IP" --query 'NetworkInterface.NetworkInterfaceId' --output text)

# AWS EC2-Datenbankinstanz erstellen und ENI zuweisen
aws ec2 run-instances --region "$REGION" --image-id "$IMAGE_ID" --instance-type "$INSTANCE_TYPE" --key-name "$KEY_NAME" --security-group "$DB_SECURITY_GROUP" --network-interfaces "NetworkInterfaceId=$ENI_ID,DeviceIndex=0" --user-data file://cloudconfig-db.yaml --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$DB_INSTANCE_NAME}]" 

# ID der Datenbankinstanz abrufen
DB_INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$DB_INSTANCE_NAME" --query 'Reservations[0].Instances[0].InstanceId' --output text --region "$REGION")

# Warten, bis die Datenbankinstanz läuft
aws ec2 wait instance-running --instance-ids "$DB_INSTANCE_ID" --region "$REGION"

# Private IP der Datenbankinstanz abrufen
DB_INTERNAL_IP=$(aws ec2 describe-instances --instance-ids "$DB_INSTANCE_ID" --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text --region "$REGION")

# AWS Webserver/WordPress-Instanz erstellen
aws ec2 run-instances --region "$REGION" --image-id "$IMAGE_ID" --instance-type "$INSTANCE_TYPE" --key-name "$KEY_NAME" --security-group "$WP_SECURITY_GROUP" --user-data file://cloudconfig-web.yaml --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$WP_INSTANCE_NAME}]"

# ID der Webserverinstanz abrufen
WP_INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$WP_INSTANCE_NAME" --query 'Reservations[0].Instances[0].InstanceId' --output text --region "$REGION")

# Warten, bis die Webserverinstanz läuft
aws ec2 wait instance-running --instance-ids "$WP_INSTANCE_ID" --region "$REGION"

# Öffentliche IP der Webserverinstanz abrufen
WPPUBLICIP=$(aws ec2 describe-instances --instance-ids "$WP_INSTANCE_ID" --query 'Reservations[0].Instances[0].PublicIpAddress' --output text --region "$REGION")

echo "WordPress-Instanz erstellt. Öffne http://$WPPUBLICIP im Browser, um die Konfiguration abzuschließen."



