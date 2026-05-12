Terraform cli setup
==================

Clone this repo to your computer
```
git clone git@github.com:ericcames/demo.datacenter.git
```
Install the terraform cli, the aws cli, and direnv
```
sudo dnf install terraform awscli direnv
```
Hook direnv into your shell (one-time)
```
echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
exec bash
```
Copy the example env file and fill in your AWS credentials
```
cp ../.envrc.example ../.envrc
$EDITOR ../.envrc
direnv allow ..
```
AWS credentials and `AWS_DEFAULT_REGION` now load automatically whenever you `cd` into the repo and unload when you leave.

If you already have a named profile in `~/.aws/credentials`, set `AWS_PROFILE` in `.envrc` instead of access keys — see the comments in `.envrc.example`.

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
aws ec2 describe-images --query 'reverse(sort_by(Images, &CreationDate))[].[Name, ImageId, CreationDate]' --filters 'Name=name,Values=F5*BIGIP-*' --output table
aws ec2 describe-images --image-ids ami-06253282a0376a081
```
