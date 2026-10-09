const fs = require('fs');
const path = require('path');

const baseDir = path.join(__dirname, '..', 'force-app', 'main', 'default');
const objectsDir = path.join(baseDir, 'objects');

function ensureDir(dir) {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

function fieldXml(field) {
  let xml = `<?xml version="1.0" encoding="UTF-8"?>\n<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">\n`;
  xml += `    <fullName>${field.fullName}</fullName>\n`;
  if (field.label) xml += `    <label>${field.label}</label>\n`;
  if (field.description) xml += `    <description>${field.description}</description>\n`;
  if (field.type) xml += `    <type>${field.type}</type>\n`;
  if (field.required) xml += `    <required>${field.required}</required>\n`;
  if (field.unique) xml += `    <unique>${field.unique}</unique>\n`;
  if (field.externalId) xml += `    <externalId>${field.externalId}</externalId>\n`;
  if (field.length) xml += `    <length>${field.length}</length>\n`;
  if (field.precision) xml += `    <precision>${field.precision}</precision>\n`;
  if (field.scale !== undefined) xml += `    <scale>${field.scale}</scale>\n`;
  if (field.displayLocationInDecimal !== undefined) xml += `    <displayLocationInDecimal>${field.displayLocationInDecimal}</displayLocationInDecimal>\n`;
  if (field.visibleLines) xml += `    <visibleLines>${field.visibleLines}</visibleLines>\n`;
  if (field.defaultValue !== undefined) xml += `    <defaultValue>${field.defaultValue}</defaultValue>\n`;
  if (field.displayFormat) xml += `    <displayFormat>${field.displayFormat}</displayFormat>\n`;
  if (field.startingNumber !== undefined) xml += `    <startingNumber>${field.startingNumber}</startingNumber>\n`;
  if (field.referenceTo) xml += `    <referenceTo>${field.referenceTo}</referenceTo>\n`;
  if (field.relationshipLabel) xml += `    <relationshipLabel>${field.relationshipLabel}</relationshipLabel>\n`;
  if (field.relationshipName) xml += `    <relationshipName>${field.relationshipName}</relationshipName>\n`;
  if (field.deleteConstraint) xml += `    <deleteConstraint>${field.deleteConstraint}</deleteConstraint>\n`;

  if (field.valueSet) {
    xml += `    <valueSet>\n        <restricted>${field.valueSet.restricted || false}</restricted>\n        <valueSetDefinition>\n            <sorted>false</sorted>\n`;
    field.valueSet.values.forEach(v => {
      xml += `            <value>\n                <fullName>${v}</fullName>\n                <default>${v === field.valueSet.defaultVal}</default>\n                <label>${v}</label>\n            </value>\n`;
    });
    xml += `        </valueSetDefinition>\n    </valueSet>\n`;
  }

  xml += `</CustomField>\n`;
  return xml;
}

function objectXml(obj) {
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
    <allowInChatterGroups>true</allowInChatterGroups>
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
        <label>${obj.nameFieldLabel || obj.label + ' Name'}</label>
        <type>Text</type>
    </nameField>
    <pluralLabel>${obj.pluralLabel}</pluralLabel>
    <sharingModel>${obj.sharingModel || 'ReadWrite'}</sharingModel>
    <visibility>Public</visibility>
</CustomObject>
`;
}

// ==========================================
// 1. Employee__c
// ==========================================
const empDir = path.join(objectsDir, 'Employee__c');
ensureDir(empDir);
fs.writeFileSync(path.join(empDir, 'Employee__c.object-meta.xml'), objectXml({
  label: 'Employee',
  pluralLabel: 'Employees',
  description: 'Employee details with hierarchy levels, reporting manager and multi-level Indian geography',
  nameFieldLabel: 'Employee Name'
}), 'utf8');

const empFieldsDir = path.join(empDir, 'fields');
ensureDir(empFieldsDir);

const employeeFields = [
  { fullName: 'Employee_Code__c', label: 'Employee Code', type: 'AutoNumber', displayFormat: 'EMP-{0000}', startingNumber: 101 },
  { fullName: 'User__c', label: 'User Account', type: 'Lookup', referenceTo: 'User', relationshipName: 'Employees_User', relationshipLabel: 'Employees', deleteConstraint: 'SetNull' },
  { fullName: 'Aadhar_Number__c', label: 'Aadhar Number', type: 'Text', length: 12, description: '12-digit Indian Aadhar number' },
  { fullName: 'Pan_Number__c', label: 'PAN Number', type: 'Text', length: 10, description: '10-character PAN number' },
  { fullName: 'Phone_Number__c', label: 'Phone Number', type: 'Phone' },
  { fullName: 'Emergency_Contact__c', label: 'Emergency Contact', type: 'Phone' },
  { fullName: 'Email__c', label: 'Email', type: 'Email' },
  { fullName: 'Reporting_Manager__c', label: 'Reporting Manager', type: 'Lookup', referenceTo: 'User', relationshipName: 'Employees_Manager', relationshipLabel: 'Reporting Subordinates', deleteConstraint: 'SetNull' },
  { fullName: 'Reporting_Manager_Employee__c', label: 'Reporting Manager (Employee)', type: 'Lookup', referenceTo: 'Employee__c', relationshipName: 'Subordinates', relationshipLabel: 'Subordinate Employees', deleteConstraint: 'SetNull' },
  { fullName: 'Profile_Pic__c', label: 'Profile Pic', type: 'Url' },
  {
    fullName: 'Hierarchy_Level__c', label: 'Hierarchy Level', type: 'Picklist',
    valueSet: {
      restricted: true,
      values: [
        'L1 - Viresh',
        'L2 - Dinesh',
        'L3 - Aishwarya',
        'L4 - Bhavya',
        'L5 - Teja',
        'L6 - Shreyas',
        'L7 - Anusha',
        'L8 - Rakesh',
        'L9 - Sunil (Super admin)'
      ],
      defaultVal: 'L1 - Viresh'
    }
  },
  {
    fullName: 'Status__c', label: 'Status', type: 'Picklist',
    valueSet: {
      restricted: true,
      values: ['Active', 'Inactive', 'On Leave'],
      defaultVal: 'Active'
    }
  },
  // Geography Dropdowns
  {
    fullName: 'Country__c', label: 'Country / Nation', type: 'Picklist',
    valueSet: {
      restricted: true,
      values: ['India', 'United States', 'United Kingdom', 'Other'],
      defaultVal: 'India'
    }
  },
  {
    fullName: 'State__c', label: 'State', type: 'Picklist',
    valueSet: {
      restricted: false,
      values: ['Karnataka', 'Maharashtra', 'Delhi', 'Gujarat', 'Tamil Nadu', 'Uttar Pradesh', 'Rajasthan', 'Telangana'],
      defaultVal: 'Karnataka'
    }
  },
  {
    fullName: 'District__c', label: 'District', type: 'Picklist',
    valueSet: {
      restricted: false,
      values: ['Bengaluru', 'Mysuru', 'Mumbai', 'Pune', 'South Delhi', 'Central Delhi', 'Ahmedabad', 'Surat', 'Chennai', 'Lucknow'],
      defaultVal: 'Bengaluru'
    }
  },
  {
    fullName: 'Town__c', label: 'Town', type: 'Picklist',
    valueSet: {
      restricted: false,
      values: ['MG road', 'Indiranagar', 'Koramangala', 'Whitefield', 'Jayanagar', 'Bandra', 'Andheri', 'Saket', 'CG Road'],
      defaultVal: 'MG road'
    }
  },
  {
    fullName: 'Municipality__c', label: 'Municipality', type: 'Picklist',
    valueSet: {
      restricted: false,
      values: ['Empty', 'BBMP - Bengaluru', 'BMC - Mumbai', 'MCD - Delhi', 'AMC - Ahmedabad'],
      defaultVal: 'Empty'
    }
  },
  {
    fullName: 'Village__c', label: 'Village', type: 'Picklist',
    valueSet: {
      restricted: false,
      values: ['Empty', 'Village 1', 'Village 2'],
      defaultVal: 'Empty'
    }
  },
  { fullName: 'Pincode__c', label: 'Pincode', type: 'Text', length: 10 }
];

employeeFields.forEach(f => {
  fs.writeFileSync(path.join(empFieldsDir, `${f.fullName}.field-meta.xml`), fieldXml(f), 'utf8');
});
console.log(`Created ${employeeFields.length} fields for Employee__c`);

// ==========================================
// 2. PJP__c (Permanent Journey Plan)
// ==========================================
const pjpDir = path.join(objectsDir, 'PJP__c');
ensureDir(pjpDir);
fs.writeFileSync(path.join(pjpDir, 'PJP__c.object-meta.xml'), objectXml({
  label: 'PJP',
  pluralLabel: 'PJPs',
  description: 'Permanent Journey Plan for monthly sales beat execution with reporting manager approval process',
  nameFieldLabel: 'PJP Name'
}), 'utf8');

const pjpFieldsDir = path.join(pjpDir, 'fields');
ensureDir(pjpFieldsDir);

const pjpFields = [
  { fullName: 'PJP_Code__c', label: 'PJP Code', type: 'AutoNumber', displayFormat: 'PJP-{0000}', startingNumber: 501 },
  { fullName: 'Employee__c', label: 'Employee', type: 'Lookup', referenceTo: 'Employee__c', relationshipName: 'PJPs', relationshipLabel: 'Journey Plans (PJP)', deleteConstraint: 'SetNull' },
  { fullName: 'User__c', label: 'Assigned User', type: 'Lookup', referenceTo: 'User', relationshipName: 'PJPs_User', relationshipLabel: 'Assigned PJPs', deleteConstraint: 'SetNull' },
  { fullName: 'Reporting_Manager__c', label: 'Reporting Manager (Approver)', type: 'Lookup', referenceTo: 'User', relationshipName: 'PJPs_Approver', relationshipLabel: 'Pending PJP Approvals', deleteConstraint: 'SetNull' },
  {
    fullName: 'Month__c', label: 'Month', type: 'Picklist',
    valueSet: {
      restricted: true,
      values: ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
      defaultVal: 'October'
    }
  },
  {
    fullName: 'Year__c', label: 'Year', type: 'Picklist',
    valueSet: {
      restricted: true,
      values: ['2024', '2025', '2026', '2027', '2028', '2029', '2030'],
      defaultVal: '2026'
    }
  },
  { fullName: 'Start_Date__c', label: 'Start Date', type: 'Date' },
  { fullName: 'End_Date__c', label: 'End Date', type: 'Date' },
  {
    fullName: 'Status__c', label: 'Status', type: 'Picklist',
    valueSet: {
      restricted: true,
      values: ['Draft', 'Submitted', 'Pending Approval', 'Approved', 'Rejected'],
      defaultVal: 'Draft'
    }
  },
  { fullName: 'Total_Beats__c', label: 'Total Beats', type: 'Number', precision: 4, scale: 0, defaultValue: '0' },
  { fullName: 'Total_Outlets__c', label: 'Total Outlets', type: 'Number', precision: 6, scale: 0, defaultValue: '0' },
  { fullName: 'Remarks__c', label: 'Remarks / Notes', type: 'LongTextArea', length: 1000, visibleLines: 3 },
  { fullName: 'Approval_Comments__c', label: 'Approval Comments', type: 'LongTextArea', length: 1000, visibleLines: 3 },
  { fullName: 'Approved_Date__c', label: 'Approved Date', type: 'DateTime' }
];

pjpFields.forEach(f => {
  fs.writeFileSync(path.join(pjpFieldsDir, `${f.fullName}.field-meta.xml`), fieldXml(f), 'utf8');
});
console.log(`Created ${pjpFields.length} fields for PJP__c`);

// ==========================================
// 3. Beat__c (Enrich Existing Object)
// ==========================================
const beatFieldsDir = path.join(objectsDir, 'Beat__c', 'fields');
ensureDir(beatFieldsDir);

const beatFieldsToAdd = [
  { fullName: 'Beat_ID__c', label: 'Beat ID', type: 'AutoNumber', displayFormat: 'BEAT-{0000}', startingNumber: 201 },
  { fullName: 'PJP__c', label: 'PJP', type: 'Lookup', referenceTo: 'PJP__c', relationshipName: 'Beats', relationshipLabel: 'Route Beats', deleteConstraint: 'SetNull' },
  { fullName: 'Assigned_To__c', label: 'Beat Assigned To (Employee)', type: 'Lookup', referenceTo: 'Employee__c', relationshipName: 'Assigned_Beats', relationshipLabel: 'Assigned Beats', deleteConstraint: 'SetNull' },
  { fullName: 'Distributor__c', label: 'Distributor', type: 'Lookup', referenceTo: 'Distributor__c', relationshipName: 'Beats', relationshipLabel: 'Route Beats', deleteConstraint: 'SetNull' },
  { fullName: 'Route_Date__c', label: 'Route Date', type: 'Date' },
  { fullName: 'Total_Outlets__c', label: 'Total Outlets', type: 'Number', precision: 4, scale: 0, defaultValue: '0' },
  // Geography on Beat
  {
    fullName: 'Country__c', label: 'Country', type: 'Picklist',
    valueSet: {
      restricted: true,
      values: ['India', 'Other'],
      defaultVal: 'India'
    }
  },
  {
    fullName: 'State__c', label: 'State', type: 'Picklist',
    valueSet: {
      restricted: false,
      values: ['Karnataka', 'Maharashtra', 'Delhi', 'Gujarat'],
      defaultVal: 'Karnataka'
    }
  },
  {
    fullName: 'District__c', label: 'District', type: 'Picklist',
    valueSet: {
      restricted: false,
      values: ['Bengaluru', 'Mysuru', 'Mumbai', 'South Delhi', 'Ahmedabad'],
      defaultVal: 'Bengaluru'
    }
  },
  {
    fullName: 'Town__c', label: 'Town', type: 'Picklist',
    valueSet: {
      restricted: false,
      values: ['MG road', 'Indiranagar', 'Koramangala', 'Whitefield', 'Jayanagar', 'Bandra', 'Saket', 'CG Road'],
      defaultVal: 'MG road'
    }
  },
  {
    fullName: 'Municipality__c', label: 'Municipality', type: 'Picklist',
    valueSet: {
      restricted: false,
      values: ['Empty', 'BBMP - Bengaluru', 'BMC - Mumbai'],
      defaultVal: 'Empty'
    }
  },
  {
    fullName: 'Village__c', label: 'Village', type: 'Picklist',
    valueSet: {
      restricted: false,
      values: ['Empty', 'Village 1'],
      defaultVal: 'Empty'
    }
  }
];

beatFieldsToAdd.forEach(f => {
  fs.writeFileSync(path.join(beatFieldsDir, `${f.fullName}.field-meta.xml`), fieldXml(f), 'utf8');
});
console.log(`Created ${beatFieldsToAdd.length} fields for Beat__c`);

// ==========================================
// 4. Outlet__c
// ==========================================
const outletDir = path.join(objectsDir, 'Outlet__c');
ensureDir(outletDir);
fs.writeFileSync(path.join(outletDir, 'Outlet__c.object-meta.xml'), objectXml({
  label: 'Outlet',
  pluralLabel: 'Outlets',
  description: 'Retail outlets and shops mapped to routes and beats, capturing KYC, owner, contact and geolocation',
  nameFieldLabel: 'Outlet Name'
}), 'utf8');

const outletFieldsDir = path.join(outletDir, 'fields');
ensureDir(outletFieldsDir);

const outletFields = [
  { fullName: 'Outlet_Code__c', label: 'Outlet Code', type: 'AutoNumber', displayFormat: 'OUT-{0000}', startingNumber: 1001 },
  { fullName: 'Beat__c', label: 'Beat', type: 'Lookup', referenceTo: 'Beat__c', relationshipName: 'Outlets', relationshipLabel: 'Route Outlets', deleteConstraint: 'SetNull' },
  { fullName: 'Outlet_Owner_Name__c', label: 'Outlet Owner Name', type: 'Text', length: 100 },
  { fullName: 'Contact_No__c', label: 'Contact No', type: 'Phone' },
  { fullName: 'Email__c', label: 'Email', type: 'Email' },
  { fullName: 'Aadhar_Number__c', label: 'Aadhar Number', type: 'Text', length: 12 },
  { fullName: 'Pan_Number__c', label: 'PAN Number', type: 'Text', length: 10 },
  { fullName: 'Geo_Location__c', label: 'Geo Location', type: 'Location', displayLocationInDecimal: true, scale: 6 },
  {
    fullName: 'Outlet_Type__c', label: 'Outlet Type', type: 'Picklist',
    valueSet: {
      restricted: true,
      values: ['Kirana', 'General Store', 'Supermarket', 'Wholesaler', 'Chemist', 'Paan Shop'],
      defaultVal: 'Kirana'
    }
  },
  { fullName: 'Sequence_Order__c', label: 'Sequence Order', type: 'Number', precision: 3, scale: 0 },
  // Geography on Outlet
  {
    fullName: 'Country__c', label: 'Country', type: 'Picklist',
    valueSet: {
      restricted: true,
      values: ['India', 'Other'],
      defaultVal: 'India'
    }
  },
  {
    fullName: 'State__c', label: 'State', type: 'Picklist',
    valueSet: {
      restricted: false,
      values: ['Karnataka', 'Maharashtra', 'Delhi', 'Gujarat'],
      defaultVal: 'Karnataka'
    }
  },
  {
    fullName: 'District__c', label: 'District', type: 'Picklist',
    valueSet: {
      restricted: false,
      values: ['Bengaluru', 'Mysuru', 'Mumbai', 'South Delhi', 'Ahmedabad'],
      defaultVal: 'Bengaluru'
    }
  },
  {
    fullName: 'Town__c', label: 'Town', type: 'Picklist',
    valueSet: {
      restricted: false,
      values: ['MG road', 'Indiranagar', 'Koramangala', 'Whitefield', 'Jayanagar', 'Bandra', 'Saket', 'CG Road'],
      defaultVal: 'MG road'
    }
  },
  {
    fullName: 'Municipality__c', label: 'Municipality', type: 'Picklist',
    valueSet: {
      restricted: false,
      values: ['Empty', 'BBMP - Bengaluru', 'BMC - Mumbai'],
      defaultVal: 'Empty'
    }
  },
  {
    fullName: 'Village__c', label: 'Village', type: 'Picklist',
    valueSet: {
      restricted: false,
      values: ['Empty', 'Village 1'],
      defaultVal: 'Empty'
    }
  },
  { fullName: 'Address__c', label: 'Address', type: 'TextArea' },
  { fullName: 'Pincode__c', label: 'Pincode', type: 'Text', length: 10 },
  {
    fullName: 'Status__c', label: 'Status', type: 'Picklist',
    valueSet: {
      restricted: true,
      values: ['Active', 'Inactive', 'Pending Verification'],
      defaultVal: 'Active'
    }
  }
];

outletFields.forEach(f => {
  fs.writeFileSync(path.join(outletFieldsDir, `${f.fullName}.field-meta.xml`), fieldXml(f), 'utf8');
});
console.log(`Created ${outletFields.length} fields for Outlet__c`);

// ==========================================
// 5. LIST VIEWS FOR ALL 4 OBJECTS
// ==========================================
function listViewXml(objName, columns) {
  let xml = `<?xml version="1.0" encoding="UTF-8"?>
<ListView xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>All</fullName>
    <filterScope>Everything</filterScope>
    <label>All ${objName.replace('__c', '')}s</label>
`;
  columns.forEach(col => {
    xml += `    <columns>${col}</columns>\n`;
  });
  xml += `</ListView>\n`;
  return xml;
}

// Employee List View
const empLvDir = path.join(empDir, 'listViews');
ensureDir(empLvDir);
fs.writeFileSync(path.join(empLvDir, 'All.listView-meta.xml'), listViewXml('Employee__c', [
  'NAME', 'Employee_Code__c', 'Hierarchy_Level__c', 'Reporting_Manager__c', 'Phone_Number__c', 'State__c', 'District__c', 'Town__c', 'Status__c'
]), 'utf8');

// PJP List View
const pjpLvDir = path.join(pjpDir, 'listViews');
ensureDir(pjpLvDir);
fs.writeFileSync(path.join(pjpLvDir, 'All.listView-meta.xml'), listViewXml('PJP__c', [
  'NAME', 'PJP_Code__c', 'Employee__c', 'Month__c', 'Year__c', 'Start_Date__c', 'End_Date__c', 'Status__c', 'Total_Beats__c', 'Total_Outlets__c', 'Reporting_Manager__c'
]), 'utf8');

// Beat List View
const beatLvDir = path.join(objectsDir, 'Beat__c', 'listViews');
ensureDir(beatLvDir);
fs.writeFileSync(path.join(beatLvDir, 'All.listView-meta.xml'), listViewXml('Beat__c', [
  'NAME', 'Beat_ID__c', 'Route_Date__c', 'PJP__c', 'Assigned_To__c', 'Distributor__c', 'Day_Of_Week__c', 'State__c', 'District__c', 'Town__c', 'Total_Outlets__c'
]), 'utf8');

// Outlet List View
const outletLvDir = path.join(outletDir, 'listViews');
ensureDir(outletLvDir);
fs.writeFileSync(path.join(outletLvDir, 'All.listView-meta.xml'), listViewXml('Outlet__c', [
  'NAME', 'Outlet_Code__c', 'Beat__c', 'Outlet_Owner_Name__c', 'Contact_No__c', 'Outlet_Type__c', 'State__c', 'District__c', 'Town__c', 'Status__c'
]), 'utf8');

console.log('List Views generated successfully!');
