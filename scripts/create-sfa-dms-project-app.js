const fs = require('fs');
const path = require('path');

const baseDir = path.join(__dirname, '..', 'force-app', 'main', 'default');

function ensureDir(dir) {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

console.log('--- GENERATING SFA DMS PROJECT METADATA ---');

// 1. APPLICATION METADATA: SFA DMS project
const appDir = path.join(baseDir, 'applications');
ensureDir(appDir);
const appXml = `<?xml version="1.0" encoding="UTF-8"?>
<CustomApplication xmlns="http://soap.sforce.com/2006/04/metadata">
    <brand>
        <headerColor>#0B5CAB</headerColor>
        <shouldOverrideOrgTheme>false</shouldOverrideOrgTheme>
    </brand>
    <description>SFA DMS Project - Employee Hierarchy, Journey Plans (PJP), Route Beats and Retail Outlets</description>
    <formFactors>Large</formFactors>
    <formFactors>Small</formFactors>
    <label>SFA DMS project</label>
    <navType>Standard</navType>
    <tabs>standard-home</tabs>
    <tabs>Employee__c</tabs>
    <tabs>PJP__c</tabs>
    <tabs>Beat__c</tabs>
    <tabs>Outlet__c</tabs>
    <tabs>Distributor__c</tabs>
    <tabs>Retailer__c</tabs>
    <tabs>Inventory__c</tabs>
    <tabs>Order__c</tabs>
    <tabs>Invoice__c</tabs>
    <uiType>Lightning</uiType>
</CustomApplication>
`;
fs.writeFileSync(path.join(appDir, 'SFA_DMS_project.app-meta.xml'), appXml, 'utf8');
console.log('Created SFA_DMS_project.app-meta.xml');

// 2. TABS
const tabsDir = path.join(baseDir, 'tabs');
ensureDir(tabsDir);

const tabDefs = [
  { name: 'Employee__c', label: 'Employees', motif: 'Custom15: People', desc: 'Employee master with hierarchy and reporting managers' },
  { name: 'PJP__c', label: 'PJPs', motif: 'Custom25: Compass', desc: 'Permanent Journey Plan for monthly route execution and approval' },
  { name: 'Outlet__c', label: 'Outlets', motif: 'Custom32: Factory', desc: 'Retail outlets and shops mapped to routes and beats' }
];

tabDefs.forEach(t => {
  const xml = `<?xml version="1.0" encoding="UTF-8"?>
<CustomTab xmlns="http://soap.sforce.com/2006/04/metadata">
    <customObject>true</customObject>
    <description>${t.desc}</description>
    <motif>${t.motif}</motif>
</CustomTab>
`;
  fs.writeFileSync(path.join(tabsDir, `${t.name}.tab-meta.xml`), xml, 'utf8');
  console.log(`Created tab ${t.name}`);
});

console.log('Tabs generation complete');
