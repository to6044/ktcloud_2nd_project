#!/bin/bash

echo "🚀 로컬 테스트 환경을 구축하고 백엔드 서버를 시작"

# 1. DB 포트 포워딩
echo "🔗 Kubernetes DB(local-db-postgresql) 포트 포워딩을 시작합니다..."
kubectl port-forward -n db svc/local-db-postgresql 5432:5432 > /dev/null 2>&1 &
echo "PF_PID=$!"

# DB 프로세스의 ID(PID)를 저장
PF_PID=$!

# 스크립트가 종료될 때 포트 포워딩 프로세스도 함께 죽이도록 예약
trap "echo -e '\n🛑 서버 종료 감지. 포트 포워딩 연결을 안전하게 해제합니다...'; kill $PF_PID" EXIT

sleep 2

# 2. 가상환경 활성화
if [ -d "venv" ]; then
    source venv/bin/activate
    echo "✅ 가상환경(venv)이 활성화되었습니다."
else
    echo "❌ 에러: venv 폴더를 찾을 수 없습니다."
    exit 1
fi

# 3. 환경변수 주입 및 서버 실행
pip install -r requirements.txt
echo "🔥 DB_HOST를 127.0.0.1로 덮어씌우고 FastAPI 서버를 실행합니다!"
DB_HOST=127.0.0.1 uvicorn main:app --host 0.0.0.0 --port 8000 --reload