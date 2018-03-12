#!/bin/bash

#Developed by Shah Zobair <szobair@redhat.com>

# Set Environment variable for AWS Access Key and Secret for this script as it requires aws-cli.

#export AWS_ACCESS_KEY_ID=XXXXXXXXXXXXX
#export AWS_SECRET_ACCESS_KEY=XXXXXXXXXXXXXX


# aws-cli installation steps

#rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
#yum install python-pip
#pip install awscli --upgrade --user

#Please mention the desired state shutdown / poweron i.e: $./asg_scaling shutdown or $./asg_scaling poweron

# Define your Auto Scaler Region. All ASG under this region will be set to 0 desired state.
# Also define the environment so that only that specific environment's (Tag) will be affected.
AWS_REGION=us-east-1
ENVIRONMENT=dev

STATE=$1

if [ "$STATE" == "" ]; then

   echo "Please mention the desired state shutdown / poweron i.e: ./asg_scaling shutdown"

elif [ "$STATE" == "shutdown" ]; then
   echo "Shutting Down all Instances from Region '$AWS_REGION' and Environment '$ENVIRONMENT'"
   aws --region=$AWS_REGION autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[?contains(Tags[?Key==\`Environment\`].Value, \`$ENVIRONMENT\`)].[AutoScalingGroupName]" --output text > /tmp/$AWS_REGION\_$ENVIRONMENT\_ASG

   for ASG in `cat /tmp/$AWS_REGION\_$ENVIRONMENT\_ASG`; do
      aws --region=$AWS_REGION autoscaling describe-auto-scaling-groups --auto-scaling-group-name $ASG --output text | grep INSTANCES | cut -f4 > /tmp/$AWS_REGION\_$ENVIRONMENT\_$ASG\_INSTANCES
      for INSTANCE in `cat /tmp/$AWS_REGION\_$ENVIRONMENT\_$ASG\_INSTANCES`; do
         echo "Standby Instance: $INSTANCE from ASG: $ASG"
         aws --region=$AWS_REGION autoscaling enter-standby --instance-ids $INSTANCE --auto-scaling-group-name $ASG --should-decrement-desired-capacity
         echo "Waiting for 3 seconds..."
         sleep 3
         echo "Shutting Down Instance: $INSTANCE"
         aws --region=$AWS_REGION ec2 stop-instances --instance-ids $INSTANCE
      done
   done
   echo "Please do not remove following files as these will be required to Power On those instances and add back to the ASGs"
   echo "-----------"
   echo "/tmp/$AWS_REGION"_"$ENVIRONMENT"_ASG"
   echo "/tmp/$AWS_REGION"_"$ENVIRONMENT"_"$ASG"_INSTANCES"
   echo "-----------"

elif [ "$STATE" == "poweron" ]; then
   echo "Powering On all Instances in Region '$AWS_REGION' and Environment '$ENVIRONMENT'"
   for ASG in `cat /tmp/$AWS_REGION\_$ENVIRONMENT\_ASG`; do
      for INSTANCE in `cat /tmp/$AWS_REGION\_$ENVIRONMENT\_$ASG\_INSTANCES`; do
         echo "Power On $INSTANCE for $ASG"
         aws --region=$AWS_REGION ec2 start-instances --instance-ids $INSTANCE
         echo "Waiting for 3 seconds..."
         sleep 3
         echo "Adding back the Instance: $INSTANCE to ASG: $ASG"
         aws --region=$AWS_REGION autoscaling exit-standby --instance-ids $INSTANCE --auto-scaling-group-name $ASG
      done
   done

else
   echo "Please mention the desired state shutdown / poweron i.e: ./asg_scaling shutdown"
fi
