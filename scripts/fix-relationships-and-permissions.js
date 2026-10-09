const fs = require('fs');
const path = require('path');

const objectsDir = path.join(__dirname, '..', 'force-app', 'main', 'default', 'objects');

// Explicit unique relationship names for all lookup and master-detail fields
const relationshipMap = {
  'Warehouse__c/Distributor__c': 'Warehouses',
  'Distributor__c/Default_Warehouse__c': 'Primary_Distributors',
  'Retailer__c/Territory__c': 'Territory_Retailers',
  'Retailer__c/Primary_Distributor__c': 'Primary_Serviced_Retailers',
  'Retailer__c/Backup_Distributor__c': 'Backup_Serviced_Retailers',
  'Beat__c/Territory__c': 'Territory_Beats',
  'Retailer_Beat_Mapping__c/Retailer__c': 'Beat_Mappings',
  'Retailer_Beat_Mapping__c/Beat__c': 'Retailer_Mappings',
  'Visit__c/Retailer__c': 'Retailer_Visits',
  'Visit__c/Beat__c': 'Beat_Visits',
  'Inventory__c/Warehouse__c': 'Warehouse_Inventories',
  'Inventory__c/Product__c': 'Product_Inventories',
  'Inventory_Batch__c/Inventory__c': 'Batches',
  'Inventory_Ledger__c/Inventory__c': 'Inventory_Ledgers',
  'Order__c/Retailer__c': 'Retailer_Orders',
  'Order__c/Primary_Distributor__c': 'Distributor_Orders',
  'Order__c/Visit__c': 'Visit_Orders',
  'Order_Line__c/Order__c': 'Order_Lines',
  'Order_Line__c/Product__c': 'Product_Order_Lines',
  'Order_Line__c/Fulfilling_Distributor__c': 'Fulfilled_Order_Lines',
  'Invoice__c/Order__c': 'Invoices',
  'Payment__c/Retailer__c': 'Retailer_Payments',
  'Payment__c/Order__c': 'Order_Payments'
};

// 1. Update relationship names in field metadata
Object.keys(relationshipMap).forEach(key => {
  const [obj, field] = key.split('/');
  const filePath = path.join(objectsDir, obj, 'fields', `${field}.field-meta.xml`);
  if (fs.existsSync(filePath)) {
    let content = fs.readFileSync(filePath, 'utf8');
    const relName = relationshipMap[key];
    content = content.replace(/<relationshipName>.*?<\/relationshipName>/, `<relationshipName>${relName}</relationshipName>`);
    fs.writeFileSync(filePath, content, 'utf8');
    console.log(`Updated ${key} relationshipName to -> ${relName}`);
  }
});

// 2. Re-generate SFA_DMS_Admin permission set excluding required fields and formulas
const permSetDir = path.join(__dirname, '..', 'force-app', 'main', 'default', 'permissionsets');
const objectNames = fs.readdirSync(objectsDir).filter(f => f.endsWith('__c')).sort();

let classAccessesXml = '';
const apexClasses = ['OrderReservationRestService', 'SyncBootstrapRestService'].sort();
apexClasses.forEach(cls => {
  classAccessesXml += `    <classAccesses>
        <apexClass>${cls}</apexClass>
        <enabled>true</enabled>
    </classAccesses>\n`;
});

let objectPermissionsXml = '';
objectNames.forEach(obj => {
  objectPermissionsXml += `    <objectPermissions>
        <allowCreate>true</allowCreate>
        <allowDelete>true</allowDelete>
        <allowEdit>true</allowEdit>
        <allowRead>true</allowRead>
        <modifyAllRecords>true</modifyAllRecords>
        <object>${obj}</object>
        <viewAllRecords>true</viewAllRecords>
    </objectPermissions>\n`;
});

let fieldPermissionsList = [];
objectNames.forEach(obj => {
  const fieldsDir = path.join(objectsDir, obj, 'fields');
  if (fs.existsSync(fieldsDir)) {
    const fieldFiles = fs.readdirSync(fieldsDir);
    fieldFiles.forEach(ff => {
      const fieldName = ff.replace('.field-meta.xml', '');
      const fieldContent = fs.readFileSync(path.join(fieldsDir, ff), 'utf8');
      
      const isFormula = fieldContent.includes('<formula>');
      const isMasterDetail = fieldContent.includes('<type>MasterDetail</type>');
      const isRequired = fieldContent.includes('<required>true</required>');

      // In Salesforce, fields that are required or MasterDetail cannot have field permissions in Permission Sets
      if (!isRequired && !isMasterDetail) {
        fieldPermissionsList.push({
          field: `${obj}.${fieldName}`,
          editable: !isFormula,
          readable: true
        });
      }
    });
  }
});

fieldPermissionsList.sort((a, b) => a.field.localeCompare(b.field));

let fieldPermissionsXml = '';
fieldPermissionsList.forEach(fp => {
  fieldPermissionsXml += `    <fieldPermissions>
        <editable>${fp.editable}</editable>
        <field>${fp.field}</field>
        <readable>true</readable>
    </fieldPermissions>\n`;
});

let tabSettingsXml = '';
const tabsDir = path.join(__dirname, '..', 'force-app', 'main', 'default', 'tabs');
if (fs.existsSync(tabsDir)) {
  const tabFiles = fs.readdirSync(tabsDir).sort();
  tabFiles.forEach(tf => {
    const tabName = tf.replace('.tab-meta.xml', '');
    tabSettingsXml += `    <tabSettings>
        <tab>${tabName}</tab>
        <visibility>Visible</visibility>
    </tabSettings>\n`;
  });
}

const permXml = `<?xml version="1.0" encoding="UTF-8"?>
<PermissionSet xmlns="http://soap.sforce.com/2006/04/metadata">
    <description>Full Administrator and Integration Access to SFA and DMS Objects and Services</description>
    <hasActivationRequired>false</hasActivationRequired>
    <label>SFA DMS Admin &amp; API Integration</label>
${classAccessesXml}${fieldPermissionsXml}${objectPermissionsXml}${tabSettingsXml}</PermissionSet>
`;

fs.writeFileSync(path.join(permSetDir, 'SFA_DMS_Admin.permissionset-meta.xml'), permXml, 'utf8');
console.log('Fixed all relationships and re-generated PermissionSet cleanly.');
