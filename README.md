Datacenter 1 - A demo datacenter
=========
A virtual datacenter that can be with Ansible Automation Platform as well as the Terraform CLI.  This is a framework to deploy the infrastructure needed for many different customer use cases.

Notes
=========
1. This demo is designed to work with the Red Hat Demo Platform. Please see the aap.as.code repo below. [aap.as.code](https://github.com/ericcames/aap.as.code "aap.as.code")
2. This demo works with Amazon only currently.

Day 0 - Configuration as code (CAC) a repeatable build process for this demo
=========
This Datacenter 1 demo is part of the AAP bootstrap process found in item 1 above.

Prior to running the Setup - Datacenter 1 playbook
=========
Activate the subscriptions needed for Infoblox, F5, Palo Alto, appliances. Makes sure to do this logged into the AWS account where the provisioning will happen.
1. https://aws.amazon.com/marketplace/procurement/?offerId=3mxm4sgum7uvec7luih8suh79&productId=3d6f2259-6756-484c-ac5e-f2d9330afe95
2. https://aws.amazon.com/marketplace/procurement/?productId=cd5685be-9635-460e-9448-20bd5bead545&offerId=c5mtwrozlfns1fnawk1nvx2dh
3. https://aws.amazon.com/marketplace/procurement/?productId=f1260463-68e1-4bfb-bf2e-075c2664c1d7&offerId=e9yfvyj3uag5uo5j2hjikv74n

ec2 instances
=========
![alt text](https://github.com/ericcames/demo.datacenter/blob/main/docs/images/dc1_aws_instances.png "Images")