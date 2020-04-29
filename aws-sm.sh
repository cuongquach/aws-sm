#!/bin/bash
#Author: Quach Chi Cuong

set -e

usage_help()
{

cat <<HELP
Usage: aws-vault <command> [<args> ...]

Script help you to list ec2 instance with active ssm agent. Then you can connect ssh to EC2 Instance via Active Installed SSM Agent.

Available Commands:
  list        List all active ec2 instances in region.
  connect     Connect to EC2 Instance via active installed SSM Agent

Software dependencies:
  - AWS CLI
  - Session Manager Plugin for AWS CLI
  - jq

Examples:
  - aws-sm list
  - aws-sm connect <instance_id>

HELP
  exit 1

}

pre_check_dependencies(){
    # If not found tool AWS CLI v1 : aws => exit
    if [[ ! $(command -v aws) ]];then
        echo "[x] Not found tool [aws] on machine."
        echo "Exit."
        exit 1
    fi

    # If not found session manager plugin for AWS CLI : session-manager-plugin => exit
    if [[ ! $(command -v session-manager-plugin) ]];then
        echo "[x] Not found tool [session-manager-plugin] on machine."
        echo "Exit 1."
        exit 1
    fi

    # If not found : jq => exit
    if [[ ! $(command -v jq) ]];then
        echo "[x] Not found tool [jq] on machine."
        echo "Exit."
        exit 1
    fi
}

install_session_manager_plugin(){
    # This function is only for note

    # Only for macos
    curl -L "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac/sessionmanager-bundle.zip" -o "sessionmanager-bundle.zip"
    unzip sessionmanager-bundle.zip
    sudo ./sessionmanager-bundle/install -i /usr/local/sessionmanagerplugin -b /usr/local/bin/session-manager-plugin
}

list_ec2_instances()
{
    # Get list ec2 instances and tag name
    LIST_EC2_INSTANCES=$(aws ec2 describe-instances --filters "Name=instance-state-code,Values=16" --output json | jq '.Reservations[].Instances[]' | jq '{name: .Tags[] | select(.Key=="Name") | .Value, instance_id: .InstanceId, private_ip: .NetworkInterfaces [0].PrivateIpAddress}' | jq -r '[.instance_id, .private_ip, .name]|@tsv' | sort -k3,3)

    # Get list ec2 instances with active installed ssm agent
    LIST_ACTIVE_SSM_EC2_INSTANCES=$(aws ssm describe-instance-information | jq '.InstanceInformationList[] | select(.PingStatus=="Online")' | jq '{instance_id: .InstanceId}' | jq -r '[.instance_id]|@tsv')

    # Determine ec2 has active or inactive/unknown ssm agent
    {
        echo -e "InstanceID\tStatus\tPrivateIP\tName"
        echo ""

        while IFS= read -r line; do
            info_instance_id=$(echo $line | awk '{print $1}')
            info_instance_meta_ip=$(echo $line | awk '{print $2}')
            info_instance_meta_tagname=$(echo $line | awk '{print $3}')

            # If found instance_id in list active ssm agent instances id
            # So: that instance_id is active
            if [[ $(grep -i ${info_instance_id} <<< ${LIST_ACTIVE_SSM_EC2_INSTANCES}) ]];then
                status="active"
            else
                status="inactive"
            fi

            # Print out information
            echo -e "${info_instance_id}\t${status}\t${info_instance_meta_ip}\t${info_instance_meta_tagname}"
        done <<< "$LIST_EC2_INSTANCES"

    } | column -t -s $'\t'
}

aws_ssm_connect_instance(){
    aws ssm start-session --target $AWS_INSTANCE_ID
}

# Main functions

if [[ "$#" -lt 1 ]];then
    echo -e "Error: missing arguments\n"
    usage_help
fi

if [[ "$#" -gt 2 ]];then
    echo -e "Error: over supported arguments\n"
    usage_help
fi

if [[ "$#" -eq 1 ]];then
    if [[ $1 == "help" ]];then
        usage_help
    fi

    if [[ $1 == "connect" ]];then
        echo -e "Error: are you missing args <instance_id> with command <connect> \n"
        usage_help
    fi

    if [[ $1 != "list" ]];then
        echo -e "Error: unsupported command <$1> \n"
        usage_help
    fi
fi

if [[ "$#" -eq 2 ]];then
    if [[ $1 != "connect" ]];then
        echo -e "Error: unsupported command <$1> \n"
        usage_help
    fi

    if [[ ! $(echo $2 | grep "^i-") ]];then
        echo -e "Error: wrong syntax aws <instance_id> with command <connect> \n"
        usage_help
    fi
fi

# Assign variables from args
OPTION="$1"
AWS_INSTANCE_ID="$2"

# Checking supported tool on local machine
pre_check_dependencies

# Action based on $OPTION arg
case $OPTION in
  "list")
    list_ec2_instances
    ;;

  "connect")
    aws_ssm_connect_instance
    ;;

  *)
    echo -n "Error: Something wrong"
    usage_help
    ;;
esac

exit 0
