const https = require('https');
const { execSync } = require('child_process');

const username = 'mukulfingertipplus.23defef3af87@agentforce.com';
const passwordWithToken = 'Arjun@20067svRxyfXPAHsNKDhYUqBF21gc';

const xmlBody = `<?xml version="1.0" encoding="utf-8" ?>
<env:Envelope xmlns:xsd="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
  <env:Body>
    <n1:login xmlns:n1="urn:partner.soap.sforce.com">
      <n1:username>${username}</n1:username>
      <n1:password>${passwordWithToken}</n1:password>
    </n1:login>
  </env:Body>
</env:Envelope>`;

const options = {
  hostname: 'login.salesforce.com',
  port: 443,
  path: '/services/Soap/u/58.0',
  method: 'POST',
  headers: {
    'Content-Type': 'text/xml',
    'SOAPAction': '""',
    'Content-Length': Buffer.byteLength(xmlBody)
  }
};

const req = https.request(options, (res) => {
  let data = '';
  res.on('data', (chunk) => { data += chunk; });
  res.on('end', () => {
    if (data.includes('<sessionId>')) {
      const sessionId = data.match(/<sessionId>(.*?)<\/sessionId>/)[1];
      const serverUrl = data.match(/<serverUrl>(.*?)<\/serverUrl>/)[1];
      const instanceUrl = serverUrl.split('/services')[0];
      console.log('LOGIN_SUCCESS');
      console.log('INSTANCE_URL:' + instanceUrl);
      
      // Authorize with sf org login access-token
      try {
        console.log('Authorizing Salesforce CLI with access token...');
        const cmd = `sf org login access-token --instance-url "${instanceUrl}" --alias sfa-dms-org --set-default --no-prompt`;
        const result = execSync(cmd, {
          input: sessionId,
          encoding: 'utf8'
        });
        console.log(result);
        console.log('CLI_AUTH_SUCCESS');
      } catch (err) {
        console.error('CLI Auth Error:', err.message);
        if (err.stdout) console.log('Stdout:', err.stdout);
        if (err.stderr) console.log('Stderr:', err.stderr);
      }
    } else {
      console.log('LOGIN_FAILED');
      console.log(data);
    }
  });
});

req.on('error', (e) => {
  console.error('HTTP Request Error:', e.message);
});

req.write(xmlBody);
req.end();
