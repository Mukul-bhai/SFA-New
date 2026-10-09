const https = require('https');

const token = process.env.SF_TOKEN || '';
const host = 'orgfarm-03c6654659-dev-ed.develop.my.salesforce.com';

function soql(query) {
  return new Promise((resolve, reject) => {
    const path = `/services/data/v60.0/query?q=${encodeURIComponent(query)}`;
    const req = https.request({
      hostname: host,
      path: path,
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    }, res => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch(e) {
          resolve(data);
        }
      });
    });
    req.on('error', reject);
    req.end();
  });
}

async function run() {
  console.log('--- USERS ---');
  const users = await soql('SELECT Id, Name, Email, Username FROM User WHERE IsActive = true LIMIT 5');
  console.log(users.records ? users.records.map(u => ({ id: u.Id, name: u.Name, email: u.Email })) : users);

  console.log('--- EMPLOYEES ---');
  const emps = await soql('SELECT Id, Name, Employee_Code__c, User__c FROM Employee__c LIMIT 5');
  console.log(emps.records ? emps.records.map(e => ({ id: e.Id, name: e.Name, code: e.Employee_Code__c, user: e.User__c })) : emps);

  console.log('--- PJPS ---');
  const pjps = await soql('SELECT Id, Name, Month__c, Year__c, Status__c, Total_Beats__c, Total_Outlets__c FROM PJP__c LIMIT 5');
  console.log(pjps.records ? pjps.records.map(p => ({ id: p.Id, name: p.Name, month: p.Month__c, status: p.Status__c })) : pjps);

  console.log('--- BEATS ---');
  const beats = await soql('SELECT Id, Name, Beat_ID__c, PJP__c, Total_Outlets__c FROM Beat__c LIMIT 5');
  console.log(beats.records ? beats.records.map(b => ({ id: b.Id, name: b.Name, pjp: b.PJP__c, outlets: b.Total_Outlets__c })) : beats);

  console.log('--- OUTLETS ---');
  const outlets = await soql('SELECT Id, Name, Outlet_Code__c, Beat__c, Outstanding_Balance__c, Credit_Limit__c FROM Outlet__c LIMIT 5');
  console.log(outlets.records ? outlets.records.map(o => ({ id: o.Id, name: o.Name, beat: o.Beat__c, bal: o.Outstanding_Balance__c, limit: o.Credit_Limit__c })) : outlets);

  console.log('--- PRODUCTS ---');
  const prods = await soql('SELECT Id, Name, Product_Code__c, MRP__c, RBP__c, Available_Stock__c FROM Product__c LIMIT 5');
  console.log(prods.records ? prods.records.map(p => ({ id: p.Id, name: p.Name, mrp: p.MRP__c, rbp: p.RBP__c })) : prods);

  console.log('--- SCHEMES ---');
  const schemes = await soql('SELECT Id, Name, Scheme_Code__c, Scheme_Type__c FROM Trade_Scheme__c LIMIT 5');
  console.log(schemes.records ? schemes.records.map(s => ({ id: s.Id, name: s.Name, code: s.Scheme_Code__c })) : schemes);
}

run();
