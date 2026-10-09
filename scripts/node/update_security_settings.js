const https = require('https');
const { execSync } = require('child_process');

try {
    const authOutput = execSync('sf org auth show-access-token --target-org sfa-dms-org --json').toString();
    const authData = JSON.parse(authOutput);
    const token = authData.result.accessToken;

    const orgOutput = execSync('sf org display --target-org sfa-dms-org --json').toString();
    const orgData = JSON.parse(orgOutput);
    const instanceUrl = new URL(orgData.result.instanceUrl);

    // First, fetch existing SecuritySettings metadata
    const queryPath = `/services/data/v68.0/tooling/query?q=${encodeURIComponent('SELECT Id, Metadata FROM SecuritySettings')}`;
    
    function makeRequest(options, postData) {
        return new Promise((resolve, reject) => {
            const req = https.request(options, (res) => {
                let data = '';
                res.on('data', chunk => data += chunk);
                res.on('end', () => {
                    resolve({ statusCode: res.statusCode, body: data });
                });
            });
            req.on('error', reject);
            if (postData) {
                req.write(postData);
            }
            req.end();
        });
    }

    async function run() {
        console.log('Querying current SecuritySettings...');
        const getRes = await makeRequest({
            hostname: instanceUrl.hostname,
            path: queryPath,
            method: 'GET',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            }
        });

        const queryResult = JSON.parse(getRes.body);
        if (!queryResult.records || queryResult.records.length === 0) {
            console.error('No SecuritySettings record found.');
            return;
        }

        const secRecord = queryResult.records[0];
        console.log('Record ID / Key:', secRecord.Id);
        console.log('Current enableAdminLoginAsAnyUser:', secRecord.Metadata.enableAdminLoginAsAnyUser);

        // Update enableAdminLoginAsAnyUser to true
        secRecord.Metadata.enableAdminLoginAsAnyUser = true;

        const patchBody = JSON.stringify({
            Metadata: secRecord.Metadata
        });

        const patchPath = `/services/data/v68.0/tooling/sobjects/SecuritySettings/${secRecord.Id}`;
        console.log('Patching SecuritySettings via:', patchPath);

        const patchRes = await makeRequest({
            hostname: instanceUrl.hostname,
            path: patchPath,
            method: 'PATCH',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json',
                'Content-Length': Buffer.byteLength(patchBody)
            }
        }, patchBody);

        console.log('PATCH Status Code:', patchRes.statusCode);
        console.log('PATCH Response:', patchRes.body);

        // Verify by re-querying
        const verifyRes = await makeRequest({
            hostname: instanceUrl.hostname,
            path: queryPath,
            method: 'GET',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            }
        });
        const verifyResult = JSON.parse(verifyRes.body);
        console.log('Verified enableAdminLoginAsAnyUser:', verifyResult.records[0].Metadata.enableAdminLoginAsAnyUser);
    }

    run();
} catch (e) {
    console.error('Error:', e);
}
