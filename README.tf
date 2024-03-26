# Define provider
provider "aws" {
  region = "us-east-1"  # Specify your desired region
}

# Create EC2 instance
resource "aws_instance" "my_ec2_instance" {
  ami                    = "ami-080e1f13689e07408"  # Specify your desired Ubuntu AMI
  instance_type          = "t2.micro"
  key_name               = "Downloads/newk8"  # Specify your key pair
  subnet_id              = "subnet-0e72377fa6b71572d"  # Specify your subnet ID
  associate_public_ip_address = true
  tags = {
    Name = "i-0d71911d942ea6d59"
  }
}

# Wait for the instance to be ready
data "aws_instance" "my_ec2_instance_data" {
  depends_on = [aws_instance.my_ec2_instance]
  instance_id = aws_instance.my_ec2_instance.id
}

# Install Docker
provisioner "remote-exec" {
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("Downloads/K8.pem")  # Specify the path to your private key
    host        = aws_instance.my_ec2_instance.public_ip
  }

  inline = [
    "sudo apt-get update",
    "sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common",
    "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
    "sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\"",
    "sudo apt-get update",
    "sudo apt-get install -y docker-ce",
    "sudo usermod -aG docker ubuntu",  # Add the ubuntu user to the docker group
    "sudo systemctl enable docker",
    "sudo systemctl start docker"
  ]
}

# Install Kubernetes
provisioner "remote-exec" {
  depends_on = [provisioner.remote-exec]
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("Downloads/K8.pem")  # Specify the path to your private key
    host        = aws_instance.my_ec2_instance.public_ip
  }

  inline = [
    "sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -",
    "sudo cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list",
    "deb https://apt.kubernetes.io/ kubernetes-xenial main",
    "EOF",
    "sudo apt-get update",
    "sudo apt-get install -y kubelet kubeadm kubectl",
    "sudo apt-mark hold kubelet kubeadm kubectl",
    "sudo systemctl enable kubelet",
    "sudo systemctl start kubelet"
  ]
}
