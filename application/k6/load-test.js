// load-test.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '1m', target: 10 },  // 1분 동안 0 → 10명으로 증가 (워밍업)
    { duration: '3m', target: 50 },  // 3분 동안 10 → 50명으로 증가 (부하)
    { duration: '1m', target: 0  },  // 1분 동안 50 → 0명으로 감소 (쿨다운)
  ],

  thresholds: {
    http_req_failed:   ['rate<0.01'],  // 에러율 1% 미만
    http_req_duration: ['p(95)<500'],  // p95 500ms 이하
  },
};

const BASE_URL = 'http://api.hybrid-test.local';

export default function () {
  const res = http.post(`${BASE_URL}/api/data`);

  check(res, {
    '✅ status 200':        (r) => r.status === 200,
    '✅ status is success': (r) => r.json('status') === 'success',
    '✅ res time < 500ms':  (r) => r.timings.duration < 500,
  });

  sleep(1);
}