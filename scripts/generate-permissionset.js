const fs = require('fs');
const path = require('path');

const permSetDir = path.join(__dirname, '..', 'force-app', 'main', 'default', 'permissionsets');
fs.mkdirSync(permSetDir, { recursive: true });

const objectsDir = path.join(__dirname, '..', 'force-app', 'main', 'default', 'objects');
const objectNames = fs.readdirSync(objectsDir).filter(f => f.endsWith('__c')).sort();

let classAccessesXml = '';
const apexClasses = ['DmsAdminRestService', 'OrderReservationRestService', 'PJPApprovalController', 'SfaMobileAuthService', 'SfaMobileSyncService', 'SyncBootstrapRestService'].sort();
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
const allObjectsWithFields = [...objectNames, 'Product2'].sort();
allObjectsWithFields.forEach(obj => {
  const fieldsDir = path.join(objectsDir, obj, 'fields');
  if (fs.existsSync(fieldsDir)) {
    const fieldFiles = fs.readdirSync(fieldsDir);
    fieldFiles.forEach(ff => {
      const fieldName = ff.replace('.field-meta.xml', '');
      const fieldContent = fs.readFileSync(path.join(fieldsDir, ff), 'utf8');
      
      const isFormula = fieldContent.includes('<formula>');
      const isMasterDetail = fieldContent.includes('<type>MasterDetail</type>');
      const isRequired = fieldContent.includes('<required>true</required>');
      // Note: In PermissionSets, required fields or master-detail fields cannot have explicit fieldPermissions in Salesforce metadata
      if (isRequired || isMasterDetail) return;

      const isEditable = !isFormula;

      fieldPermissionsList.push({
        field: `${obj}.${fieldName}`,
        editable: isEditable,
        readable: true
      });
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

let xml = `<?xml version="1.0" encoding="UTF-8"?>
<PermissionSet xmlns="http://soap.sforce.com/2006/04/metadata">
    <description>Full Administrator and Integration Access to SFA and DMS Objects and Services</description>
    <hasActivationRequired>false</hasActivationRequired>
    <label>SFA DMS Admin &amp; API Integration</label>
${classAccessesXml}${fieldPermissionsXml}${objectPermissionsXml}${tabSettingsXml}</PermissionSet>
`;

fs.writeFileSync(path.join(permSetDir, 'SFA_DMS_Admin.permissionset-meta.xml'), xml, 'utf8');
console.log('Permission Set SFA_DMS_Admin re-generated with all fields and objects.');
