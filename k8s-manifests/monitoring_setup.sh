#!/bin/bash

echo "🚀 Prometheus 및 Grafana 포트포워딩을 백그라운드에서 시작합니다..."

# Prometheus 포트포워딩
nohup kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090 > /dev/null 2>&1 &
PROM_PID=$!
echo "✅ Prometheus (Port 9090) 실행 완료 - PID: $PROM_PID"

# Grafana 포트포워딩
nohup kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80 > /dev/null 2>&1 &
GRAF_PID=$!
echo "✅ Grafana (Port 3000) 실행 완료 - PID: $GRAF_PID"

echo "------------------------------------------------------"
echo "📌 포트포워딩이 백그라운드에서 실행 중입니다."
echo "🛑 나중에 종료하려면 아래 명령어를 실행하세요:"
echo "   kill $PROM_PID $GRAF_PID"
echo "------------------------------------------------------"