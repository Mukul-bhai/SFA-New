const fs = require('fs');
const path = require('path');

const baseDir = path.join(__dirname, '..', '..', 'force-app', 'main', 'default');
const objectsDir = path.join(baseDir, 'objects');
const permSetPath = path.join(baseDir, 'permissionsets', 'SFA_DMS_Admin.permissionset-meta.xml');

// 1. Gather all custom objects
const allObjects = fs.readdirSync(objectsDir).filter(f => {
    return fs.statSync(path.join(objectsDir, f)).isDirectory() && f.endsWith('__c');
});

// 2. Gather all custom fields for all objects
const allFieldPermissions = [];

allObjects.forEach(obj => {
    const fieldsDir = path.join(objectsDir, obj, 'fields');
    if (fs.existsSync(fieldsDir)) {
        const fieldFiles = fs.readdirSync(fieldsDir).filter(f => f.endsWith('.field-meta.xml'));
        fieldFiles.forEach(ff => {
            const fieldName = ff.replace('.field-meta.xml', '');
            const fieldXml = fs.readFileSync(path.join(fieldsDir, ff), 'utf8');

            const isCalculated = fieldXml.includes('<formula>') || fieldXml.includes('<type>Formula</type>');
            const isAutoNumber = fieldXml.includes('<type>AutoNumber</type>');
            const isMasterDetail = fieldXml.includes('<type>MasterDetail</type>');
            const isRequired = fieldXml.includes('<required>true</required>');

            // In Salesforce Metadata API, MasterDetail and required fields cannot be in fieldPermissions AT ALL
            if (isRequired || isMasterDetail) {
                return;
            }

            const editable = (!isCalculated && !isAutoNumber);

            allFieldPermissions.push({
                field: `${obj}.${fieldName}`,
                editable: editable,
                readable: true
            });
        });
    }
});

// Standard objects custom fields
['Product2'].forEach(obj => {
    const fieldsDir = path.join(objectsDir, obj, 'fields');
    if (fs.existsSync(fieldsDir)) {
        const fieldFiles = fs.readdirSync(fieldsDir).filter(f => f.endsWith('.field-meta.xml'));
        fieldFiles.forEach(ff => {
            const fieldName = ff.replace('.field-meta.xml', '');
            const fieldXml = fs.readFileSync(path.join(fieldsDir, ff), 'utf8');
            if (fieldXml.includes('<required>true</required>') || fieldXml.includes('<type>MasterDetail</type>')) {
                return;
            }
            allFieldPermissions.push({
                field: `${obj}.${fieldName}`,
                editable: true,
                readable: true
            });
        });
    }
});

allFieldPermissions.sort((a, b) => a.field.localeCompare(b.field));

// 3. Object Permissions
const allObjectPermissions = allObjects.map(obj => ({
    object: obj,
    allowCreate: true,
    allowDelete: true,
    allowEdit: true,
    allowRead: true,
    modifyAllRecords: true,
    viewAllRecords: true
}));
allObjectPermissions.sort((a, b) => a.object.localeCompare(b.object));

// 4. Tab Settings
const tabsDir = path.join(baseDir, 'tabs');
const allTabs = fs.readdirSync(tabsDir)
    .filter(f => f.endsWith('.tab-meta.xml'))
    .map(f => f.replace('.tab-meta.xml', ''));

const allTabSettings = allTabs.map(t => ({
    tab: t,
    visibility: 'Visible'
}));
allTabSettings.sort((a, b) => a.tab.localeCompare(b.tab));

// 5. Classes
const classes = [
    'DmsAdminRestService',
    'OrderReservationRestService',
    'PJPApprovalController',
    'SFARollupService',
    'SfaMobileAuthService',
    'SfaMobileSyncService',
    'SyncBootstrapRestService'
];
classes.sort();

// Build PermissionSet XML
let xml = `<?xml version="1.0" encoding="UTF-8"?>\n<PermissionSet xmlns="http://soap.sforce.com/2006/04/metadata">\n`;
xml += `    <description>Full Administrator and Integration Access to SFA and DMS Objects and Services</description>\n`;
xml += `    <hasActivationRequired>false</hasActivationRequired>\n`;
xml += `    <label>SFA DMS Admin &amp; API Integration</label>\n`;

classes.forEach(cls => {
    xml += `    <classAccesses>\n        <apexClass>${cls}</apexClass>\n        <enabled>true</enabled>\n    </classAccesses>\n`;
});

allFieldPermissions.forEach(fp => {
    xml += `    <fieldPermissions>\n        <editable>${fp.editable}</editable>\n        <field>${fp.field}</field>\n        <readable>${fp.readable}</readable>\n    </fieldPermissions>\n`;
});

allObjectPermissions.forEach(op => {
    xml += `    <objectPermissions>\n        <allowCreate>${op.allowCreate}</allowCreate>\n        <allowDelete>${op.allowDelete}</allowDelete>\n        <allowEdit>${op.allowEdit}</allowEdit>\n        <allowRead>${op.allowRead}</allowRead>\n        <modifyAllRecords>${op.modifyAllRecords}</modifyAllRecords>\n        <object>${op.object}</object>\n        <viewAllRecords>${op.viewAllRecords}</viewAllRecords>\n    </objectPermissions>\n`;
});

allTabSettings.forEach(ts => {
    xml += `    <tabSettings>\n        <tab>${ts.tab}</tab>\n        <visibility>${ts.visibility}</visibility>\n    </tabSettings>\n`;
});

xml += `</PermissionSet>\n`;

fs.writeFileSync(permSetPath, xml, 'utf8');
console.log('Successfully regenerated SFA_DMS_Admin.permissionset-meta.xml with', allFieldPermissions.length, 'fields,', allObjectPermissions.length, 'objects,', allTabSettings.length, 'tabs.');
