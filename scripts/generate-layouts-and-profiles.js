const fs = require('fs');
const path = require('path');

const objectsDir = path.resolve(__dirname, '../force-app/main/default/objects');
const layoutsDir = path.resolve(__dirname, '../force-app/main/default/layouts');
const profilesDir = path.resolve(__dirname, '../force-app/main/default/profiles');

if (!fs.existsSync(layoutsDir)) fs.mkdirSync(layoutsDir, { recursive: true });
if (!fs.existsSync(profilesDir)) fs.mkdirSync(profilesDir, { recursive: true });

const customObjects = fs.readdirSync(objectsDir).filter(f => f.endsWith('__c')).sort();
const allObjects = [...customObjects, 'Product2'];

// 1. First pass: Build child relationships map for relatedLists
const relatedListsMap = {};

for (const childObj of allObjects) {
  const fieldsDir = path.join(objectsDir, childObj, 'fields');
  if (!fs.existsSync(fieldsDir)) continue;

  const fieldFiles = fs.readdirSync(fieldsDir).filter(f => f.endsWith('.field-meta.xml'));
  for (const f of fieldFiles) {
    const fieldName = f.replace('.field-meta.xml', '');
    const content = fs.readFileSync(path.join(fieldsDir, f), 'utf8');

    const refMatch = content.match(/<referenceTo>(.*?)<\/referenceTo>/);
    if (refMatch) {
      const parentObj = refMatch[1].trim();
      if (!relatedListsMap[parentObj]) {
        relatedListsMap[parentObj] = [];
      }
      relatedListsMap[parentObj].push(`${childObj}.${fieldName}`);
    }
  }
}

console.log('Discovered relationships for Related Lists:');
for (const p in relatedListsMap) {
  console.log(`- ${p} has ${relatedListsMap[p].length} related lists`);
}

// 2. Generate Layouts for all custom objects
const layoutAssignments = [];

// Include Product2 Layout
layoutAssignments.push(`    <layoutAssignments>
        <layout>Product2-Product Layout</layout>
    </layoutAssignments>`);

for (const obj of customObjects) {
  const fieldsDir = path.join(objectsDir, obj, 'fields');
  let fieldFiles = [];
  if (fs.existsSync(fieldsDir)) {
    fieldFiles = fs.readdirSync(fieldsDir).filter(f => f.endsWith('.field-meta.xml'));
  }

  let hasMasterDetail = false;
  const customFields = [];
  for (const f of fieldFiles) {
    const fieldName = f.replace('.field-meta.xml', '');
    const content = fs.readFileSync(path.join(fieldsDir, f), 'utf8');
    const isRequired = content.includes('<required>true</required>');
    const isFormula = content.includes('<formula>');
    const isMasterDetail = content.includes('<type>MasterDetail</type>');
    if (isMasterDetail) hasMasterDetail = true;
    customFields.push({
      name: fieldName,
      required: isRequired || isMasterDetail,
      readonly: isFormula
    });
  }

  // Split fields into Left and Right columns
  const leftCol = [];
  const rightCol = [];

  // Always put Name on left
  leftCol.push(`            <layoutItems>
                <behavior>Required</behavior>
                <field>Name</field>
            </layoutItems>`);

  // Child objects in Master-Detail relationships do not have an OwnerId field
  if (!hasMasterDetail) {
    rightCol.push(`            <layoutItems>
                <behavior>Edit</behavior>
                <field>OwnerId</field>
            </layoutItems>`);
  }

  customFields.forEach((cf, idx) => {
    let behavior = 'Edit';
    if (cf.required) behavior = 'Required';
    else if (cf.readonly) behavior = 'Readonly';

    const itemXml = `            <layoutItems>
                <behavior>${behavior}</behavior>
                <field>${cf.name}</field>
            </layoutItems>`;

    if (idx % 2 === 0) {
      leftCol.push(itemXml);
    } else {
      rightCol.push(itemXml);
    }
  });

  // Build related lists XML
  const childRelList = relatedListsMap[obj] || [];
  let relatedListsXml = '';
  if (childRelList.length > 0) {
    relatedListsXml = childRelList.map(rl => `    <relatedLists>
        <fields>NAME</fields>
        <relatedList>${rl}</relatedList>
    </relatedLists>`).join('\n') + '\n';
  }

  const layoutLabel = obj.replace('__c', '').replace(/_/g, ' ') + ' Layout';
  const layoutFileName = `${obj}-${layoutLabel}.layout-meta.xml`;
  const layoutFilePath = path.join(layoutsDir, layoutFileName);

  const layoutXml = `<?xml version="1.0" encoding="UTF-8"?>
<Layout xmlns="http://soap.sforce.com/2006/04/metadata">
    <excludeButtons>Submit</excludeButtons>
    <layoutSections>
        <customLabel>false</customLabel>
        <detailHeading>false</detailHeading>
        <editHeading>true</editHeading>
        <label>Information</label>
        <layoutColumns>
${leftCol.join('\n')}
        </layoutColumns>
        <layoutColumns>
${rightCol.join('\n')}
        </layoutColumns>
        <style>TwoColumnsTopToBottom</style>
    </layoutSections>
    <layoutSections>
        <customLabel>false</customLabel>
        <detailHeading>true</detailHeading>
        <editHeading>true</editHeading>
        <label>System Information</label>
        <layoutColumns>
            <layoutItems>
                <behavior>Readonly</behavior>
                <field>CreatedById</field>
            </layoutItems>
        </layoutColumns>
        <layoutColumns>
            <layoutItems>
                <behavior>Readonly</behavior>
                <field>LastModifiedById</field>
            </layoutItems>
        </layoutColumns>
        <style>TwoColumnsTopToBottom</style>
    </layoutSections>
    <layoutSections>
        <customLabel>true</customLabel>
        <detailHeading>false</detailHeading>
        <editHeading>true</editHeading>
        <label>Custom Links</label>
        <layoutColumns/>
        <layoutColumns/>
        <layoutColumns/>
        <style>CustomLinks</style>
    </layoutSections>
${relatedListsXml}</Layout>
`;

  fs.writeFileSync(layoutFilePath, layoutXml, 'utf8');
  console.log(`Generated Layout with Related Lists: ${layoutFileName}`);

  layoutAssignments.push(`    <layoutAssignments>
        <layout>${obj}-${layoutLabel}</layout>
    </layoutAssignments>`);
}

// 3. Update Product2 Layout with Related Lists as well
const product2LayoutPath = path.join(layoutsDir, 'Product2-Product Layout.layout-meta.xml');
if (fs.existsSync(product2LayoutPath)) {
  const p2Related = relatedListsMap['Product2'] || [];
  const p2CustomRelatedXml = p2Related.map(rl => `    <relatedLists>
        <fields>NAME</fields>
        <relatedList>${rl}</relatedList>
    </relatedLists>`).join('\n');
  
  let p2Content = fs.readFileSync(product2LayoutPath, 'utf8');
  // Inject before standard price lists
  if (!p2Content.includes('Inventory__c.Product__c')) {
    p2Content = p2Content.replace('<relatedLists>\n        <relatedList>RelatedStandardPriceList', p2CustomRelatedXml + '\n    <relatedLists>\n        <relatedList>RelatedStandardPriceList');
    fs.writeFileSync(product2LayoutPath, p2Content, 'utf8');
    console.log('Updated Product2 Layout with custom related lists.');
  }
}

// 4. Generate Admin Profile with Layout Assignments and Application Visibility
const adminProfileXml = `<?xml version="1.0" encoding="UTF-8"?>
<Profile xmlns="http://soap.sforce.com/2006/04/metadata">
    <applicationVisibilities>
        <application>Enterprise_SFA_DMS</application>
        <default>true</default>
        <visible>true</visible>
    </applicationVisibilities>
    <custom>false</custom>
    <userLicense>Salesforce</userLicense>
${layoutAssignments.join('\n')}
</Profile>
`;

fs.writeFileSync(path.join(profilesDir, 'Admin.profile-meta.xml'), adminProfileXml, 'utf8');
console.log(`Generated Admin.profile-meta.xml with ${layoutAssignments.length} layout assignments!`);
