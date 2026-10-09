const https = require('https');
const querystring = require('querystring');
const fs = require('fs');
const path = require('path');

const username = 'mukulfingertipplus.23defef3af87@agentforce.com';
const password = 'Arjun@20067svRxyfXPAHsNKDhYUqBF21gc';

// Known Salesforce CLI Connected App Client IDs
const clientIds = [
  'PlatformCLI',
  'SalesforceDevelopmentExperienceCLI',
  '3MVG99OxAZUgDx-5vdS7Bq5m0g3.8h.c6jQ9z.Wv1vM_Jq8S8yv2B5r_8e0k5Y2L7v1vM_Jq8S8yv2B5r_8e0'
];

async function tryOAuthLogin(clientId) {
  return new Promise((resolve) => {
    const postData = querystring.stringify({
      grant_type: 'password',
      client_id: clientId,
      username: username,
      password: password
    });

    const options = {
      hostname: 'login.salesforce.com',
      port: 443,
      path: '/services/oauth2/token',
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Content-Length': Buffer.byteLength(postData)
      }
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        resolve({ clientId, statusCode: res.statusCode, body: data });
      });
    });

    req.on('error', (e) => resolve({ clientId, error: e.message }));
    req.write(postData);
    req.end();
  });
}

async function run() {
  for (const cid of clientIds) {
    console.log(`Testing OAuth with clientId: ${cid}...`);
    const res = await tryOAuthLogin(cid);
    console.log(`Result: ${res.statusCode} -> ${res.body}`);
    if (res.statusCode === 200) {
      console.log('SUCCESS! Token received!');
      break;
    }
  }
}

run();
