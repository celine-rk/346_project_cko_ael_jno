#!/bin/bash

##############################################################################################################
# date: 12.12.2023                                                                                           #
# written by Celine König                                                                                    #
# This script facilitates the launch of an aws instance and runs a classical wordpress in it                 #
##############################################################################################################

# variables
BOLD='\033[1m'                  # bold text
REGULAR=$(tput sgr0)            # regular text
GREEN='\033[0;32m'              # green color
NOCOLOR='\033[0m'               # no color
KEY_NAME="wordpress-key"        # used to create new key pair
INSTANCE_TYPE="t2.micro"        # is enough for a wordpress
SECURITY_GROUP="wordpress"      # Ändere dies zu deiner Security Group ID
IMAGE_ID"ami-08c40ec9ead489470" # Image-id of a classical ubuntu 22.04 image
REGION="us-east-1"              # Ändere dies z
INSTANCE_NAME="WPinstance"      # Instance name of the to be created instance
SSH_Path="~/.ssh/$KEY_NAME"
EC2APACHE="~/ec2apache"

# short instruction
echo -e "This script is going to install $BOLD apache $REGULAR and initialize an $BOLD ubuntu ec2 instance $REGULAR in aws, to launch a casual worpress website"
read -p "Do you want to continue this script and configure an aws instance? [y/n]" ANSWER_CONTINUE
    if [[ "$ANSWER_CONTINUE" =~ [nN] ]]; then
        echo -e "You chose not to continue with this script, therefore the Script is closing $GREEN NOW! $NOCOLOR"
        exit 1
    fi

# creating ssh keypair 
echo -e "Creating a new ssh key-pair ..."
aws ec2 create-key-pair --key-name $KEY_NAME --key-type rsa --query "KeyMaterial" --output text > "~/$SSH_Path.pem"

# create security group

aws ec2 create-security-group --group-name $SECURITY_GROUP --description "EC2-wordpress"
asw ec2 authorize-security-group-ingress --group-name $SECURITY_GROUP --protocol tcp --port 80 --cidr 0.0.0.0/0         # allow http connection
asw ec2 authorize-security-group-ingress --group-name $SECURITY_GROUP --protocol tcp --port 22 --cidr 0.0.0.0/0         # allow ssh connection

# create a seperate directory for initial installation
echo -e "creating a new directory $BOLD ec2apache $REGULAR to make following steps easier"
mkdir $EC2APACHE
cd $EC2APACHE

# copying the apache.txt in the correct directory
echo -e "Where did you save the apache.txt file? Enter the $GREEN ABSOLUTE PATH $NOCOLOR to it " 
read PATH_APACHE

if [[ -f "$PATH_APACHE" ]]; then
    echo "The File existis goint to move it into $EC2APACHE directory....."
    mv $PATH_APACHE $EC2APACHE
else 
    echo -e "The file doesn't exist or you copied the wrong path.
            Please make sure you copied the $GREEN absolute path $NOCOLOR from $GREEN apache.txt $NOCOLOR"
    while [[ ! "$changeAns" =~ [YyNn] ]]; do
        read -p "Wanna change your answer? [y/n]: " changeAns
        if [[ "$changeAns" =~ [Yy] ]]; then 
            read -p "Enter the ABSOLUTE PATH to apache.txt: " Newpath_apache
            set -- "${Newpath_apache[@]}"
            echo -e "the filepath from apache.txt has successfully been changed to $@"
            break
        fi
        if [[ "$changeAns" =~ [Nn] ]]; then
            echo "the filepath isn't correct, can't install apache within the instance. Going to close script now!"
            exit 1
        fi
    done
fi
# create aws instance
INSTANCE_ID=$(aws ec2 run-instances --region $REGION --image-id $IMAGE_ID \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --security-group-ids $SECURITY_GROUP \
  --user-data file://apache.txt \                                                                 
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" \
  --query 'Instances[0].InstanceId' \
  --output text)

# Wait until insance is started
aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $REGION

# Get instance information
Public_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text \
  --region $REGION)

# WordPress-Installationsskript an die Instanz senden und ausführen
scp -i "$KEY_NAME.pem" install-wordpress.sh ubuntu@$Public_IP:~/install-wordpress.sh
ssh -i "$KEY_NAME.pem" ubuntu@$Public_IP 'bash ~/install-wordpress.sh'

echo "WordPress-Instanz erstellt. Öffne http://$Public_IP im Browser, um die Konfiguration abzuschließen."

