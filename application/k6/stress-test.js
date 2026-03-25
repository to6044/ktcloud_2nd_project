// stress-test.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '2m', target: 50  },  // Load Test 수준 (워밍업)
    { duration: '2m', target: 100 },  // 2배
    { duration: '2m', target: 200 },  // 4배
    { duration: '2m', target: 300 },  // 6배
    { duration: '2m', target: 400 },  // 8배 ← 여기서 보통 뭔가 터짐
    { duration: '2m', target: 0   },  // 쿨다운
  ],

  thresholds: {
    http_req_failed:   ['rate<0.05'],  // 에러율 5% 미만 (Stress라 기준 완화)
    http_req_duration: ['p(95)<2000'], // p95 2000ms 이하 (기준 완화)
  },
};

const BASE_URL = 'http://api.hybrid-test.local';

export default function () {
  const res = http.post(`${BASE_URL}/api/data`);

  check(res, {
    '✅ status 200':        (r) => r.status === 200,
    '✅ status is success': (r) => r.json('status') === 'success',
    '✅ res time < 2000ms': (r) => r.timings.duration < 2000,
  });

  sleep(1);
}