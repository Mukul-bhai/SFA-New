const https = require('https');
const querystring = require('querystring');
const { execSync } = require('child_process');

async function main() {
    const token = JSON.parse(execSync('sf org auth show-access-token --target-org sfa-dms-org --json')).result.accessToken;
    const inst = new URL(JSON.parse(execSync('sf org display --target-org sfa-dms-org --json')).result.instanceUrl);

    function fetchPage() {
        return new Promise((resolve, reject) => {
            const req = https.get({
                hostname: inst.hostname,
                path: '/partnerbt/loginAccessPolicies.apexp',
                headers: { 'Authorization': 'Bearer ' + token }
            }, (res) => {
                let d = '';
                res.on('data', c => d += c);
                res.on('end', () => resolve({ headers: res.headers, body: d }));
            });
            req.on('error', reject);
        });
    }

    console.log('Fetching Login Access Policies page...');
    const page = await fetchPage();

    function getVal(id) {
        const regex = new RegExp('<input[^>]+id="' + id.replace(/\./g, '\\.') + '"[^>]+value="([^"]*)"', 'i');
        const m = page.body.match(regex);
        return m ? m[1] : '';
    }

    const vs = getVal('com.salesforce.visualforce.ViewState');
    const ver = getVal('com.salesforce.visualforce.ViewStateVersion');
    const mac = getVal('com.salesforce.visualforce.ViewStateMAC');
    const csrf = getVal('com.salesforce.visualforce.ViewStateCSRF');

    if (!vs) {
        console.error('ViewState not found');
        return;
    }

    console.log('Extracted ViewState (length:', vs.length, ')');

    const postData = querystring.stringify({
        'loginAccessPolicies:mainForm': 'loginAccessPolicies:mainForm',
        'loginAccessPolicies:mainForm:j_id45:adminTable:0:adminsCanLogInAsAny': 'on',
        'loginAccessPolicies:mainForm:j_id45:j_id50:save': 'Save',
        'com.salesforce.visualforce.ViewState': vs,
        'com.salesforce.visualforce.ViewStateVersion': ver,
        'com.salesforce.visualforce.ViewStateMAC': mac,
        'com.salesforce.visualforce.ViewStateCSRF': csrf
    });

    console.log('Submitting POST form to enable Administrators Can Log In As Any User...');
    const postReq = () => new Promise((resolve, reject) => {
        const req = https.request({
            hostname: inst.hostname,
            path: '/partnerbt/loginAccessPolicies.apexp',
            method: 'POST',
            headers: {
                'Authorization': 'Bearer ' + token,
                'Content-Type': 'application/x-www-form-urlencoded',
                'Content-Length': Buffer.byteLength(postData)
            }
        }, (res) => {
            let d = '';
            res.on('data', c => d += c);
            res.on('end', () => resolve({ statusCode: res.statusCode, headers: res.headers, body: d }));
        });
        req.on('error', reject);
        req.write(postData);
        req.end();
    });

    const postRes = await postReq();
    console.log('POST status:', postRes.statusCode);

    // Verify
    const verifyPage = await fetchPage();
    const isChecked = verifyPage.body.includes('adminsCanLogInAsAny" type="checkbox" checked') || 
                     verifyPage.body.match(/adminsCanLogInAsAny[^>]*checked/);
    console.log('Is adminsCanLogInAsAny now checked?', !!isChecked);

    const toolingCheck = execSync('sf data query --target-org sfa-dms-org --use-tooling-api --query "SELECT Id, Metadata FROM SecuritySettings" --json').toString();
    const toolingData = JSON.parse(toolingCheck);
    console.log('Tooling API enableAdminLoginAsAnyUser:', toolingData.result.records[0].Metadata.enableAdminLoginAsAnyUser);
}

main().catch(console.error);
