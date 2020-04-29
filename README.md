# aws-sm

aws-sm (aws + session manager) is a shell script help you to connect to EC2 Instance via Active Installed SSM Agent on EC2 Instances from your local machine.

## Prerequisites
You need to install at least 3 tools on your local machine:

- [AWS CLI version 1]
- [Session Manager Plugin for AWS CLI]
- [jq on Linux] or [jq on MacOS]

On your **AWS Service** needs:

- Install SSM Agent on EC2 Instances and SSM Agent Service has to be active
- Attach IAM Instance Profile with permission SSM Role to EC2 Instances
- IAM User Account used for **AWS CLI** need to have permission to access AWS System Manager - Session Manager Service.

## Installation

Clone git soure script then place script in directory exists in $PATH Environment variables.

```
$ git clone https://github.com/cuongquach/aws-sm.git
$ chmod +x aws-sm.sh
$ mv aws-sm.sh /usr/local/bin/aws-sm
```

## Usage

**Notice**:
- Remember to expose your AWS Credentials via environment variables or config file with AWS CLI before run this script.
- You can combine this script with some credential tool like `aws-vault`.


```
$ aws-sm help
Usage: aws-sm <command> [<args> ...]

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
```

## Examples

List all EC2 Instances on your account with specific accounts.

```
$ aws-sm list
InstanceID           Status    PrivateIP      Name
i-00c017al34ke0a111  active    10.50.49.82    CuongQuach-Machine-1
i-074a779e193pq4359  active    10.50.62.203   CuongQuach-Machine-2
i-0c81de2666e49ea12  active    10.50.71.63    CuongQuach-Machine-3
```

Connect to EC2 Instance ID via Active Installed SSM Agent on EC2 Instance.

```
$ aws-sm connect i-00c017al34ke0a111

Starting session with SessionId: iam-user-cuongquach
sh-4.2$ sudo -i
[root@ip-10-50.49.82 ~]# whoami
root
```

[AWS CLI version 1]: https://docs.aws.amazon.com/cli/latest/userguide/install-cliv1.html
[Session Manager Plugin for AWS CLI]: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html
[jq on MacOS]: http://macappstore.org/jq/
[jq on Linux]: http://macappstore.org/jq/
