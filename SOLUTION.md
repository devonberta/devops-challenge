# Notes

## Developed with:
The code was developed with and tested using the following tools:
* vscode
* Terraform v1.9.6
* Localstack v3.8.0
* dive 0.12.0
* terraform-local
* go version go1.23.2 darwin/arm64
* dockert desktop + kubernetes
* helm version.BuildInfo{Version:"v3.16.1", GitCommit:"5a5449dc42be07001fd5771d56429132984ab3ab", GitTreeState:"dirty", GoVersion:"go1.23.1"}

## Challenge-1 comments:

* development was on a Apple silicon mac
* For container build with this: GOOS=linux GOARCH=arm64 go build
* I am more practiced with golang so I created the web server application with it and complied for linux arm64 after testing on darwin arm64
* Health endpoint as part of the web server example to flush out the rendered manifest from the helm chart with a health check because it was easy to add and k8s deployments should have health checks

Validation commands run during testing:
* docker run -p 8000:2000 devonberta/devops-challenge:latest --port 2000
* curl -v localhost:8000
* curl -v localhost:8000/startupProbe
* curl -v localhost:8000/livenessProbe

Note on dive tests, seem to be broken in recent version invovling docker desktop github issue open here: https://github.com/wagoodman/dive/issues/507
Validated github action ran as expected and published to dockerhub.
Removed local docker images and forced a pull from the registry. Container ran as expected.
## Challenge-2 comments:

* Tested with docker destkop kubernetes instead of kind, minikube, or k3s
* built a terraform module for the helm chart also to manage deployment and include it here

## challenge-3 comments:

* Two example solutions provided: 
    * one is reusing aws maintianed modules and putting them into a deployment terraform which seems to be what was the expected approach
    * two is I made seperate modules form scratch for the resources that implemented a simplified model for deployment
* the reason of providing two approaches is to highlight that sometimes the existing modules introduce unnecessary complexity in managing of resources that can be solved with a purpose built solution
* based on the limited information in the diagram I gathered the desired resoruces where:
    * 1 vpc
    * 1 internet gateway
    * 1 load balancers configured for multi az across 3 azs
    * 3 nat instances
    * 1 autoscale group across 3 az's 
    * 3 private subnets spread across availablity zones
    * 1 nsg
    * 1 multi AZ RDS DB Cluster spread across 3 azs
    * 1 S3 bucket
* running the terraform I have not hard coded the region in the provider cofig. It is typical when run through ci/cd tools this value may need to be changed depending on destination deploying too. This can be set via environment variables instead along with credentials. 
* the alternative is to configure a provider for all the possible regions and use alias's when calling modules but did not implement that in this example
* commands:
    * AWS_ACCESS_KEY_ID="" AWS_SECRET_ACCESS_KEY="" AWS_REGION="us-east-1" terraform init
    * AWS_ACCESS_KEY_ID="" AWS_SECRET_ACCESS_KEY="" AWS_REGION="us-east-1" terraform plan -var 'db_password=my_password!'
    * AWS_ACCESS_KEY_ID="" AWS_SECRET_ACCESS_KEY="" AWS_REGION="us-east-1" terraform apply -var 'db_password=my_password!'