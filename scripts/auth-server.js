const http = require('http');
const https = require('https');
const url = require('url');
const querystring = require('querystring');
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const PORT = 1717;
const CLIENT_ID = 'PlatformCLI';
const REDIRECT_URI = `http://localhost:${PORT}/OauthRedirect`;
const ALIAS = 'sfa-dms-org';

const authUrl = `https://login.salesforce.com/services/oauth2/authorize?response_type=code&client_id=${CLIENT_ID}&redirect_uri=${encodeURIComponent(REDIRECT_URI)}&prompt=login%20consent&scope=refresh_token%20api%20web`;

console.log('--------------------------------------------------');
console.log('OAUTH AUTHENTICATION SERVER STARTED');
console.log('--------------------------------------------------');
console.log('Click or open this URL in your browser:');
console.log(authUrl);
console.log('--------------------------------------------------');

const server = http.createServer((req, res) => {
  const parsedUrl = url.parse(req.url, true);

  if (parsedUrl.pathname === '/OauthRedirect') {
    const code = parsedUrl.query.code;

    if (!code) {
      res.writeHead(400, { 'Content-Type': 'text/html' });
      res.end('<h1>Error: No authorization code received.</h1>');
      return;
    }

    console.log('Authorization code received! Exchanging for token...');

    // Exchange code for token
    const postData = querystring.stringify({
      grant_type: 'authorization_code',
      code: code,
      client_id: CLIENT_ID,
      redirect_uri: REDIRECT_URI
    });

    const tokenReq = https.request({
      hostname: 'login.salesforce.com',
      port: 443,
      path: '/services/oauth2/token',
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Content-Length': Buffer.byteLength(postData)
      }
    }, (tokenRes) => {
      let body = '';
      tokenRes.on('data', chunk => body += chunk);
      tokenRes.on('end', () => {
        try {
          const data = JSON.parse(body);
          if (data.error) {
            console.error('Token exchange error:', data);
            res.writeHead(500, { 'Content-Type': 'text/html' });
            res.end(`<h1>Token Error: ${data.error_description || data.error}</h1>`);
            return;
          }

          console.log('Token exchange SUCCESS!');
          console.log('Instance URL:', data.instance_url);
          console.log('User ID URL:', data.id);

          // Construct SFDX auth format
          // force://<clientId>:<clientSecret>:<refreshToken>@<instanceUrl>
          const sfdxAuthUrl = `force://${CLIENT_ID}::${data.refresh_token}@${data.instance_url.replace('https://', '')}`;
          const authUrlFile = path.join(__dirname, 'sfdx-auth-url.txt');
          fs.writeFileSync(authUrlFile, sfdxAuthUrl, 'utf8');

          console.log('Importing into Salesforce CLI via sfdx-url...');
          execSync(`sf org login sfdx-url --sfdx-url-file "${authUrlFile}" --alias ${ALIAS} --set-default`, { encoding: 'utf8' });
          fs.unlinkSync(authUrlFile);

          res.writeHead(200, { 'Content-Type': 'text/html' });
          res.end(`
            <html>
              <body style="font-family: Arial, sans-serif; text-align: center; padding-top: 50px; background-color: #f0fdf4;">
                <h1 style="color: #16a34a;">Authentication Successful!</h1>
                <p style="font-size: 18px; color: #1e293b;">Your Salesforce Developer Org <b>sfa-dms-org</b> has been connected to Salesforce CLI.</p>
                <p style="color: #64748b;">You can safely close this browser window and return to your agent.</p>
              </body>
            </html>
          `);

          console.log('==================================================');
          console.log('ORGANIZATION CONNECTED SUCCESSFULLY AS: ' + ALIAS);
          console.log('==================================================');

          setTimeout(() => {
            server.close();
            process.exit(0);
          }, 1500);

        } catch (e) {
          console.error('Failed to parse token response:', e);
          res.writeHead(500, { 'Content-Type': 'text/html' });
          res.end(`<h1>Internal Error: ${e.message}</h1>`);
        }
      });
    });

    tokenReq.on('error', (e) => {
      console.error('HTTPS Token Request Error:', e);
      res.writeHead(500, { 'Content-Type': 'text/html' });
      res.end(`<h1>Network Error: ${e.message}</h1>`);
    });

    tokenReq.write(postData);
    tokenReq.end();
  } else {
    res.writeHead(404, { 'Content-Type': 'text/plain' });
    res.end('Not Found');
  }
});

server.listen(PORT, () => {
  console.log(`Server listening on http://localhost:${PORT}`);
  // Launch Chrome
  try {
    const cmd = `Start-Process "chrome.exe" "${authUrl}"`;
    execSync(`powershell -Command "${cmd}"`);
    console.log('Chrome launched successfully to authorization URL.');
  } catch (err) {
    console.log('Could not auto-launch Chrome, please open URL manually.');
  }
});
