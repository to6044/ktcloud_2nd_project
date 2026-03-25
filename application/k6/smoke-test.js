// smoke-test.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: 1,          // 가상 유저 1명
  duration: '30s', // 30초 동안

  thresholds: {
    http_req_failed:   ['rate<0.01'],   // 에러율 1% 미만
    http_req_duration: ['p(95)<500'],   // 95%가 500ms 이하
  },
};

const BASE_URL = 'http://api.hybrid-test.local';

export default function () {
  const res = http.post(`${BASE_URL}/api/data`);

  check(res, {
    '✅ status 200':         (r) => r.status === 200,
    '✅ status is success':  (r) => r.json('status') === 'success',
    '✅ res time < 500ms':   (r) => r.timings.duration < 500,
  });

  sleep(1);
}