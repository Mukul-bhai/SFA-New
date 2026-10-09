const fs = require('fs');
const path = require('path');

const dir = path.resolve(__dirname, '../force-app/main/default/objects/Mobile_Auth_Session__c/fields');
if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });

const fields = [
  { name: 'Email__c', label: 'Email', type: 'Text', length: 100 },
  { name: 'User__c', label: 'User', type: 'Lookup', referenceTo: 'User' },
  { name: 'OTP__c', label: 'OTP Code', type: 'Text', length: 10 },
  { name: 'OTP_Expiry__c', label: 'OTP Expiry', type: 'DateTime' },
  { name: 'Password_Hash__c', label: 'Password Hash', type: 'Text', length: 255 },
  { name: 'Auth_Token__c', label: 'Auth Token', type: 'Text', length: 255 },
  { name: 'Is_Verified__c', label: 'Is Verified', type: 'Checkbox', defaultValue: 'false' }
];

fields.forEach(f => {
  let typeXml = '';
  if (f.type === 'Text') {
    typeXml = `<type>Text</type><length>${f.length}</length>`;
  } else if (f.type === 'Lookup') {
    typeXml = `<type>Lookup</type><referenceTo>${f.referenceTo}</referenceTo><relationshipName>Mobile_Auth_Sessions</relationshipName><deleteConstraint>SetNull</deleteConstraint>`;
  } else if (f.type === 'DateTime') {
    typeXml = `<type>DateTime</type>`;
  } else if (f.type === 'Checkbox') {
    typeXml = `<type>Checkbox</type><defaultValue>${f.defaultValue}</defaultValue>`;
  }

  const xml = `<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>${f.name}</fullName>
    <label>${f.label}</label>
    ${typeXml}
</CustomField>
`;
  fs.writeFileSync(path.join(dir, `${f.name}.field-meta.xml`), xml, 'utf8');
});

console.log('Mobile_Auth_Session fields created.');
