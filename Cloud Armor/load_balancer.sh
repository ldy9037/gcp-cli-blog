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