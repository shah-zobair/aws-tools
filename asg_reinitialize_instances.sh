#!/bin/bash

# Set Environment variable for AWS Access Key and Secret for this script as it requires aws-cli.

#export AWS_ACCESS_KEY_ID=XXXXXXXXXXXXX
#export AWS_SECRET_ACCESS_KEY=XXXXXXXXXXXXXX


# aws-cli installation steps

#rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
#yum install python-pip
#pip install awscli --upgrade --user


# Define your Auto Scaler Region. All ASG under this region will be set to 0 desired state.
# Also define the environment so that only that specific environment's (Tag) will be affected.
AWS_REGION=us-east-1
ENVIRONMENT=dev
DESIRED_CAPACITY=0

MIN_SIZE=$DESIRED_CAPACITY


aws --region=$AWS_REGION autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[?contains(Tags[?Key==\`Environment\`].Value, \`$ENVIRONMENT\`)].[AutoScalingGroupName]" --output text > /tmp/$AWS_REGION\_$ENVIRONMENT\_ASG

for ASG in `cat /tmp/$AWS_REGION\_$ENVIRONMENT\_ASG`; do

 echo "Scaling $ASG to $DESIRED_CAPACITY"

 aws --region=$AWS_REGION autoscaling update-auto-scaling-group --auto-scaling-group-name $ASG --min-size $MIN_SIZE --desired-capacity $DESIRED_CAPACITY 

done

echo ""
echo "Scaled ASG names has been stored in /tmp/"$AWS_REGION"_"$ENVIRONMENT"_ASG"
