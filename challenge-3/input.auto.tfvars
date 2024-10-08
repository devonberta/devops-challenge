deployment = {
    name-prefix = "devops-challenge"
    vpc-cidr    = "10.0.0.0/16"
    public-cidrs = [
        "10.0.1.0/24", 
        "10.0.2.0/24", 
        "10.0.3.0/24"
    ]
    private-cidrs = [
        "10.0.101.0/24", 
        "10.0.102.0/24", 
        "10.0.103.0/24"
    ]
    ubuntu-image-id     = "ubuntu"
    max-instances   = 6
    min-instances   = 3
    starting-instances = 3
    region          = "us-east-1"
}

