#!/bin/bash

# ubuntu image 기반의 Instance Template 생성
gcloud compute instance-templates create study-web-dev-1 \
--machine-type=f1-micro \
--image=ubuntu-minimal-2004-focal-v20211209 \
--image-project=ubuntu-os-cloud \
--boot-disk-size=10GB \
--boot-disk-type=pd-balanced \
--boot-disk-device-name=study-web-dev-1

# health check 사용을 위해 프로브 IP대역 허용
gcloud compute firewall-rules create allow-http-ingress-from-healthcheck \
    --action allow \
    --direction ingress \
    --rules tcp:80 \
    --source-ranges 130.211.0.0/22,35.191.0.0/16

# 자동 복구 기능을 사용하기 위해 health check 생성
gcloud compute health-checks create http http-health-check \
    --request-path=/ \
    --check-interval=30s \
    --port 80

# MIG 생성
gcloud compute instance-groups managed create study-managed-instance-group \
--base-instance-name=study-web-dev \
--template=study-web-dev-1 \
--size=1 \
--zone=asia-northeast3-a \
--health-check=http-health-check \
--initial-delay=300

# start script를 metadata로 사용하는 instance template 생성
gcloud compute instance-templates create study-web-dev-2 \
--machine-type=f1-micro \
--image=ubuntu-minimal-2004-focal-v20211209 \
--image-project=ubuntu-os-cloud \
--boot-disk-size=10GB \
--boot-disk-type=pd-balanced \
--boot-disk-device-name=study-web-dev-2 \
--metadata-from-file=startup-script=./start_script.sh

# 인스턴스 그룹에서 사용하는 인스턴스 템플릿 변경
gcloud compute instance-groups managed set-instance-template study-managed-instance-group \
--template=study-web-dev-2 \
--zone=asia-northeast3-a

# 인스턴스 그룹내 생성되어 있는 인스턴스 교체
gcloud compute instance-groups managed rolling-action replace study-managed-instance-group \
--zone=asia-northeast3-a