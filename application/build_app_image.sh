#!/bin/bash

NAMESPACE="k8s.io"
BACKEND_IMAGE="docker.io/ktcloud7/backend:v1.0.7"
FRONTEND_IMAGE="docker.io/ktcloud7/frontend:v1.0.5"

echo "🛠️ [$BACKEND_IMAGE] 이미지 빌드 시작..."

sudo buildctl build \
    --frontend=dockerfile.v0 \
    --local context=./backend \
    --local dockerfile=./backend \
    --output type=image,name=$BACKEND_IMAGE,containerd-namespace=$NAMESPACE,unpack=true

echo "✅ 빌드 프로세스 종료!"
echo "🔍 [$NAMESPACE] 네임스페이스에 이미지가 잘 저장되었는지 확인합니다..."

# k3s ctr 명령어로 이미지 존재 여부 확인
if sudo k3s ctr -n $NAMESPACE images ls | grep -q "$BACKEND_IMAGE"; then
    echo "🎉 성공: $BACKEND_IMAGE 이미지가 정상적으로 등록되었습니다!"
    echo "---------------------------------------------------------"
    
    sudo k3s ctr -n $NAMESPACE images ls | grep "$BACKEND_IMAGE" | awk '{
        print "REF    : " $1
        print "TYPE   : " $2
        print "DIGEST : " $3
        print "SIZE   : " $4 $5
    }'
    
    echo "---------------------------------------------------------"
else
    echo "❌ 에러: $BACKEND_IMAGE 이미지를 찾을 수 없습니다."
    exit 1
fi


echo "🛠️ [$FRONTEND_IMAGE] 이미지 빌드 시작..."
sudo buildctl build \
    --frontend=dockerfile.v0 \
    --local context=./frontend \
    --local dockerfile=./frontend \
    --output type=image,name=$FRONTEND_IMAGE,containerd-namespace=$NAMESPACE,unpack=true

if sudo k3s ctr -n $NAMESPACE images ls | grep -q "$FRONTEND_IMAGE"; then
    echo "🎉 성공: $FRONTEND_IMAGE 이미지가 정상적으로 등록되었습니다!"
    sudo k3s ctr -n $NAMESPACE images ls | grep "$FRONTEND_IMAGE"
else
    echo "❌ 에러: $FRONTEND_IMAGE 이미지를 찾을 수 없습니다."
    exit 1
fi

echo "✅ 빌드 프로세스 종료!"
echo "🔍 [$NAMESPACE] 네임스페이스에 이미지가 잘 저장되었는지 확인합니다..."

# k3s ctr 명령어로 이미지 존재 여부 확인 (grep -q는 출력 없이 존재 여부만 판단합니다)
if sudo k3s ctr -n $NAMESPACE images ls | grep -q "$FRONTEND_IMAGE"; then
    echo "🎉 성공: $FRONTEND_IMAGE 이미지가 정상적으로 등록되었습니다!"
    echo "---------------------------------------------------------"
    
    # awk를 사용하여 각 컬럼을 변수에 담고 원하는 형식으로 출력
    sudo k3s ctr -n $NAMESPACE images ls | grep "$FRONTEND_IMAGE" | awk '{
        print "REF    : " $1
        print "TYPE   : " $2
        print "DIGEST : " $3
        print "SIZE   : " $4 $5
    }'
    
    echo "---------------------------------------------------------"
else
    echo "❌ 에러: $FRONTEND_IMAGE 이미지를 찾을 수 없습니다."
    exit 1
fi