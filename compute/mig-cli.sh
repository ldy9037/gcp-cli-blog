#!/bin/bash

# ubuntu image 기반의 Instance Template 생성
gcloud compute instance-templates create study-web-dev-1 \
--machine-type=f1-micro \
--image=ubuntu-minimal-2004-focal-v20211209 \
--image-project=ubuntu-os-cloud \
--boot-disk-size=10GB \
--boot-disk-type=pd-balanced \
--boot-disk-device-name=study-web-dev-1
