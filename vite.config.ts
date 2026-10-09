import { defineConfig, type Plugin } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import fs from 'fs'
import path from 'path'
import https from 'https'

function salesforceProxyPlugin(): Plugin {
  return {
    name: 'salesforce-proxy',
    configureServer(server) {
      server.middlewares.use('/api/salesforce', (req, res, _next) => {
        let token = process.env.SF_ACCESS_TOKEN || '';
        let instanceUrl = 'https://orgfarm-03c6654659-dev-ed.develop.my.salesforce.com';

        const activeTokenPath = path.resolve(process.cwd(), 'active_token.json');
        try {
          if (fs.existsSync(activeTokenPath)) {
            const data = JSON.parse(fs.readFileSync(activeTokenPath, 'utf8'));
            if (data.accessToken) token = data.accessToken;
            if (data.instanceUrl) instanceUrl = data.instanceUrl;
          }
        } catch (e) {
          console.error('Error reading active_token.json:', e);
        }

        const targetUrl = new URL(instanceUrl);
        const subPath = req.url || '';

        const chunks: Buffer[] = [];
        req.on('data', chunk => chunks.push(Buffer.from(chunk)));
        req.on('end', () => {
          const bodyBuffer = Buffer.concat(chunks);
          const headers: Record<string, string | number> = {
            'Authorization': 'Bearer ' + token,
            'Content-Type': req.headers['content-type'] || 'application/json'
          };
          if (req.method !== 'GET' && req.method !== 'HEAD') {
            headers['Content-Length'] = bodyBuffer.length;
          }

          const sfReq = https.request({
            hostname: targetUrl.hostname,
            port: 443,
            path: subPath,
            method: req.method,
            headers: headers
          }, (sfRes) => {
            res.statusCode = sfRes.statusCode || 200;
            res.setHeader('Content-Type', sfRes.headers['content-type'] || 'application/json');
            sfRes.pipe(res);
          });

          sfReq.on('error', (err) => {
            res.statusCode = 502;
            res.end(JSON.stringify({ error: 'Salesforce Proxy Error: ' + err.message }));
          });

          if (bodyBuffer.length > 0) {
            sfReq.write(bodyBuffer);
          }
          sfReq.end();
        });
      });
    }
  };
}

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    salesforceProxyPlugin(),
    react(),
    tailwindcss()
  ],
  server: {
    port: 5173,
    host: true
  }
})
