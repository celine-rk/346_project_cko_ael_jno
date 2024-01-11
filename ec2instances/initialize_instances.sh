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
DB_PRIVATE_IP="172.31.10.15"

# VPC CIDR-Block für neu erstelltes subnet
CIDR_BLOCK="172.31.10.0/24"

# Erster Check, ob AWS CLI installiert ist
if command -v aws &> /dev/null; then
    echo -e "AWS CLI is installed. $GREEN $BOLD NEXT STEP: $REGULAR $NOCOLOR initializing instances for wordpress."
    aws --version
else
    echo -e "AWS CLI is not installed. Should this script install the $GREEN $BOLD AWS CLI $REGULAR $NOCOLOR for you? [y/n]: "
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

# Neues VPC erstellen und deren ID in Variable VPC_ID hinzufügen
echo -e "create $GREEN new vpc $NOCOLOR....."

VPC_ID=$(aws ec2 create-vpc --cidr-block "$CIDR_BLOCK" --query 'Vpc.VpcId' --output text)

# Neues Subnet erstellen
echo -e "creating $GREEN new subnet $NOCOLOR....."
SUBNET_ID=$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block "$CIDR_BLOCK" --query 'Subnet.SubnetId' --output text)

# Sicherheitsgruppen für die Webserver-Instanz erstellen (id anstelle von namen übergeben)
echo -e "Creating $GREEN webserver security group $NOCOLOR..."
WP_SECURITY_GROUP_ID=$(aws ec2 create-security-group --group-name "$WP_SECURITY_GROUP" --description "EC2-wordpress" --vpc-id "$VPC_ID" --query 'GroupId' --output text)
aws ec2 authorize-security-group-ingress --group-id "$WP_SECURITY_GROUP_ID" --protocol tcp --port 80 --cidr 0.0.0.0/0  # HTTP-Verbindung erlauben
aws ec2 authorize-security-group-ingress --group-id "$WP_SECURITY_GROUP_ID" --protocol tcp --port 22 --cidr 0.0.0.0/0  # SSH-Verbindung erlauben

# Sicherheitsgruppen für die Datenbank-Instanz erstellen 
echo -e "Creating $GREEN database security group $NOCOLOR..."
DB_SECURITY_GROUP_ID=$(aws ec2 create-security-group --group-name "$DB_SECURITY_GROUP" --description "EC2-database" --vpc-id "$VPC_ID" --query 'GroupId' --output text)
aws ec2 authorize-security-group-ingress --group-id "$DB_SECURITY_GROUP_ID" --protocol tcp --port 3306 --source-group "$WP_SECURITY_GROUP_ID"
aws ec2 authorize-security-group-ingress --group-id "$DB_SECURITY_GROUP_ID" --protocol tcp --port 22 --source-group "$WP_SECURITY_GROUP_ID"

#  Elastic Network Interface (ENI) für die Webserver-Instanz erstellen

# Elastische IPv4-Adresse erstellen
echo -e "Creating $GREEN elastic IPv4 for webserver-instance $NOCOLOR..."
ALLOCATION_ID=$(aws ec2 allocate-address --domain vpc --query 'AllocationId' --output text)

# Netzwerkschnittstelle erstellen (inklusive Zuordnung der elastischen IPv4-Adresse)
echo -e "Creating $GREEN network interface for webserver instance $NOCOLOR..."
ENI_ID_WEB=$(aws ec2 create-network-interface --subnet-id "$SUBNET_ID" --groups "$WP_SECURITY_GROUP_ID"  --query 'NetworkInterface.NetworkInterfaceId' --output text)

# Internet GW erstellen
echo -e "Creating $GREEN internet GW $NOCOLOR..."
IGW_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)

# GW an VPC attachen
echo -e "attaching $GREEN GW to VPC $NOCOLOR..."
aws ec2 attach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID"

# Routing Tabelle abfragen (für die ID) und anschliessend dem GW anpassen
echo -e "Updating $GREEN Routing Tables $NOCOLOR..."
ROUTE_TABLE_ID=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values="$VPC_ID"" --query 'RouteTables[*].RouteTableId' --output text)
aws ec2 create-route --route-table-id "$ROUTE_TABLE_ID" --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW_ID"

# Elastische IPv4-Adresse der Netzwerkschnittstelle zuordnen (Kommunikation nach aussen für Webserver)
echo -e "attaching $GREEN IP to network interface from webserver $NOCOLOR..."
aws ec2 associate-address --allocation-id "$ALLOCATION_ID" --network-interface-id "$ENI_ID_WEB"

# AWS EC2-Datenbankinstanz erstellen und ENI zuweisen
echo -e "Creating $GREEN database instance $NOCOLOR..."

# DB Instanz erstellen
aws ec2 run-instances --region "$REGION" --image-id "$IMAGE_ID" --instance-type "$INSTANCE_TYPE" --key-name "$KEY_NAME" --network-interfaces "DeviceIndex=0,SubnetId="$SUBNET_ID",Groups="$DB_SECURITY_GROUP_ID",PrivateIpAddress="$DB_PRIVATE_IP"" --user-data file://cloudconfig-db.yaml --no-associate-public-ip-address --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$DB_INSTANCE_NAME}]"

# ID der Datenbankinstanz abrufen
DB_INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values="$DB_INSTANCE_NAME"" --query 'Reservations[0].Instances[0].InstanceId' --output text --region "$REGION")

# Warten, bis die Datenbankinstanz läuft
aws ec2 wait instance-running --instance-ids "$DB_INSTANCE_ID" --region "$REGION"

# AWS Webserver/WordPress-Instanz erstellen und Network interface zu weisen
aws ec2 run-instances --region "$REGION" --image-id "$IMAGE_ID" --instance-type "$INSTANCE_TYPE" --key-name "$KEY_NAME" --network-interfaces "NetworkInterfaceId="$ENI_ID_WEB",DeviceIndex=0" --user-data file://cloudconfig-web.yaml --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value="$WP_INSTANCE_NAME"}]"

# ID der Webserverinstanz abrufen
WP_INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values="$WP_INSTANCE_NAME"" --query 'Reservations[0].Instances[0].InstanceId' --output text --region "$REGION")

# Warten, bis die Webserverinstanz läuft
aws ec2 wait instance-running --instance-ids "$WP_INSTANCE_ID" --region "$REGION"

# Öffentliche IP der Webserverinstanz abrufen
WPPUBLICIP=$(aws ec2 describe-instances --instance-ids "$WP_INSTANCE_ID" --query 'Reservations[0].Instances[0].PublicIpAddress' --output text --region "$REGION")

# Ende und Ausgabe der öffentlichen IP zur Wordpress Seite
echo -e "Die Reihenfolge der Befehle ist wichtig! Die Verbindung zwischen der Webserver-Instanz und der DB-Instanz kann nur geprüft werden, wenn eine $GREEN SSH-Verbindung $NOCOLOR auf den $GREEN Webserver $NOCOLOR erfolgte"

echo -e "WordPress-Instanz erstellt. Öffne $GREEN http://"$WPPUBLICIP" $NOCOLOR im Browser, um die Konfiguration abzuschließen."

# SSH Verbindungen zu Instanzen
echo -e "Eine Verbindung zur Webserver-Instanz via ssh kann wie folgt vorgenommen werden: $BOLD ssh -i "$KEY_NAME".pem ubuntu@"$WPPUBLICIP" $REGULAR"

# Datenbank Verbindung zu Webserver herstellen reihenfolge wechseln
echo -e "Datenbank-Instanz wurde erstellt. Über folgenden Befehl kann die Kommunikation von Webserver zu DB geprüft werden: $BOLD mysql -h  $GREEN "$DB_PRIVATE_IP "$NOCOLOR -u $GREEN wpuser $NOCOLOR -p $REGULAR" 
echo -e "Das PW für $BOLD wpuser $REGULAR lautet: $BOLD X4#L6LwrN4V!w4&m^6pH98Li $REGULAR " 

echo -e "Eine Verbindung zur Datenbank-Instanz via ssh kann wie folgt vorgenommen werden: $BOLD ssh -i "$KEY_NAME".pem ubuntu@"$DB_PRIVATE_IP" $REGULAR"