const fs = require('fs');
const path = require('path');

const baseDir = path.join(__dirname, '..', '..', 'force-app', 'main', 'default');

function ensureDir(dir) {
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
    }
}

function writeXML(filePath, content) {
    ensureDir(path.dirname(filePath));
    fs.writeFileSync(filePath, content.trim() + '\n', 'utf8');
    console.log('Wrote:', path.relative(baseDir, filePath));
}

// 1. Helper to generate Custom Field XML
function createFieldXML(fieldDef) {
    let xml = `<?xml version="1.0" encoding="UTF-8"?>\n<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">\n`;
    xml += `    <fullName>${fieldDef.name}</fullName>\n`;
    xml += `    <label>${fieldDef.label}</label>\n`;
    xml += `    <type>${fieldDef.type}</type>\n`;

    if (fieldDef.required) {
        xml += `    <required>true</required>\n`;
    }
    if (fieldDef.length) {
        xml += `    <length>${fieldDef.length}</length>\n`;
    }
    if (fieldDef.precision !== undefined) {
        xml += `    <precision>${fieldDef.precision}</precision>\n`;
    }
    if (fieldDef.scale !== undefined) {
        xml += `    <scale>${fieldDef.scale}</scale>\n`;
    }
    if (fieldDef.defaultValue !== undefined) {
        xml += `    <defaultValue>${fieldDef.defaultValue}</defaultValue>\n`;
    }
    if (fieldDef.visibleLines !== undefined) {
        xml += `    <visibleLines>${fieldDef.visibleLines}</visibleLines>\n`;
    }
    if (fieldDef.referenceTo) {
        xml += `    <referenceTo>${fieldDef.referenceTo}</referenceTo>\n`;
        if (fieldDef.relationshipLabel) {
            xml += `    <relationshipLabel>${fieldDef.relationshipLabel}</relationshipLabel>\n`;
        }
        if (fieldDef.relationshipName) {
            xml += `    <relationshipName>${fieldDef.relationshipName}</relationshipName>\n`;
        }
        xml += `    <deleteConstraint>SetNull</deleteConstraint>\n`;
    }
    if (fieldDef.picklistValues) {
        xml += `    <valueSet>\n        <valueSetDefinition>\n            <sorted>false</sorted>\n`;
        fieldDef.picklistValues.forEach((val, idx) => {
            xml += `            <value>\n                <fullName>${val}</fullName>\n                <default>${idx === 0 && fieldDef.defaultFirst ? 'true' : 'false'}</default>\n                <label>${val}</label>\n            </value>\n`;
        });
        xml += `        </valueSetDefinition>\n    </valueSet>\n`;
    }
    xml += `</CustomField>`;
    return xml;
}

// 2. Helper to generate Custom Object XML
function createObjectXML(label, pluralLabel, nameFieldDef, description) {
    let xml = `<?xml version="1.0" encoding="UTF-8"?>\n<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">\n`;
    xml += `    <actionOverrides>\n        <actionName>Accept</actionName>\n        <type>Default</type>\n    </actionOverrides>\n`;
    xml += `    <actionOverrides>\n        <actionName>CancelEdit</actionName>\n        <type>Default</type>\n    </actionOverrides>\n`;
    xml += `    <actionOverrides>\n        <actionName>Clone</actionName>\n        <type>Default</type>\n    </actionOverrides>\n`;
    xml += `    <actionOverrides>\n        <actionName>Delete</actionName>\n        <type>Default</type>\n    </actionOverrides>\n`;
    xml += `    <actionOverrides>\n        <actionName>Edit</actionName>\n        <type>Default</type>\n    </actionOverrides>\n`;
    xml += `    <actionOverrides>\n        <actionName>List</actionName>\n        <type>Default</type>\n    </actionOverrides>\n`;
    xml += `    <actionOverrides>\n        <actionName>New</actionName>\n        <type>Default</type>\n    </actionOverrides>\n`;
    xml += `    <actionOverrides>\n        <actionName>SaveEdit</actionName>\n        <type>Default</type>\n    </actionOverrides>\n`;
    xml += `    <actionOverrides>\n        <actionName>Tab</actionName>\n        <type>Default</type>\n    </actionOverrides>\n`;
    xml += `    <actionOverrides>\n        <actionName>View</actionName>\n        <type>Default</type>\n    </actionOverrides>\n`;
    xml += `    <allowInChatterGroups>false</allowInChatterGroups>\n`;
    xml += `    <compactLayoutAssignment>SYSTEM</compactLayoutAssignment>\n`;
    xml += `    <deploymentStatus>Deployed</deploymentStatus>\n`;
    xml += `    <description>${description || label}</description>\n`;
    xml += `    <enableActivities>true</enableActivities>\n`;
    xml += `    <enableBulkApi>true</enableBulkApi>\n`;
    xml += `    <enableFeeds>false</enableFeeds>\n`;
    xml += `    <enableHistory>true</enableHistory>\n`;
    xml += `    <enableLicensing>false</enableLicensing>\n`;
    xml += `    <enableReports>true</enableReports>\n`;
    xml += `    <enableSearch>true</enableSearch>\n`;
    xml += `    <enableSharing>true</enableSharing>\n`;
    xml += `    <enableStreamingApi>true</enableStreamingApi>\n`;
    xml += `    <label>${label}</label>\n`;
    xml += `    <pluralLabel>${pluralLabel}</pluralLabel>\n`;
    xml += `    <nameField>\n`;
    if (nameFieldDef.type === 'AutoNumber') {
        xml += `        <displayFormat>${nameFieldDef.displayFormat}</displayFormat>\n`;
        xml += `        <label>${nameFieldDef.label}</label>\n`;
        xml += `        <type>AutoNumber</type>\n`;
    } else {
        xml += `        <label>${nameFieldDef.label}</label>\n`;
        xml += `        <type>Text</type>\n`;
    }
    xml += `    </nameField>\n`;
    xml += `    <sharingModel>ReadWrite</sharingModel>\n`;
    xml += `    <visibility>Public</visibility>\n`;
    xml += `</CustomObject>`;
    return xml;
}

// 3. Helper to generate Custom Tab XML
function createTabXML(label, motif, description) {
    return `<?xml version="1.0" encoding="UTF-8"?>\n<CustomTab xmlns="http://soap.sforce.com/2006/04/metadata">\n    <customObject>true</customObject>\n    <description>${description || label}</description>\n    <motif>${motif || 'Custom13: Box'}</motif>\n</CustomTab>`;
}

// DEFINITIONS OF OBJECTS AND FIELDS
const objects = [
    {
        objName: 'Product__c',
        label: 'Product',
        pluralLabel: 'Products',
        description: 'SFA Product Master for FMCG products, biscuits, packages and pricing',
        motif: 'Custom13: Box',
        nameField: { label: 'Product Name', type: 'Text' },
        fields: [
            { name: 'Product_Code__c', label: 'Product Code', type: 'Text', length: 50 },
            { name: 'SKU__c', label: 'SKU', type: 'Text', length: 50 },
            { name: 'Quantity__c', label: 'Quantity', type: 'Number', precision: 10, scale: 0, defaultValue: 0 },
            { name: 'MRP__c', label: 'Product price(MRP)', type: 'Currency', precision: 10, scale: 2 },
            { name: 'RBP__c', label: 'Product price(RBP)', type: 'Currency', precision: 10, scale: 2 },
            { name: 'Available_Stock__c', label: 'Available Stock', type: 'Number', precision: 10, scale: 0, defaultValue: 0 },
            { name: 'Manufacturing_Date__c', label: 'Manufacturing Date', type: 'Date' },
            { name: 'Expiry_Date__c', label: 'Expiry Date', type: 'Date' },
            { name: 'Flavour__c', label: 'Flavour', type: 'Picklist', picklistValues: ['Glucose', 'Salty', 'Sweet & Salty', 'Chocolate', 'Bourbon', 'Butter', 'Elaichi', 'Vanilla', 'Cashew Butter'] },
            { name: 'Variant__c', label: 'Variant', type: 'Picklist', picklistValues: ['50g', '100g', '120g', '150g', '200g', '250g', '500g', 'Family Pack', 'Box 50pcs'] },
            { name: 'Batch_No__c', label: 'Batch No', type: 'Text', length: 50 },
            { name: 'Product_Image__c', label: 'Product Image', type: 'Url' },
            { name: 'Package_Type__c', label: 'Package Type', type: 'Picklist', picklistValues: ['Box', 'Packet', 'Cover', 'Case', 'Tin'] },
            { name: 'Unit_Conversion__c', label: 'Unit Conversion', type: 'Number', precision: 6, scale: 0, defaultValue: 10 },
            { name: 'Brand__c', label: 'Brand', type: 'Picklist', picklistValues: ['Parle', 'Britannia', 'Sunfeast', 'ITC', 'Cadbury', 'Mayora'] },
            { name: 'Sub_Brand__c', label: 'Sub Brand', type: 'Picklist', picklistValues: ['Parle-G', 'Monaco', 'Krackjack', 'Hide & Seek', 'Good Day', 'Bourbon', 'Marie Gold', '20-20', 'Kopiko'] },
            { name: 'Brand_Alias__c', label: 'Brand Alias', type: 'Text', length: 100 },
            { name: 'GST_Percentage__c', label: 'GST %', type: 'Percent', precision: 5, scale: 2, defaultValue: 18.00 },
            { name: 'Category__c', label: 'Category', type: 'Picklist', picklistValues: ['Biscuits', 'Confectionery', 'Snacks', 'Chocolates', 'Beverages'] },
            { name: 'Is_Active__c', label: 'Active', type: 'Checkbox', defaultValue: true }
        ]
    },
    {
        objName: 'Asset_Survey__c',
        label: 'Asset Survey',
        pluralLabel: 'Asset Surveys',
        description: 'Store display assets and equipment audit during outlet visits',
        motif: 'Custom19: Wrench',
        nameField: { label: 'Survey ID', type: 'AutoNumber', displayFormat: 'AST-{00000}' },
        fields: [
            { name: 'Outlet__c', label: 'Outlet Name', type: 'Lookup', referenceTo: 'Outlet__c', relationshipLabel: 'Asset Surveys', relationshipName: 'Asset_Surveys' },
            { name: 'Visit__c', label: 'Store Visit', type: 'Lookup', referenceTo: 'Visit__c', relationshipLabel: 'Asset Surveys', relationshipName: 'Asset_Surveys' },
            { name: 'Asset_Name__c', label: 'Asset Name', type: 'Text', length: 100, required: true },
            { name: 'Asset_Code__c', label: 'Asset Code', type: 'Text', length: 50 },
            { name: 'Status__c', label: 'Status', type: 'Picklist', picklistValues: ['Working / Good', 'Damaged', 'Needs Repair', 'Missing', 'Replaced'], defaultFirst: true },
            { name: 'Picture__c', label: 'Picture', type: 'Url' },
            { name: 'Given_Date__c', label: 'Given Date', type: 'Date' },
            { name: 'Survey_Date__c', label: 'Survey Date', type: 'Date' },
            { name: 'Remarks__c', label: 'Remarks', type: 'LongTextArea', length: 1000, visibleLines: 3 }
        ]
    },
    {
        objName: 'Competitor_Activity__c',
        label: 'Competitor Activity',
        pluralLabel: 'Competitor Activities',
        description: 'Capturing competitor brands, pricing, and schemes in retail outlets',
        motif: 'Custom68: Globe',
        nameField: { label: 'Activity ID', type: 'AutoNumber', displayFormat: 'CMP-{00000}' },
        fields: [
            { name: 'Outlet__c', label: 'Outlet Name', type: 'Lookup', referenceTo: 'Outlet__c', relationshipLabel: 'Competitor Activities', relationshipName: 'Competitor_Activities' },
            { name: 'Visit__c', label: 'Store Visit', type: 'Lookup', referenceTo: 'Visit__c', relationshipLabel: 'Competitor Activities', relationshipName: 'Competitor_Activities' },
            { name: 'Competitor_Name__c', label: 'Competitor Name', type: 'Text', length: 100, required: true },
            { name: 'Company__c', label: 'Company', type: 'Text', length: 100 },
            { name: 'MRP__c', label: 'MRP', type: 'Currency', precision: 10, scale: 2 },
            { name: 'RBP__c', label: 'RBP', type: 'Currency', precision: 10, scale: 2 },
            { name: 'Schemes__c', label: 'Schemes (Any)', type: 'LongTextArea', length: 1000, visibleLines: 3 },
            { name: 'Image__c', label: 'Image', type: 'Url' },
            { name: 'Capture_Date__c', label: 'Capture Date', type: 'Date' },
            { name: 'Category__c', label: 'Category', type: 'Picklist', picklistValues: ['Biscuits', 'Cookies', 'Wafers', 'Chocolates', 'Snacks'] },
            { name: 'Remarks__c', label: 'Remarks', type: 'LongTextArea', length: 1000, visibleLines: 3 }
        ]
    },
    {
        objName: 'Stock_Check__c',
        label: 'Stock Check',
        pluralLabel: 'Stock Checks',
        description: 'In-store stock audit and shelf inventory verification',
        motif: 'Custom32: Factory',
        nameField: { label: 'Stock Check ID', type: 'AutoNumber', displayFormat: 'STK-{00000}' },
        fields: [
            { name: 'Outlet__c', label: 'Outlet Name', type: 'Lookup', referenceTo: 'Outlet__c', relationshipLabel: 'Stock Checks', relationshipName: 'Stock_Checks' },
            { name: 'Visit__c', label: 'Store Visit', type: 'Lookup', referenceTo: 'Visit__c', relationshipLabel: 'Stock Checks', relationshipName: 'Stock_Checks' },
            { name: 'Product__c', label: 'Product Name', type: 'Lookup', referenceTo: 'Product__c', relationshipLabel: 'Stock Checks', relationshipName: 'Stock_Checks' },
            { name: 'Quantity__c', label: 'How Many Qty', type: 'Number', precision: 8, scale: 0, defaultValue: 0 },
            { name: 'Manufacturing_Date__c', label: 'Manufacturing Date', type: 'Date' },
            { name: 'Expiry_Date__c', label: 'Expiry Date', type: 'Date' },
            { name: 'Batch_No__c', label: 'Batch No', type: 'Text', length: 50 },
            { name: 'Check_Date__c', label: 'Check Date', type: 'Date' },
            { name: 'Stock_Condition__c', label: 'Stock Condition', type: 'Picklist', picklistValues: ['Good Stock', 'Low Stock', 'Out of Stock', 'Near Expiry', 'Damaged'], defaultFirst: true },
            { name: 'Remarks__c', label: 'Remarks', type: 'Text', length: 255 }
        ]
    },
    {
        objName: 'Ticket__c',
        label: 'Ticket',
        pluralLabel: 'Tickets',
        description: 'Customer and outlet issue ticketing system',
        motif: 'Custom53: Bell',
        nameField: { label: 'Ticket Num (Auto Generated)', type: 'AutoNumber', displayFormat: 'TCK-{00000}' },
        fields: [
            { name: 'Outlet__c', label: 'Outlet Name', type: 'Lookup', referenceTo: 'Outlet__c', relationshipLabel: 'Tickets', relationshipName: 'Tickets' },
            { name: 'Visit__c', label: 'Store Visit', type: 'Lookup', referenceTo: 'Visit__c', relationshipLabel: 'Tickets', relationshipName: 'Tickets' },
            { name: 'Subject__c', label: 'Ticket Subject', type: 'Text', length: 255, required: true },
            { name: 'Description__c', label: 'Description', type: 'LongTextArea', length: 2000, visibleLines: 4 },
            { name: 'Image__c', label: 'Image', type: 'Url' },
            { name: 'Status__c', label: 'Status', type: 'Picklist', picklistValues: ['Open', 'In Progress', 'Pending Distributor', 'Resolved', 'Closed'], defaultFirst: true },
            { name: 'Priority__c', label: 'Priority', type: 'Picklist', picklistValues: ['Low', 'Medium', 'High', 'Urgent'], defaultFirst: true },
            { name: 'Category__c', label: 'Category', type: 'Picklist', picklistValues: ['Product Quality', 'Delayed Delivery', 'Scheme Dispute', 'Damaged Stock', 'Display Asset', 'Billing Issue', 'Other'] },
            { name: 'Assigned_To__c', label: 'Assigned To', type: 'Lookup', referenceTo: 'User', relationshipLabel: 'Assigned Tickets', relationshipName: 'Assigned_Tickets' },
            { name: 'Resolution_Notes__c', label: 'Resolution Notes', type: 'LongTextArea', length: 1000, visibleLines: 3 }
        ]
    },
    {
        objName: 'Product_Return__c',
        label: 'Product Return',
        pluralLabel: 'Product Returns',
        description: 'Damaged and expired stock returns from retail outlets',
        motif: 'Custom61: Castle',
        nameField: { label: 'Return ID', type: 'AutoNumber', displayFormat: 'RET-{00000}' },
        fields: [
            { name: 'Outlet__c', label: 'Outlet Name', type: 'Lookup', referenceTo: 'Outlet__c', relationshipLabel: 'Product Returns', relationshipName: 'Product_Returns' },
            { name: 'Visit__c', label: 'Store Visit', type: 'Lookup', referenceTo: 'Visit__c', relationshipLabel: 'Product Returns', relationshipName: 'Product_Returns' },
            { name: 'Product__c', label: 'Product Name', type: 'Lookup', referenceTo: 'Product__c', relationshipLabel: 'Product Returns', relationshipName: 'Product_Returns' },
            { name: 'Quantity__c', label: 'How Many Qty', type: 'Number', precision: 8, scale: 0, defaultValue: 0 },
            { name: 'Manufacturing_Date__c', label: 'Manufacturing Date', type: 'Date' },
            { name: 'Batch_No__c', label: 'Batch No', type: 'Text', length: 50 },
            { name: 'Return_Reason__c', label: 'Return Reason', type: 'Picklist', picklistValues: ['Expired', 'Damaged', 'Near Expiry', 'Defective Packaging', 'Wrong Delivery', 'Overstock', 'Customer Return'], defaultFirst: true },
            { name: 'Status__c', label: 'Status', type: 'Picklist', picklistValues: ['Requested', 'Approved', 'Picked Up', 'Credited', 'Rejected'], defaultFirst: true },
            { name: 'Return_Date__c', label: 'Return Date', type: 'Date' },
            { name: 'Credit_Amount__c', label: 'Credit Amount', type: 'Currency', precision: 10, scale: 2 },
            { name: 'Remarks__c', label: 'Remarks', type: 'LongTextArea', length: 1000, visibleLines: 3 }
        ]
    }
];

// Additional fields for Scheme__c
const schemeAdditionalFields = [
    { name: 'Primary_Product__c', label: 'Primary Product', type: 'Lookup', referenceTo: 'Product__c', relationshipLabel: 'Schemes (Primary)', relationshipName: 'Primary_Schemes' },
    { name: 'Free_Product_Custom__c', label: 'Free Product', type: 'Lookup', referenceTo: 'Product__c', relationshipLabel: 'Schemes (Free)', relationshipName: 'Free_Schemes' },
    { name: 'Duration_Days__c', label: 'Duration (Days)', type: 'Number', precision: 4, scale: 0 },
    { name: 'Region__c', label: 'Region', type: 'Picklist', picklistValues: ['All India', 'North', 'South', 'East', 'West', 'Karnataka', 'Maharashtra', 'Delhi NCR', 'Tamil Nadu'], defaultFirst: true },
    { name: 'Outlet_Type__c', label: 'Outlet Type', type: 'Picklist', picklistValues: ['All Types', 'Kirana', 'Supermarket', 'General Store', 'Wholesaler', 'Bakery', 'Medical Store'], defaultFirst: true },
    { name: 'Bundle_Price__c', label: 'Bundle Price', type: 'Currency', precision: 10, scale: 2 },
    { name: 'Discount_Amount__c', label: 'Discount Amount', type: 'Currency', precision: 10, scale: 2 }
];

// Additional fields for Attendance__c
const attendanceAdditionalFields = [
    { name: 'Employee__c', label: 'Employee', type: 'Lookup', referenceTo: 'Employee__c', relationshipLabel: 'Attendances', relationshipName: 'Attendances' },
    { name: 'User__c', label: 'User', type: 'Lookup', referenceTo: 'User', relationshipLabel: 'Attendances', relationshipName: 'Attendances' },
    { name: 'Attendance_Date__c', label: 'Attendance Date', type: 'Date' },
    { name: 'Start_Time__c', label: 'Start Time', type: 'DateTime' },
    { name: 'End_Time__c', label: 'End Time', type: 'DateTime' },
    { name: 'Geo_Location__c', label: 'Geo Location', type: 'Text', length: 100 },
    { name: 'Total_Working_Hours__c', label: 'Total Working Hours', type: 'Number', precision: 4, scale: 2 },
    { name: 'Attendance_Status__c', label: 'Attendance Status', type: 'Picklist', picklistValues: ['Present', 'Absent', 'Half Day', 'On Leave', 'Holiday', 'Week Off'], defaultFirst: true },
    { name: 'Is_Leave__c', label: 'Is Leave', type: 'Checkbox', defaultValue: false },
    { name: 'Leave_Date__c', label: 'Leave Date', type: 'Date' },
    { name: 'Leave_Type__c', label: 'Leave Type', type: 'Picklist', picklistValues: ['Casual Leave', 'Sick Leave', 'Earned Leave', 'Maternity/Paternity Leave', 'Emergency Leave', 'Compensatory Off'] },
    { name: 'Leave_Status__c', label: 'Leave Status', type: 'Picklist', picklistValues: ['Pending', 'Approved', 'Rejected', 'Hold'], defaultFirst: true },
    { name: 'Approver__c', label: 'Approver Name', type: 'Lookup', referenceTo: 'User', relationshipLabel: 'Approved Attendances', relationshipName: 'Approved_Attendances' },
    { name: 'Leave_Reason__c', label: 'Leave Reason', type: 'LongTextArea', length: 1000, visibleLines: 3 }
];

// Additional fields for Order__c & Order_Line__c
const orderAdditionalFields = [
    { name: 'Outlet__c', label: 'Outlet Name', type: 'Lookup', referenceTo: 'Outlet__c', relationshipLabel: 'Orders', relationshipName: 'Orders' },
    { name: 'Visit__c', label: 'Store Visit', type: 'Lookup', referenceTo: 'Visit__c', relationshipLabel: 'Orders', relationshipName: 'Orders' },
    { name: 'Applied_Scheme__c', label: 'Schemes (Any)', type: 'Lookup', referenceTo: 'Scheme__c', relationshipLabel: 'Orders', relationshipName: 'Orders' },
    { name: 'Schemes_Applied__c', label: 'Schemes Applied', type: 'Text', length: 255 },
    { name: 'Total_Quantity__c', label: 'Total Qty', type: 'Number', precision: 10, scale: 0, defaultValue: 0 },
    { name: 'Gross_Amount__c', label: 'Gross Amount', type: 'Currency', precision: 12, scale: 2 },
    { name: 'Tax_Amount__c', label: 'Tax Amount', type: 'Currency', precision: 12, scale: 2 },
    { name: 'Total_Amount__c', label: 'Total Amount', type: 'Currency', precision: 12, scale: 2 }
];

const orderLineAdditionalFields = [
    { name: 'Product_Custom__c', label: 'Product Name', type: 'Lookup', referenceTo: 'Product__c', relationshipLabel: 'Order Lines', relationshipName: 'Order_Lines' },
    { name: 'SKU__c', label: 'SKU', type: 'Text', length: 50 },
    { name: 'Gross_Amount__c', label: 'Gross Amount', type: 'Currency', precision: 12, scale: 2 },
    { name: 'Tax_Amount__c', label: 'Tax Amount', type: 'Currency', precision: 12, scale: 2 },
    { name: 'Scheme_Custom__c', label: 'Scheme Applied', type: 'Lookup', referenceTo: 'Scheme__c', relationshipLabel: 'Order Lines', relationshipName: 'Order_Lines' }
];

// GENERATE EVERYTHING
console.log('--- GENERATING SFA OBJECTS & FIELDS ---');

// 1. Create New Objects
objects.forEach(obj => {
    const objDir = path.join(baseDir, 'objects', obj.objName);
    writeXML(path.join(objDir, `${obj.objName}.object-meta.xml`), createObjectXML(obj.label, obj.pluralLabel, obj.nameField, obj.description));
    
    // Tab
    writeXML(path.join(baseDir, 'tabs', `${obj.objName}.tab-meta.xml`), createTabXML(obj.label, obj.motif, obj.description));

    // Fields
    obj.fields.forEach(f => {
        writeXML(path.join(objDir, 'fields', `${f.name}.field-meta.xml`), createFieldXML(f));
    });
});

// 2. Add Scheme Additional Fields
schemeAdditionalFields.forEach(f => {
    writeXML(path.join(baseDir, 'objects', 'Scheme__c', 'fields', `${f.name}.field-meta.xml`), createFieldXML(f));
});

// 3. Add Attendance Additional Fields
attendanceAdditionalFields.forEach(f => {
    writeXML(path.join(baseDir, 'objects', 'Attendance__c', 'fields', `${f.name}.field-meta.xml`), createFieldXML(f));
});

// 4. Add Order Additional Fields
orderAdditionalFields.forEach(f => {
    writeXML(path.join(baseDir, 'objects', 'Order__c', 'fields', `${f.name}.field-meta.xml`), createFieldXML(f));
});

// 5. Add Order_Line Additional Fields
orderLineAdditionalFields.forEach(f => {
    writeXML(path.join(baseDir, 'objects', 'Order_Line__c', 'fields', `${f.name}.field-meta.xml`), createFieldXML(f));
});

console.log('--- ALL OBJECTS & FIELDS GENERATED SUCCESSFULLY ---');
