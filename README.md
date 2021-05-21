## Deploy [Binderhub](https://binderhub.readthedocs.io/en/latest/index.html) on EC2 with Terraform

Create a file called "terraform.tfvars" with the content:

```
region             = "<AWS region>" (defaults to eu-west-2)
ami                = "<Ubuntu AMI for this region>" (defaults to ami-0194c3e07668a7e36)
key_name           = "<your key name>"
key_path           = "<path to your private key>"
dockerhub_username = "<your Dockerhub username>"
dockerhub_password = "<your Dockerhub password>"
```

Then run

```
terraform init
terraform apply
```

and take note of the URLs that are output at the end of the installation process.

(Don't forget to run ```terraform destroy``` when you have finished with it!)

You can run a Kubernetes dashboard by logging on to the instance with SSH, runnning ```sudo minikube dashboard --url``` and forwarding the appropriate port.

If you want to install Binderhub from a particular repo or branch, you can uncomment the ```# install dev version``` section in ```bootstrap.sh``` and comment out the ```# install prod version``` section.