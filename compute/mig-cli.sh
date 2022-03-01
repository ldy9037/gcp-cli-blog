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

# 오토스케일링 설정
gcloud compute instance-groups managed set-autoscaling study-managed-instance-group \
--zone asia-northeast3-a \
--cool-down-period "60" \
--max-num-replicas "3" \
--min-num-replicas "1" \
--set-schedule "business-hours" \
--schedule-cron "0 9 * * 1-5" \
--schedule-min-required-replicas 2 \
--target-cpu-utilization "0.6" \
--schedule-duration-sec 32400 \
--schedule-time-zone "Asia/Seoul" \
--mode "on"

# 윈도우 인스턴스 템플릿 생성
gcloud compute instance-templates create study-web-dev-3 \
--machine-type=f1-micro \
--image=windows-server-2019-dc-v20211216 \
--image-project=windows-cloud \
--boot-disk-size=50GB \
--boot-disk-type=pd-balanced \
--boot-disk-device-name=study-web-dev-3

# 윈도우 인스턴스 템플릿을 기반으로 MIG 생성
gcloud compute instance-groups managed create study-managed-instance-group-windows \
--base-instance-name=study-web-dev \
--template=study-web-dev-3 \
--size=1 \
--zone=asia-northeast3-a \
--health-check=http-health-check \
--initial-delay=300

# 스테이트풀 정책으로 스테이트풀 디스크 구성
gcloud compute instance-groups managed update study-managed-instance-group-windows \
--zone=asia-northeast3-a \
--stateful-disk device-name=study-web-dev-3,auto-delete=on-permanent-instance-deletion

# 스테이트풀 메타데이터 구성을 가지고 있는 인스턴스 수동 생성
gcloud compute instance-groups managed create-instance study-managed-instance-group-windows \
--instance study-web-dev-metadata \
--zone=asia-northeast3-a \
--stateful-metadata test-metadata=emadam

# 인스턴스 수동 생성
gcloud compute instance-groups managed create-instance study-managed-instance-group-windows \
  --instance study-web-dev-metadata-2 \
  --zone=asia-northeast3-a

# 스테이트풀 메타데이터 적용을 위해 인스턴스별 구성 추가 
gcloud compute instance-groups managed instance-configs create study-managed-instance-group-windows \
--instance study-web-dev-metadata-2 \
--zone asia-northeast3-a \
--stateful-metadata test-metadata-2=emadam-2

# 스테이트풀 정책으로 스테이트풀 IP 구성
gcloud beta compute instance-groups managed update study-managed-instance-group-windows \
    --stateful-internal-ip enabled \
    --stateful-external-ip enabled \
   --zone asia-northeast3-a

# 전체 네트워크 인터페이스 이름 확인
gcloud compute instance-templates describe study-web-dev-3 --format=json | jq .properties.networkInterfaces[].name | tr -d '"'

# 스테이트풀 정책 중 스테이트풀 IP 구성 제거
interface_name=`gcloud compute instance-templates describe study-web-dev-3 --format=json | jq .properties.networkInterfaces[0].name | tr -d '"'`

gcloud beta compute instance-groups managed update study-managed-instance-group-windows \
    --remove-stateful-internal-ips $interface_name \
    --remove-stateful-external-ips $interface_name \
   --zone asia-northeast3-a

# 예약된 고정 IP 주소 전부 해제 
addresses=`gcloud compute addresses list | awk '{ print $1 }' | grep study | tr '\n' ' '`

gcloud compute addresses delete $addresses --region=asia-northeast3

# 고정 IP주소 예약
gcloud compute addresses create study-address-1 \
--region=asia-northeast3

# 인스턴스별 구성에 스테이트풀 IP 구성 옵션 추가 
gcloud beta compute instance-groups managed instance-configs update study-managed-instance-group-windows \
    --instance study-web-dev-metadata-2 \
    --stateful-internal-ip address=10.178.0.51 \
    --stateful-external-ip address=projects/project-name/regions/asia-northeast3/addresses/study-address-1 \
   --zone=asia-northeast3-a