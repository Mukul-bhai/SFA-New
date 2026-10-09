const fs = require('fs');
const path = require('path');

const baseDir = path.join(__dirname, '..', 'force-app', 'main', 'default');
const objectsDir = path.join(baseDir, 'objects');

// Object Definitions
const objects = [
  {
    name: 'Distributor__c',
    label: 'Distributor',
    pluralLabel: 'Distributors',
    description: 'Distributor entity holding inventory and servicing retailers',
    sharingModel: 'ReadWrite',
    fields: [
      { name: 'Distributor_Code__c', label: 'Distributor Code', type: 'Text', length: 30, unique: true, externalId: true, required: true },
      { name: 'Contact_Person__c', label: 'Contact Person', type: 'Lookup', referenceTo: 'Contact' },
      { name: 'GSTIN__c', label: 'GSTIN', type: 'Text', length: 15 },
      { name: 'Credit_Limit__c', label: 'Credit Limit', type: 'Currency', precision: 16, scale: 2 },
      { name: 'Current_Outstanding__c', label: 'Current Outstanding', type: 'Currency', precision: 16, scale: 2, defaultValue: '0' },
      { name: 'Status__c', label: 'Status', type: 'Picklist', values: ['Onboarding', 'Pending_Approval', 'Active', 'Suspended', 'Inactive'], defaultValue: 'Active' },
      { name: 'Default_Warehouse__c', label: 'Default Warehouse', type: 'Lookup', referenceTo: 'Warehouse__c' }
    ]
  },
  {
    name: 'Warehouse__c',
    label: 'Warehouse',
    pluralLabel: 'Warehouses',
    description: 'Physical storage depots operated by distributors',
    sharingModel: 'ControlledByParent',
    fields: [
      { name: 'Warehouse_Code__c', label: 'Warehouse Code', type: 'Text', length: 30, unique: true, externalId: true, required: true },
      { name: 'Distributor__c', label: 'Distributor', type: 'MasterDetail', referenceTo: 'Distributor__c', required: true, writeRequiresMasterRead: false },
      { name: 'Address__c', label: 'Address', type: 'LongTextArea', length: 32768, visibleLines: 3 },
      { name: 'Geolocation__c', label: 'Geolocation', type: 'Location', displayLocationInDecimal: true, scale: 6 },
      { name: 'Is_Active__c', label: 'Is Active', type: 'Checkbox', defaultValue: 'true' }
    ]
  },
  {
    name: 'Territory__c',
    label: 'Territory',
    pluralLabel: 'Territories',
    description: 'Geographic sales territory',
    sharingModel: 'ReadWrite',
    fields: [
      { name: 'Territory_Code__c', label: 'Territory Code', type: 'Text', length: 30, unique: true, externalId: true, required: true },
      { name: 'Region__c', label: 'Region', type: 'Picklist', values: ['North', 'South', 'East', 'West', 'Central'] },
      { name: 'State__c', label: 'State', type: 'Text', length: 50 },
      { name: 'Area__c', label: 'Area', type: 'Text', length: 50 }
    ]
  },
  {
    name: 'Beat__c',
    label: 'Beat',
    pluralLabel: 'Beats',
    description: 'Specific route mapped to day of week',
    sharingModel: 'ControlledByParent',
    fields: [
      { name: 'Beat_Code__c', label: 'Beat Code', type: 'Text', length: 30, unique: true, externalId: true, required: true },
      { name: 'Territory__c', label: 'Territory', type: 'MasterDetail', referenceTo: 'Territory__c', required: true, writeRequiresMasterRead: false },
      { name: 'Day_Of_Week__c', label: 'Day Of Week', type: 'Picklist', values: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'] },
      { name: 'Assigned_Executive__c', label: 'Assigned Executive', type: 'Lookup', referenceTo: 'User' }
    ]
  },
  {
    name: 'Retailer__c',
    label: 'Retailer',
    pluralLabel: 'Retailers',
    description: 'Retail stores and kiranas visited by sales representatives',
    sharingModel: 'ReadWrite',
    fields: [
      { name: 'Retailer_Code__c', label: 'Retailer Code', type: 'Text', length: 30, unique: true, externalId: true, required: true },
      { name: 'Shop_Name__c', label: 'Shop Name', type: 'Text', length: 100 },
      { name: 'Owner_Phone__c', label: 'Owner Phone', type: 'Phone' },
      { name: 'Territory__c', label: 'Territory', type: 'Lookup', referenceTo: 'Territory__c' },
      { name: 'Primary_Distributor__c', label: 'Primary Distributor', type: 'Lookup', referenceTo: 'Distributor__c' },
      { name: 'Backup_Distributor__c', label: 'Backup Distributor', type: 'Lookup', referenceTo: 'Distributor__c' },
      { name: 'Allow_Backup_Fulfillment__c', label: 'Allow Backup Fulfillment', type: 'Checkbox', defaultValue: 'false' },
      { name: 'Geolocation__c', label: 'Geolocation', type: 'Location', displayLocationInDecimal: true, scale: 6 },
      { name: 'Geofence_Radius_Meters__c', label: 'Geofence Radius (Meters)', type: 'Number', precision: 5, scale: 0, defaultValue: '100' },
      { name: 'Credit_Limit__c', label: 'Credit Limit', type: 'Currency', precision: 16, scale: 2, defaultValue: '10000' },
      { name: 'Outstanding_Balance__c', label: 'Outstanding Balance', type: 'Currency', precision: 16, scale: 2, defaultValue: '0' },
      { name: 'Credit_Hold__c', label: 'Credit Hold', type: 'Checkbox', defaultValue: 'false' },
      { name: 'Verification_Status__c', label: 'Verification Status', type: 'Picklist', values: ['Unverified', 'Verified', 'Rejected'], defaultValue: 'Verified' }
    ]
  },
  {
    name: 'Retailer_Beat_Mapping__c',
    label: 'Retailer Beat Mapping',
    pluralLabel: 'Retailer Beat Mappings',
    description: 'Junction mapping retailers to beats with sequence order',
    sharingModel: 'ControlledByParent',
    fields: [
      { name: 'Retailer__c', label: 'Retailer', type: 'MasterDetail', referenceTo: 'Retailer__c', required: true, writeRequiresMasterRead: false },
      { name: 'Beat__c', label: 'Beat', type: 'MasterDetail', referenceTo: 'Beat__c', required: true, writeRequiresMasterRead: false },
      { name: 'Sequence_Order__c', label: 'Sequence Order', type: 'Number', precision: 4, scale: 0, defaultValue: '1' }
    ]
  },
  {
    name: 'Attendance__c',
    label: 'Attendance',
    pluralLabel: 'Attendances',
    description: 'Daily punch in and out record for sales reps',
    sharingModel: 'ReadWrite',
    fields: [
      { name: 'Sales_Executive__c', label: 'Sales Executive', type: 'Lookup', referenceTo: 'User' },
      { name: 'Punch_In_Time__c', label: 'Punch In Time', type: 'DateTime' },
      { name: 'Punch_In_Location__c', label: 'Punch In Location', type: 'Location', displayLocationInDecimal: true, scale: 6 },
      { name: 'Punch_In_Battery_Level__c', label: 'Punch In Battery Level (%)', type: 'Percent', precision: 3, scale: 0 },
      { name: 'Punch_Out_Time__c', label: 'Punch Out Time', type: 'DateTime' },
      { name: 'Punch_Out_Location__c', label: 'Punch Out Location', type: 'Location', displayLocationInDecimal: true, scale: 6 },
      { name: 'Status__c', label: 'Status', type: 'Picklist', values: ['Punched_In', 'Punched_Out', 'Regularized', 'Leave'], defaultValue: 'Punched_In' },
      { name: 'Total_Distance_KM__c', label: 'Total Distance (KM)', type: 'Number', precision: 6, scale: 2, defaultValue: '0' }
    ]
  },
  {
    name: 'Visit__c',
    label: 'Visit',
    pluralLabel: 'Visits',
    description: 'Store visit conducted by sales rep',
    sharingModel: 'ReadWrite',
    fields: [
      { name: 'Retailer__c', label: 'Retailer', type: 'Lookup', referenceTo: 'Retailer__c' },
      { name: 'Sales_Executive__c', label: 'Sales Executive', type: 'Lookup', referenceTo: 'User' },
      { name: 'Beat__c', label: 'Beat', type: 'Lookup', referenceTo: 'Beat__c' },
      { name: 'Check_In_Time__c', label: 'Check In Time', type: 'DateTime' },
      { name: 'Check_Out_Time__c', label: 'Check Out Time', type: 'DateTime' },
      { name: 'Check_In_Location__c', label: 'Check In Location', type: 'Location', displayLocationInDecimal: true, scale: 6 },
      { name: 'Is_Within_Geofence__c', label: 'Is Within Geofence', type: 'Checkbox', defaultValue: 'true' },
      { name: 'Geofence_Deviation_Distance_Meters__c', label: 'Geofence Deviation (Meters)', type: 'Number', precision: 8, scale: 2, defaultValue: '0' },
      { name: 'Visit_Status__c', label: 'Visit Status', type: 'Picklist', values: ['In_Progress', 'Completed', 'Skipped', 'Store_Closed', 'Refused'], defaultValue: 'In_Progress' },
      { name: 'Skip_Reason__c', label: 'Skip Reason', type: 'Picklist', values: ['Retailer_Closed', 'Stock_Full', 'Payment_Dispute', 'Personal_Emergency'] },
      { name: 'Order_Placed__c', label: 'Order Placed', type: 'Checkbox', defaultValue: 'false' }
    ]
  },
  {
    name: 'Inventory__c',
    label: 'Inventory',
    pluralLabel: 'Inventories',
    description: 'Stock tracking header per Warehouse and Product',
    sharingModel: 'ControlledByParent',
    fields: [
      { name: 'Warehouse__c', label: 'Warehouse', type: 'MasterDetail', referenceTo: 'Warehouse__c', required: true, writeRequiresMasterRead: false },
      { name: 'Product__c', label: 'Product', type: 'Lookup', referenceTo: 'Product2' },
      { name: 'Warehouse_Product_Key__c', label: 'Warehouse Product Key', type: 'Text', length: 80, unique: true, externalId: true },
      { name: 'Physical_Stock__c', label: 'Physical Stock', type: 'Number', precision: 12, scale: 2, defaultValue: '0' },
      { name: 'Reserved_Stock__c', label: 'Reserved Stock', type: 'Number', precision: 12, scale: 2, defaultValue: '0' },
      { name: 'Blocked_Stock__c', label: 'Blocked Stock', type: 'Number', precision: 12, scale: 2, defaultValue: '0' },
      { name: 'Damaged_Stock__c', label: 'Damaged Stock', type: 'Number', precision: 12, scale: 2, defaultValue: '0' },
      { name: 'Expired_Stock__c', label: 'Expired Stock', type: 'Number', precision: 12, scale: 2, defaultValue: '0' },
      { 
        name: 'Available_Stock__c', 
        label: 'Available Stock', 
        type: 'Formula', 
        formula: 'Physical_Stock__c - (Reserved_Stock__c + Blocked_Stock__c + Damaged_Stock__c + Expired_Stock__c)',
        formulaTreatBlanksAs: 'BlankAsZero',
        precision: 12, 
        scale: 2 
      }
    ]
  },
  {
    name: 'Inventory_Batch__c',
    label: 'Inventory Batch',
    pluralLabel: 'Inventory Batches',
    description: 'Batch details for lot tracking and expiry',
    sharingModel: 'ControlledByParent',
    fields: [
      { name: 'Inventory__c', label: 'Inventory', type: 'MasterDetail', referenceTo: 'Inventory__c', required: true, writeRequiresMasterRead: false },
      { name: 'Batch_Number__c', label: 'Batch Number', type: 'Text', length: 50, required: true },
      { name: 'Manufacturing_Date__c', label: 'Manufacturing Date', type: 'Date' },
      { name: 'Expiry_Date__c', label: 'Expiry Date', type: 'Date' },
      { name: 'Quantity__c', label: 'Quantity', type: 'Number', precision: 12, scale: 2, defaultValue: '0' },
      { name: 'MRP__c', label: 'MRP', type: 'Currency', precision: 12, scale: 2 }
    ]
  },
  {
    name: 'Inventory_Ledger__c',
    label: 'Inventory Ledger',
    pluralLabel: 'Inventory Ledgers',
    description: 'Immutable ledger record for every stock change',
    sharingModel: 'ControlledByParent',
    fields: [
      { name: 'Inventory__c', label: 'Inventory', type: 'MasterDetail', referenceTo: 'Inventory__c', required: true, writeRequiresMasterRead: false },
      { name: 'Type__c', label: 'Type', type: 'Picklist', values: ['GRN_Receipt', 'Order_Reservation', 'Order_Dispatch', 'Stock_Adjustment', 'Transfer_In', 'Transfer_Out', 'Damage_WriteOff', 'Reservation_Release'], defaultValue: 'Order_Reservation' },
      { name: 'Quantity_Delta__c', label: 'Quantity Delta', type: 'Number', precision: 12, scale: 2 },
      { name: 'Reference_Record_Id__c', label: 'Reference Record ID', type: 'Text', length: 50 },
      { name: 'Notes__c', label: 'Notes', type: 'Text', length: 255 },
      { name: 'Timestamp__c', label: 'Timestamp', type: 'DateTime' }
    ]
  },
  {
    name: 'Order__c',
    label: 'Order',
    pluralLabel: 'Orders',
    description: 'Sales Order placed by sales reps or retailers',
    sharingModel: 'ReadWrite',
    fields: [
      { name: 'Retailer__c', label: 'Retailer', type: 'Lookup', referenceTo: 'Retailer__c' },
      { name: 'Primary_Distributor__c', label: 'Primary Distributor', type: 'Lookup', referenceTo: 'Distributor__c' },
      { name: 'Sales_Executive__c', label: 'Sales Executive', type: 'Lookup', referenceTo: 'User' },
      { name: 'Visit__c', label: 'Visit', type: 'Lookup', referenceTo: 'Visit__c' },
      { name: 'Idempotency_Key__c', label: 'Idempotency Key', type: 'Text', length: 64, unique: true, externalId: true },
      { name: 'Order_Date__c', label: 'Order Date', type: 'DateTime' },
      { name: 'Status__c', label: 'Status', type: 'Picklist', values: ['Draft', 'Submitted', 'Approved', 'Credit_Hold', 'Processing', 'Dispatched', 'Delivered', 'Cancelled'], defaultValue: 'Submitted' },
      { name: 'Total_Amount__c', label: 'Total Amount', type: 'Currency', precision: 16, scale: 2, defaultValue: '0' },
      { name: 'Discount_Amount__c', label: 'Discount Amount', type: 'Currency', precision: 16, scale: 2, defaultValue: '0' }
    ]
  },
  {
    name: 'Order_Line__c',
    label: 'Order Line',
    pluralLabel: 'Order Lines',
    description: 'Line item of sales order',
    sharingModel: 'ControlledByParent',
    fields: [
      { name: 'Order__c', label: 'Order', type: 'MasterDetail', referenceTo: 'Order__c', required: true, writeRequiresMasterRead: false },
      { name: 'Product__c', label: 'Product', type: 'Lookup', referenceTo: 'Product2' },
      { name: 'Quantity__c', label: 'Quantity', type: 'Number', precision: 10, scale: 2, defaultValue: '1' },
      { name: 'Unit_Price__c', label: 'Unit Price', type: 'Currency', precision: 12, scale: 2, defaultValue: '0' },
      { name: 'Fulfilling_Distributor__c', label: 'Fulfilling Distributor', type: 'Lookup', referenceTo: 'Distributor__c' },
      { name: 'Fulfillment_Status__c', label: 'Fulfillment Status', type: 'Picklist', values: ['Allocated_Primary', 'Allocated_Backup', 'Backordered', 'Cancelled'], defaultValue: 'Allocated_Primary' },
      {
        name: 'Line_Total__c',
        label: 'Line Total',
        type: 'Formula',
        formula: 'Quantity__c * Unit_Price__c',
        formulaTreatBlanksAs: 'BlankAsZero',
        precision: 16,
        scale: 2
      }
    ]
  },
  {
    name: 'Invoice__c',
    label: 'Invoice',
    pluralLabel: 'Invoices',
    description: 'Billing invoice generated against sales order',
    sharingModel: 'ReadWrite',
    fields: [
      { name: 'Order__c', label: 'Order', type: 'Lookup', referenceTo: 'Order__c' },
      { name: 'Invoice_Number__c', label: 'Invoice Number', type: 'Text', length: 50, unique: true, externalId: true },
      { name: 'Invoice_Date__c', label: 'Invoice Date', type: 'Date' },
      { name: 'Invoice_Amount__c', label: 'Invoice Amount', type: 'Currency', precision: 16, scale: 2 },
      { name: 'Status__c', label: 'Status', type: 'Picklist', values: ['Draft', 'Issued', 'Paid', 'Partially_Paid', 'Cancelled'], defaultValue: 'Issued' }
    ]
  },
  {
    name: 'Payment__c',
    label: 'Payment',
    pluralLabel: 'Payments',
    description: 'Payment collected from retailer',
    sharingModel: 'ReadWrite',
    fields: [
      { name: 'Retailer__c', label: 'Retailer', type: 'Lookup', referenceTo: 'Retailer__c' },
      { name: 'Order__c', label: 'Order', type: 'Lookup', referenceTo: 'Order__c' },
      { name: 'Payment_Mode__c', label: 'Payment Mode', type: 'Picklist', values: ['Cash', 'Cheque', 'UPI', 'Bank_Transfer'], defaultValue: 'Cash' },
      { name: 'Amount__c', label: 'Amount', type: 'Currency', precision: 16, scale: 2 },
      { name: 'Transaction_Reference__c', label: 'Transaction Reference', type: 'Text', length: 60 },
      { name: 'Status__c', label: 'Status', type: 'Picklist', values: ['Pending', 'Confirmed', 'Bounced', 'Failed'], defaultValue: 'Confirmed' }
    ]
  }
];

function generateObjectXml(obj) {
  return `<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <actionOverrides>
        <actionName>Accept</actionName>
        <type>Default</type>
    </actionOverrides>
    <actionOverrides>
        <actionName>CancelEdit</actionName>
        <type>Default</type>
    </actionOverrides>
    <actionOverrides>
        <actionName>Clone</actionName>
        <type>Default</type>
    </actionOverrides>
    <actionOverrides>
        <actionName>Delete</actionName>
        <type>Default</type>
    </actionOverrides>
    <actionOverrides>
        <actionName>Edit</actionName>
        <type>Default</type>
    </actionOverrides>
    <actionOverrides>
        <actionName>List</actionName>
        <type>Default</type>
    </actionOverrides>
    <actionOverrides>
        <actionName>New</actionName>
        <type>Default</type>
    </actionOverrides>
    <actionOverrides>
        <actionName>SaveEdit</actionName>
        <type>Default</type>
    </actionOverrides>
    <actionOverrides>
        <actionName>Tab</actionName>
        <type>Default</type>
    </actionOverrides>
    <actionOverrides>
        <actionName>View</actionName>
        <type>Default</type>
    </actionOverrides>
    <allowInChatterGroups>false</allowInChatterGroups>
    <compactLayoutAssignment>SYSTEM</compactLayoutAssignment>
    <deploymentStatus>Deployed</deploymentStatus>
    <description>${obj.description}</description>
    <enableActivities>true</enableActivities>
    <enableBulkApi>true</enableBulkApi>
    <enableFeeds>false</enableFeeds>
    <enableHistory>true</enableHistory>
    <enableLicensing>false</enableLicensing>
    <enableReports>true</enableReports>
    <enableSearch>true</enableSearch>
    <enableSharing>true</enableSharing>
    <enableStreamingApi>true</enableStreamingApi>
    <label>${obj.label}</label>
    <nameField>
        <label>${obj.label} Name</label>
        <type>Text</type>
    </nameField>
    <pluralLabel>${obj.pluralLabel}</pluralLabel>
    <sharingModel>${obj.sharingModel}</sharingModel>
    <visibility>Public</visibility>
</CustomObject>
`;
}

function generateFieldXml(field) {
  let xml = `<?xml version="1.0" encoding="UTF-8"?>\n<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">\n`;
  xml += `    <fullName>${field.name}</fullName>\n`;
  xml += `    <label>${field.label}</label>\n`;

  if (field.type === 'Text') {
    xml += `    <type>Text</type>\n`;
    xml += `    <length>${field.length || 255}</length>\n`;
    if (field.unique) xml += `    <unique>true</unique>\n`;
    if (field.externalId) xml += `    <externalId>true</externalId>\n`;
    if (field.required) xml += `    <required>true</required>\n`;
  } else if (field.type === 'LongTextArea') {
    xml += `    <type>LongTextArea</type>\n`;
    xml += `    <length>${field.length}</length>\n`;
    xml += `    <visibleLines>${field.visibleLines || 3}</visibleLines>\n`;
  } else if (field.type === 'Number') {
    xml += `    <type>Number</type>\n`;
    xml += `    <precision>${field.precision}</precision>\n`;
    xml += `    <scale>${field.scale}</scale>\n`;
    if (field.defaultValue) xml += `    <defaultValue>${field.defaultValue}</defaultValue>\n`;
    if (field.unique) xml += `    <unique>true</unique>\n`;
    if (field.externalId) xml += `    <externalId>true</externalId>\n`;
  } else if (field.type === 'Currency') {
    xml += `    <type>Currency</type>\n`;
    xml += `    <precision>${field.precision}</precision>\n`;
    xml += `    <scale>${field.scale}</scale>\n`;
    if (field.defaultValue) xml += `    <defaultValue>${field.defaultValue}</defaultValue>\n`;
  } else if (field.type === 'Percent') {
    xml += `    <type>Percent</type>\n`;
    xml += `    <precision>${field.precision}</precision>\n`;
    xml += `    <scale>${field.scale}</scale>\n`;
  } else if (field.type === 'Checkbox') {
    xml += `    <type>Checkbox</type>\n`;
    xml += `    <defaultValue>${field.defaultValue || 'false'}</defaultValue>\n`;
  } else if (field.type === 'Phone') {
    xml += `    <type>Phone</type>\n`;
  } else if (field.type === 'Date') {
    xml += `    <type>Date</type>\n`;
  } else if (field.type === 'DateTime') {
    xml += `    <type>DateTime</type>\n`;
  } else if (field.type === 'Location') {
    xml += `    <type>Location</type>\n`;
    xml += `    <displayLocationInDecimal>${field.displayLocationInDecimal}</displayLocationInDecimal>\n`;
    xml += `    <scale>${field.scale}</scale>\n`;
  } else if (field.type === 'Lookup') {
    xml += `    <type>Lookup</type>\n`;
    xml += `    <referenceTo>${field.referenceTo}</referenceTo>\n`;
    xml += `    <relationshipName>${field.name.replace('__c', '')}s</relationshipName>\n`;
    if (field.required) xml += `    <required>true</required>\n`;
  } else if (field.type === 'MasterDetail') {
    xml += `    <type>MasterDetail</type>\n`;
    xml += `    <referenceTo>${field.referenceTo}</referenceTo>\n`;
    xml += `    <relationshipName>${field.name.replace('__c', '')}s</relationshipName>\n`;
    xml += `    <relationshipOrder>0</relationshipOrder>\n`;
    xml += `    <reparentableMasterDetail>false</reparentableMasterDetail>\n`;
    xml += `    <writeRequiresMasterRead>${field.writeRequiresMasterRead || false}</writeRequiresMasterRead>\n`;
  } else if (field.type === 'Picklist') {
    xml += `    <type>Picklist</type>\n`;
    xml += `    <valueSet>\n`;
    xml += `        <valueSetDefinition>\n`;
    xml += `            <sorted>false</sorted>\n`;
    field.values.forEach(v => {
      xml += `            <value>\n`;
      xml += `                <fullName>${v}</fullName>\n`;
      xml += `                <default>${v === field.defaultValue ? 'true' : 'false'}</default>\n`;
      xml += `                <label>${v.replace(/_/g, ' ')}</label>\n`;
      xml += `            </value>\n`;
    });
    xml += `        </valueSetDefinition>\n`;
    xml += `    </valueSet>\n`;
  } else if (field.type === 'Formula') {
    xml += `    <type>Number</type>\n`;
    xml += `    <formula>${field.formula.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')}</formula>\n`;
    xml += `    <formulaTreatBlanksAs>${field.formulaTreatBlanksAs || 'BlankAsZero'}</formulaTreatBlanksAs>\n`;
    xml += `    <precision>${field.precision}</precision>\n`;
    xml += `    <scale>${field.scale}</scale>\n`;
  }

  xml += `</CustomField>\n`;
  return xml;
}

// Generate files
objects.forEach(obj => {
  const objDir = path.join(objectsDir, obj.name);
  const fieldsDir = path.join(objDir, 'fields');
  
  fs.mkdirSync(fieldsDir, { recursive: true });
  
  fs.writeFileSync(path.join(objDir, `${obj.name}.object-meta.xml`), generateObjectXml(obj), 'utf8');
  
  obj.fields.forEach(f => {
    fs.writeFileSync(path.join(fieldsDir, `${f.name}.field-meta.xml`), generateFieldXml(f), 'utf8');
  });
  
  console.log(`Created schema for ${obj.name} with ${obj.fields.length} fields.`);
});

console.log('Finished generating all Salesforce Custom Objects & Fields.');
