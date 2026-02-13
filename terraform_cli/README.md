Terraform CLI

Install the terraform cli
Install the aws cli
Get access to your AWS environment
Setup your environment variables for access to your aws environment
```
AWS_ACCESS_KEY_ID=AKIAV2KYZ_GOES_HERE
AWS_SECRET_ACCESS_KEY=LJv+2wycnvUPI2n_GOES_HERE
export PS1 EDITOR AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
. ./.bashrc
```
Commands to develop your files
```
terraform fmt
terraform init
terraform validate
terraform plan
terraform apply
terraform destroy
```
Useful commands in trying to find amis
```
aws ec2 describe-images --query 'reverse(sort_by(Images, &CreationDate))[].[Name, ImageId, CreationDate]' --filters 'Name=name,Values=F5*BIGIP-*' --output table --region us-west-1
aws ec2 describe-images --image-ids ami-06253282a0376a081 --region us-west-1
```
