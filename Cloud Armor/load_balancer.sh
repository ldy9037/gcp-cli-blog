# gcloud에 사용될 사용자 정보 설정
gcloud auth login

# Project 설정
gcloud config set project <project_id>

# VPC 생성
gcloud compute networks create emadam-test-vpc \
    --subnet-mode=custom

# Subnet 생성
gcloud compute networks subnets create emadam-test-subnet \
    --network=emadam-test-vpc \
    --range=192.168.0.0/24 \
    --region=asia-northeast3

# Cloud Router 생성
gcloud compute routers create emadam-test-router \
    --network=emadam-test-vpc \
    --region=asia-northeast3

# NAT 생성
gcloud compute routers nats create emadam-test-nat \
    --router=emadam-test-router \
    --auto-allocate-nat-external-ips \
    --nat-all-subnet-ip-ranges \
    --region=asia-northeast3

# VM Instance 생성
gcloud compute instances create emadam-test-vm \
--zone=asia-northeast3-a \
--machine-type=e2-micro \
--subnet=emadam-test-subnet \
--no-address \
--image=rocky-linux-8-optimized-gcp-v20240611 \
--image-project=rocky-linux-cloud \
--boot-disk-size=20GB \
--boot-disk-type=pd-balanced \
--boot-disk-device-name=emadam-test-vm \
--scopes=cloud-platform \
--metadata-from-file=startup_script=./startup_script.sh
