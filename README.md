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

Note that currently all the ports between 30000 and 40000 are opened in the security group, as the Binderhub and Jupyterhub ports are not known a priori*. The respective ports can be found in ```~/binderhub_port``` and ```~/jupyterhub_port``` and Terraform could be configured to only open these, but this would require a second "apply".

At the end of the ```bootstrap.sh``` is a commented out section that allows you to install Binderhub from a forked repo for testing purposes.

\* While it is possible to configure the Jupterhub port, it doesn't appear to be possible to do this with the Binderhub port.