# Web-Application Hosting on AWS with Terraform

**Version: v1.0**

Hi from Asif,

This is the asignment project of simple Web-App hosting on AWS cloud platform using terraform.
In this assignment we are deploying a highly available and in-control infrastructure to run in backend. Which will provide us a robust design ready to deploy on any AWS account. You just have to maintaine the below listed pre-requisites and it will boom in the end with the end-point URL for the WebApp page.

```
In the end this deployment will provide us;
1. A Robust, Highly Available, In-Control AWS Infrastructure
2. An ALB Endpoint URL
3. An email in your mailbox for SNS subscription
4. A WebPage with AWS-Architecture Design used for this assignment
```

---
## Pre-requisites before applying changes

> Provide your user credentials to terraform before deployment

> The code was build with 0.14.7 (v14) version of Terraform which is compatible with mentioned v12 and later

> Probably you will receive an email from AWS for SNS subscription which will give you the Monitoring alerts

---
## Design Considerations

> You can find the AWS Architecture Design on the deployed WebApplication after hitting the endpoint or else you can find it at the link: https://github.com/Asif-Patel/AWS-WebApp-Hosting-Module/blob/main/demo/img/AWS-WebApp-Hosting.png?raw=true

I have chosen the AWS Standalone Infra Architecture to go for this assignment which will fullfill the requirments as mentioned in the email/assignment.

> Please find below highlighted parameters I took in consideration while building this deployment including points from extra credit:

* **VPC Scaling/Growth :** I have taken a CIDR range of `/24` which is provide 256 IPs for allocation. Out of these 265 IPs, I have given the range of `/26` for each Public Subnet and `/27` for each Private Subnet. As my design is having 2 Public and 2 Private subnets so it will obtain total 192 IPs in combain and we will still have `64` IPs unallocated for future growth or scaling.*

* **WEB Server - AMI :** I have chosen a Linux AMI and used the AWS Managed Value from `AWS-SSM Parameter Store`. I have pulled the value from the records and assigned it in the Launch Configuration which will provide us the `Latest AMI Id from AWS Market Place`.

* **WEB Server - SSH Access :** As its mentioned explicit in requirments, I have not provided any kind of `SSH_Key` or `tcp:22` traffic to SSH inside the server. Rather, I choose to manage the EC2 server with `AWS Systems Manager`. I have attached a EC2-IAM-Role to the server which is allow SSM access to the EC2 server along with SSMInstanceRole policy. So that we can manage our EC2 server remotely from SSM without SSH to it.

* **WEB Server - Security Group :** As the SSH is indeed not required for our Web Server hence I have allowed the EC2-SG to `only port 80(HTTP)` and for optional 443(HTTPS) only in our design.

* **Encryption at Rest - EBS Volumes :** I have chosen a `AWS provided default encryption at EBS` level to encrypt the data of Web Server. I have added *root volume* as well as *secondary volume* of `10GB of gp2` type. We can use the `Custome KMS Key` as well to encrypt the data followed by the limited access to the EC2 users only.

* **Alarm Mechanism for Monitoring :** In this bullet, I have created `two Alert mechanisms` for monitoring of this Infrastrucutre. First, to monitor the `Healtcheck of endpoint of ALB`. And the second one for `the monitoring of ASG`, which will notify us if our EC2 is having high load, when our EC2 will launch/termiante/stop or for any launch/termination ERRORS. This will throw and `SNS notification` to the subscribers listed *(currently You and Me)*. 

* **Auto Scaling :** After monitoring this ASG and after getting a notification to us, this Infra is designed in such a way that it will `Scale-in` or `Scale-out` based on the *obtaining load* (the threshold given is 80% CPU) and also based on the *Desired Capacity* which is 1-1-1 currently.

* **Log Mechanism :** I have designed it like we can store our `ALB traffic logs to the S3 bucket` directly. So that we can record all the logs from ALB along with the endpints hitting the ALB endpoints. This is currently commented out in the script as while destroying we explicitly required to empty the S3-bucket. The code used is;

```
    access_logs {
    bucket  = aws_s3_bucket.alb-logs.bucket
    prefix  = "webapp-alb"
    enabled = true
  }
```


---
## AWS Resources to be created

Resource Name | Qty | Resource Name | Qty | Resource Name | Qty
--- | --- | --- | --- | --- | ---
*VPC* | *1* | *IAM Role* | *1* | *LB Listner* | *1*
*Public-Subnet* | *2* | *Security Groups* | *2* | *LB Target Group* | *1*
*Private-Subnet* | *2* | *Launch Config* | *1* | *SNS Topic* | *1*
*Route Table* | *2* | *AutoScaling Group* | *1* | *SNS Subscriptions* | *2*
*IGW* | *1* | *EC2* | *1* | *ASG Healthcheck Monitor* | *1*
*NAT Gateway* | *1* | *Application LB* | *1* | *ALB End-URL Monitor* | *1*

---
## Contributor

- Asif Alam Patel --> <patelasif8600@gmail.com>

---
## License & copywrite

- © Asif Patel, AWS DevOps Engineer
---

> Thank you so much for your time !!!
> See you soon !!!
