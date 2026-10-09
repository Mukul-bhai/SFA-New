const fs = require('fs');
const path = require('path');

const listViewsConfig = {
  'Distributor__c': [
    'NAME',
    'Distributor_Code__c',
    'Status__c',
    'Credit_Limit__c',
    'Current_Outstanding__c',
    'Default_Warehouse__c',
    'GSTIN__c'
  ],
  'Warehouse__c': [
    'NAME',
    'Warehouse_Code__c',
    'Distributor__c',
    'Address__c',
    'Is_Active__c'
  ],
  'Retailer__c': [
    'NAME',
    'Retailer_Code__c',
    'Shop_Name__c',
    'Owner_Phone__c',
    'Primary_Distributor__c',
    'Credit_Limit__c',
    'Outstanding_Balance__c',
    'Credit_Hold__c'
  ],
  'Inventory__c': [
    'NAME',
    'Warehouse__c',
    'Product__c',
    'Physical_Stock__c',
    'Reserved_Stock__c',
    'Available_Stock__c',
    'Blocked_Stock__c',
    'Damaged_Stock__c'
  ],
  'Inventory_Batch__c': [
    'NAME',
    'Inventory__c',
    'Batch_Number__c',
    'Manufacturing_Date__c',
    'Expiry_Date__c',
    'Quantity__c',
    'MRP__c'
  ],
  'Inventory_Ledger__c': [
    'NAME',
    'Inventory__c',
    'Type__c',
    'Quantity_Delta__c',
    'Timestamp__c',
    'Reference_Record_Id__c'
  ],
  'Order__c': [
    'NAME',
    'Order_Date__c',
    'Retailer__c',
    'Primary_Distributor__c',
    'Status__c',
    'Total_Amount__c',
    'Sales_Executive__c'
  ],
  'Order_Line__c': [
    'NAME',
    'Order__c',
    'Product__c',
    'Quantity__c',
    'Unit_Price__c',
    'Line_Total__c',
    'Fulfillment_Status__c'
  ],
  'Invoice__c': [
    'NAME',
    'Invoice_Number__c',
    'Order__c',
    'Invoice_Amount__c',
    'Invoice_Date__c',
    'Status__c'
  ],
  'Payment__c': [
    'NAME',
    'Order__c',
    'Retailer__c',
    'Amount__c',
    'Payment_Mode__c',
    'Status__c'
  ],
  'Beat__c': [
    'NAME',
    'Beat_Code__c',
    'Assigned_Executive__c',
    'Day_Of_Week__c',
    'Territory__c'
  ],
  'Retailer_Beat_Mapping__c': [
    'NAME',
    'Beat__c',
    'Retailer__c',
    'Sequence_Order__c'
  ],
  'Visit__c': [
    'NAME',
    'Retailer__c',
    'Sales_Executive__c',
    'Check_In_Time__c',
    'Check_Out_Time__c',
    'Visit_Status__c'
  ],
  'Attendance__c': [
    'NAME',
    'Sales_Executive__c',
    'Punch_In_Time__c',
    'Punch_Out_Time__c',
    'Status__c'
  ],
  'Territory__c': [
    'NAME',
    'Territory_Code__c',
    'Region__c'
  ]
};

const objectsBaseDir = path.resolve(__dirname, '../force-app/main/default/objects');

for (const [objName, cols] of Object.entries(listViewsConfig)) {
  const lvDir = path.join(objectsBaseDir, objName, 'listViews');
  if (!fs.existsSync(lvDir)) {
    fs.mkdirSync(lvDir, { recursive: true });
  }

  const columnsXml = cols.map(c => `    <columns>${c}</columns>`).join('\n');
  const xml = `<?xml version="1.0" encoding="UTF-8"?>
<ListView xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>All</fullName>
${columnsXml}
    <filterScope>Everything</filterScope>
    <label>All</label>
</ListView>
`;

  const filePath = path.join(lvDir, 'All.listView-meta.xml');
  fs.writeFileSync(filePath, xml, 'utf8');
  console.log(`Generated All ListView for ${objName} at ${filePath}`);
}

console.log('Finished generating all 15 ListViews!');
