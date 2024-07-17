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
    --machine-type=e2-medium \
    --subnet=emadam-test-subnet \
    --no-address \
    --image=rocky-linux-8-optimized-gcp-v20240611 \
    --image-project=rocky-linux-cloud \
    --boot-disk-size=20GB \
    --boot-disk-type=pd-balanced \
    --boot-disk-device-name=emadam-test-vm \
    --scopes=cloud-platform \
    --metadata-from-file=startup-script=startup_script.sh

# Prober 접근을 허용하는 방화벽 규칙 생성
gcloud compute firewall-rules create emadam-test-rule \
    --network=emadam-test-vpc \
    --action=allow \
    --direction=ingress \
    --rules=tcp:80 \
    --source-ranges=130.211.0.0/22,35.191.0.0/16 

# 비관리형 인스턴스 그룹 생성
gcloud compute instance-groups unmanaged create emadam-test-ig \
    --zone=asia-northeast3-a

# 인스턴스 그룹에 인스턴스 추가
gcloud compute instance-groups unmanaged add-instances emadam-test-ig \
    --zone=asia-northeast3-a \
    --instances=emadam-test-vm

# 인스턴스 그룹에 이름이 지정된 포트 추가
gcloud compute instance-groups set-named-ports emadam-test-ig \
    --named-ports http:80 \
    --zone asia-northeast3-a

# 외부 고정 IP 생성
gcloud compute addresses create emadam-test-external-ip \
    --ip-version=IPV4 \
    --global

# 관리형 Zone 생성
gcloud dns managed-zones create emadam-test-zone \
    --dns-name=<domain> \
    --description="For Cloud Armor testing"

# 로드밸런서용 Record 생성
gcloud dns record-sets transaction start \
    --zone=emadam-test-zone

EXTERNAL_IP=`gcloud beta compute addresses describe emadam-test-external-ip --global | grep ^address: | awk '{ print $2 }'`
gcloud dns record-sets transaction add $EXTERNAL_IP \
    --name=test-lb.<domain> \
    --ttl=300 \
    --type=A \
    --zone=emadam-test-zone

gcloud dns record-sets transaction execute \
    --zone=emadam-test-zone

# 관리형 SSL 인증서 생성
gcloud compute ssl-certificates create emadam-test-ssl \
    --domains=test-lb.<domain> \
    --global

# 상태확인 생성
gcloud compute health-checks create http emadam-test-health-check \
    --request-path=/ \
    --check-interval=5s \
    --port 80

# 백엔드 서비스 생성
gcloud compute backend-services create emadam-test-backend-service \
    --protocol=HTTP \
    --port-name=http \
    --health-checks=emadam-test-health-check \
    --connection-draining-timeout=300 \
    --enable-logging \
    --global

# 백엔드 추가
gcloud compute backend-services add-backend emadam-test-backend-service \
    --instance-group=emadam-test-ig \
    --instance-group-zone=asia-northeast3-a \
    --global

# URL MAP 생성
gcloud compute url-maps create emadam-test-url-map \
    --default-service emadam-test-backend-service

# Target Proxy 생성
gcloud compute target-https-proxies create emadam-test-target-proxy \
    --url-map=emadam-test-url-map \
    --ssl-certificates=emadam-test-ssl 

# Forwarding Rule 추가
gcloud compute forwarding-rules create emadam-test-forwarding-rule \
    --address=emadam-test-external-ip \
    --global \
    --target-https-proxy=emadam-test-target-proxy \
    --ports=443

# Forwarding Rule 제거
gcloud compute forwarding-rules delete emadam-test-forwarding-rule \
    --global

# Target Proxy 제거
gcloud compute target-https-proxies delete emadam-test-target-proxy 

# URL MAP 제거
gcloud compute url-maps delete emadam-test-url-map 