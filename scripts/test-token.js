const https = require('https');

const token = process.env.SF_TOKEN || '';
const domains = [
  'orgfarm-03c6654659-dev-ed.develop.my.salesforce.com',
  'orgfarm-03c6654659-dev-ed.develop.lightning.force.com'
];

domains.forEach(hostname => {
  const options = {
    hostname,
    port: 443,
    path: '/services/data/v60.0/sobjects',
    method: 'GET',
    headers: {
      'Authorization': 'Bearer ' + token
    }
  };

  const req = https.request(options, (res) => {
    let data = '';
    res.on('data', chunk => data += chunk);
    res.on('end', () => {
      console.log(`[${hostname}] STATUS: ${res.statusCode}`);
      console.log(data.slice(0, 300));
    });
  });

  req.on('error', e => console.error(`[${hostname}] ERROR:`, e.message));
  req.end();
});
