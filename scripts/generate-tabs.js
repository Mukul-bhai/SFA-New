const fs = require('fs');
const path = require('path');

const tabsDir = path.join(__dirname, '..', 'force-app', 'main', 'default', 'tabs');
fs.mkdirSync(tabsDir, { recursive: true });

const tabObjects = [
  { name: 'Distributor__c', motif: 'Custom40: Compass' },
  { name: 'Warehouse__c', motif: 'Custom19: Wrench' },
  { name: 'Retailer__c', motif: 'Custom50: Big top' },
  { name: 'Territory__c', motif: 'Custom68: Globe' },
  { name: 'Beat__c', motif: 'Custom78: Map' },
  { name: 'Attendance__c', motif: 'Custom25: Alarm clock' },
  { name: 'Visit__c', motif: 'Custom83: Calendar' },
  { name: 'Inventory__c', motif: 'Custom33: Desk' },
  { name: 'Order__c', motif: 'Custom93: Shopping cart' },
  { name: 'Invoice__c', motif: 'Custom41: Cash' },
  { name: 'Payment__c', motif: 'Custom17: Sack' }
];

tabObjects.forEach(t => {
  const content = `<?xml version="1.0" encoding="UTF-8"?>
<CustomTab xmlns="http://soap.sforce.com/2006/04/metadata">
    <customObject>true</customObject>
    <motif>${t.motif}</motif>
</CustomTab>
`;
  fs.writeFileSync(path.join(tabsDir, `${t.name}.tab-meta.xml`), content, 'utf8');
});

console.log('Custom tabs generated successfully.');
