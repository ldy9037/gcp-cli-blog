# 백엔드 보안 정책 생성
gcloud compute security-policies create emadam-test-security-policy \
    --type=CLOUD_ARMOR \
    --global

# 백엔드 보안 정책 확인
gcloud compute security-policies describe emadam-test-security-policy \
    --global

# 백엔드 서비스에 보안 정책 연결
gcloud compute backend-services update emadam-test-backend-service \
    --security-policy=emadam-test-security-policy \
    --global

# 백엔드 서비스에 연결된 보안 정책 확인
gcloud compute backend-services describe emadam-test-backend-service \
    --global | grep securityPolicy | awk '{ print $2 }'

# IP 차단 규칙 생성
gcloud compute security-policies rules create 10 \
    --security-policy emadam-test-security-policy \
    --src-ip-ranges "211.243.179.113" \
    --action "deny-403"

# IP 허용 규칙 생성
gcloud compute security-policies rules create 9 \
    --security-policy emadam-test-security-policy \
    --src-ip-ranges "211.243.179.113" \
    --action "allow"

# REQUEST-932-APPLICATION-ATTACK-RCE - 932200 Rule
gcloud compute security-policies rules create 8 \
	--project=infra-common-dev \
	--action=deny-403 \
	--security-policy=emadam-test-security-policy \
	--expression=request.headers\[\'cookie\'\].lower\(\).urlDecodeUni\(\).matches\(\"\[\*\?\`\\\'\]\[^/\[:space:\]\]\+/\|\[\$\]\[\(\{\[\[:alnum:\]\]\|/\[^/\]\+\?\[\*\?\`\\\'\]\"\)\ $'\n'\|\|\ $'\n'request.query.lower\(\).urlDecodeUni\(\).matches\(\"\[\*\?\`\\\'\]\[^/\[:space:\]\]\+/\|\[\$\]\[\(\{\[\[:alnum:\]\]\|/\[^/\]\+\?\[\*\?\`\\\'\]\"\)

# 보안 정책 로그 설정
gcloud compute security-policies update emadam-test-security-policy \
    --log-level=VERBOSE