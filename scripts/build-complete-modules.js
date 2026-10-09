const fs = require('fs');
const path = require('path');

const baseDir = path.resolve(__dirname, '../force-app/main/default');
const objectsDir = path.join(baseDir, 'objects');
const tabsDir = path.join(baseDir, 'tabs');
const layoutsDir = path.join(baseDir, 'layouts');
const listViewsDir = (obj) => path.join(objectsDir, obj, 'listViews');
const profilesDir = path.join(baseDir, 'profiles');
const permSetDir = path.join(baseDir, 'permissionsets');
const appFile = path.join(baseDir, 'applications', 'Enterprise_SFA_DMS.app-meta.xml');

// Helper to make dir
function ensureDir(p) {
  if (!fs.existsSync(p)) fs.mkdirSync(p, { recursive: true });
}

// 1. New Custom Objects Definitions
const newObjects = [
  {
    name: 'Scheme__c',
    label: 'Scheme',
    pluralLabel: 'Schemes',
    description: 'Trade promotion schemes (Buy X Get Y, Slab discount, Cash discount)',
    sharingModel: 'ReadWrite',
    tabMotif: 'Custom63: Chip',
    fields: [
      { name: 'Scheme_Code__c', label: 'Scheme Code', type: 'Text', length: 30, unique: true, externalId: true, required: true },
      { name: 'Scheme_Type__c', label: 'Scheme Type', type: 'Picklist', values: ['Buy_X_Get_Y', 'Slab_Discount', 'Flat_Discount', 'Cash_Discount'], defaultValue: 'Buy_X_Get_Y' },
      { name: 'Status__c', label: 'Status', type: 'Picklist', values: ['Draft', 'Active', 'Suspended', 'Expired'], defaultValue: 'Active' },
      { name: 'Start_Date__c', label: 'Start Date', type: 'Date' },
      { name: 'End_Date__c', label: 'End Date', type: 'Date' },
      { name: 'Applicable_Brand__c', label: 'Applicable Brand', type: 'Text', length: 50 },
      { name: 'Applicable_Category__c', label: 'Applicable Category', type: 'Text', length: 50 },
      { name: 'Applicable_Product__c', label: 'Applicable Product', type: 'Lookup', referenceTo: 'Product2', relationshipName: 'Schemes_Applicable' },
      { name: 'Free_Product__c', label: 'Free Product', type: 'Lookup', referenceTo: 'Product2', relationshipName: 'Schemes_Free' },
      { name: 'Buy_Quantity__c', label: 'Buy Quantity', type: 'Number', precision: 10, scale: 0 },
      { name: 'Get_Quantity__c', label: 'Get Quantity', type: 'Number', precision: 10, scale: 0 },
      { name: 'Discount_Percentage__c', label: 'Discount Percentage (%)', type: 'Percent', precision: 5, scale: 2 },
      { name: 'Minimum_Order_Value__c', label: 'Minimum Order Value', type: 'Currency', precision: 16, scale: 2 },
      { name: 'Description__c', label: 'Description', type: 'LongTextArea', length: 32768, visibleLines: 3 }
    ]
  },
  {
    name: 'Scheme_Slab__c',
    label: 'Scheme Slab',
    pluralLabel: 'Scheme Slabs',
    description: 'Quantity tiers for volume discounts under a scheme',
    sharingModel: 'ControlledByParent',
    fields: [
      { name: 'Scheme__c', label: 'Scheme', type: 'MasterDetail', referenceTo: 'Scheme__c', relationshipName: 'Scheme_Slabs', writeRequiresMasterRead: false },
      { name: 'Min_Quantity__c', label: 'Min Quantity', type: 'Number', precision: 10, scale: 0, required: true },
      { name: 'Max_Quantity__c', label: 'Max Quantity', type: 'Number', precision: 10, scale: 0 },
      { name: 'Discount_Percentage__c', label: 'Discount Percentage (%)', type: 'Percent', precision: 5, scale: 2 },
      { name: 'Free_Quantity__c', label: 'Free Quantity', type: 'Number', precision: 10, scale: 0 }
    ]
  },
  {
    name: 'Target__c',
    label: 'Target',
    pluralLabel: 'Targets',
    description: 'Sales targets partitioned into Monthly, Day-wise, and Outlet Type',
    sharingModel: 'ReadWrite',
    tabMotif: 'Custom43: Jewel',
    fields: [
      { name: 'Sales_Executive__c', label: 'Sales Executive', type: 'Lookup', referenceTo: 'User', relationshipName: 'Sales_Targets' },
      { name: 'Territory__c', label: 'Territory', type: 'Lookup', referenceTo: 'Territory__c', relationshipName: 'Territory_Targets' },
      { name: 'Target_Type__c', label: 'Target Type', type: 'Picklist', values: ['Monthly', 'Day_Wise', 'Outlet_Type'], defaultValue: 'Monthly', required: true },
      { name: 'Month__c', label: 'Month', type: 'Picklist', values: ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'] },
      { name: 'Year__c', label: 'Year', type: 'Text', length: 4 },
      { name: 'Target_Date__c', label: 'Target Date (Day-wise)', type: 'Date' },
      { name: 'Outlet_Category__c', label: 'Outlet Category', type: 'Picklist', values: ['Kirana', 'Supermarket', 'Wholesaler', 'Chemist', 'Hypermarket', 'General_Store'] },
      { name: 'Target_Revenue__c', label: 'Target Revenue', type: 'Currency', precision: 16, scale: 2, defaultValue: '0' },
      { name: 'Achieved_Revenue__c', label: 'Achieved Revenue', type: 'Currency', precision: 16, scale: 2, defaultValue: '0' },
      { name: 'Target_Volume_Units__c', label: 'Target Volume (Units)', type: 'Number', precision: 10, scale: 0, defaultValue: '0' },
      { name: 'Achieved_Volume_Units__c', label: 'Achieved Volume (Units)', type: 'Number', precision: 10, scale: 0, defaultValue: '0' },
      { name: 'Target_Visits_Count__c', label: 'Target Visits Count', type: 'Number', precision: 6, scale: 0, defaultValue: '0' },
      { name: 'Achieved_Visits_Count__c', label: 'Achieved Visits Count', type: 'Number', precision: 6, scale: 0, defaultValue: '0' },
      {
        name: 'Achievement_Percentage__c',
        label: 'Achievement %',
        type: 'Formula',
        formula: 'IF(Target_Revenue__c > 0, (Achieved_Revenue__c / Target_Revenue__c) * 100, 0)',
        formulaTreatBlanksAs: 'BlankAsZero',
        precision: 5,
        scale: 2
      }
    ]
  },
  {
    name: 'Expense_Claim__c',
    label: 'Expense Claim',
    pluralLabel: 'Expense Claims',
    description: 'TA/DA daily and travel allowance claims with full day and half day options',
    sharingModel: 'ReadWrite',
    tabMotif: 'Custom14: Hands',
    fields: [
      { name: 'Sales_Executive__c', label: 'Sales Executive', type: 'Lookup', referenceTo: 'User', relationshipName: 'Expense_Claims' },
      { name: 'Attendance__c', label: 'Attendance', type: 'Lookup', referenceTo: 'Attendance__c', relationshipName: 'Expense_Claims' },
      { name: 'Claim_Date__c', label: 'Claim Date', type: 'Date', required: true },
      { name: 'Day_Type__c', label: 'Day Type', type: 'Picklist', values: ['Full_Day', 'Half_Day'], defaultValue: 'Full_Day', required: true },
      { name: 'Daily_Allowance_Amount__c', label: 'Daily Allowance (DA)', type: 'Currency', precision: 10, scale: 2, defaultValue: '250' },
      { name: 'Travel_Mode__c', label: 'Travel Mode', type: 'Picklist', values: ['Two_Wheeler', 'Four_Wheeler', 'Public_Transport', 'Auto_Cab'], defaultValue: 'Two_Wheeler' },
      { name: 'Distance_Traveled_KM__c', label: 'Distance Traveled (KM)', type: 'Number', precision: 8, scale: 2, defaultValue: '0' },
      { name: 'Rate_Per_KM__c', label: 'Rate Per KM', type: 'Currency', precision: 8, scale: 2, defaultValue: '3.50' },
      { name: 'Travel_Allowance_Amount__c', label: 'Travel Allowance (TA)', type: 'Currency', precision: 10, scale: 2, defaultValue: '0' },
      { name: 'Lodging_Hotel_Amount__c', label: 'Lodging / Hotel Amount', type: 'Currency', precision: 10, scale: 2, defaultValue: '0' },
      { name: 'Food_Amount__c', label: 'Food Amount', type: 'Currency', precision: 10, scale: 2, defaultValue: '0' },
      { name: 'Misc_Amount__c', label: 'Misc Expense Amount', type: 'Currency', precision: 10, scale: 2, defaultValue: '0' },
      {
        name: 'Total_Claim_Amount__c',
        label: 'Total Claim Amount',
        type: 'Formula',
        formula: 'Daily_Allowance_Amount__c + Travel_Allowance_Amount__c + Lodging_Hotel_Amount__c + Food_Amount__c + Misc_Amount__c',
        formulaTreatBlanksAs: 'BlankAsZero',
        precision: 10,
        scale: 2
      },
      { name: 'Receipt_Bill_URL__c', label: 'Receipt / Bill URL', type: 'Url' },
      { name: 'Status__c', label: 'Status', type: 'Picklist', values: ['Draft', 'Submitted', 'Approved', 'Rejected', 'Reimbursed'], defaultValue: 'Submitted' },
      { name: 'Approval_Comments__c', label: 'Approval Comments', type: 'Text', length: 255 }
    ]
  },
  {
    name: 'Survey_Response__c',
    label: 'Outlet Survey',
    pluralLabel: 'Outlet Surveys',
    description: 'Field survey questions and feedback captured during store visits',
    sharingModel: 'ReadWrite',
    tabMotif: 'Custom55: Books',
    fields: [
      { name: 'Visit__c', label: 'Visit', type: 'Lookup', referenceTo: 'Visit__c', relationshipName: 'Survey_Responses' },
      { name: 'Retailer__c', label: 'Retailer', type: 'Lookup', referenceTo: 'Retailer__c', relationshipName: 'Survey_Responses' },
      { name: 'Sales_Executive__c', label: 'Sales Executive', type: 'Lookup', referenceTo: 'User', relationshipName: 'Survey_Responses' },
      { name: 'Survey_Date__c', label: 'Survey Date', type: 'Date' },
      { name: 'Survey_Type__c', label: 'Survey Type', type: 'Picklist', values: ['General_Feedback', 'New_Launch_Feedback', 'Visibility_Audit', 'Customer_Satisfaction'], defaultValue: 'General_Feedback' },
      { name: 'Rating__c', label: 'Rating (1 to 5)', type: 'Picklist', values: ['1', '2', '3', '4', '5'], defaultValue: '4' },
      { name: 'Feedback_Notes__c', label: 'Feedback Notes', type: 'LongTextArea', length: 32768, visibleLines: 3 }
    ]
  },
  {
    name: 'Merchandising_Audit__c',
    label: 'Planogram Check',
    pluralLabel: 'Planogram Checks',
    description: 'Merchandising and shelf planogram compliance audits',
    sharingModel: 'ReadWrite',
    tabMotif: 'Custom38: Camera',
    fields: [
      { name: 'Visit__c', label: 'Visit', type: 'Lookup', referenceTo: 'Visit__c', relationshipName: 'Merchandising_Audits' },
      { name: 'Retailer__c', label: 'Retailer', type: 'Lookup', referenceTo: 'Retailer__c', relationshipName: 'Merchandising_Audits' },
      { name: 'Planogram_Compliant__c', label: 'Planogram Compliant', type: 'Checkbox', defaultValue: 'true' },
      { name: 'Brand_Shelf_Share_Percent__c', label: 'Brand Shelf Share (%)', type: 'Percent', precision: 5, scale: 2 },
      { name: 'Display_Location__c', label: 'Display Location', type: 'Picklist', values: ['Eye_Level_Shelf', 'Top_Shelf', 'Bottom_Shelf', 'Cash_Counter', 'Endcap_Display', 'Floor_Standee'], defaultValue: 'Eye_Level_Shelf' },
      { name: 'Shelf_Photo_URL__c', label: 'Shelf Photo URL', type: 'Url' },
      { name: 'Remarks__c', label: 'Remarks', type: 'Text', length: 255 }
    ]
  },
  {
    name: 'Competition_Capture__c',
    label: 'Competition Capture',
    pluralLabel: 'Competition Captures',
    description: 'Competitor brands, pricing, and offers captured in retail shops',
    sharingModel: 'ReadWrite',
    tabMotif: 'Custom28: Submarine',
    fields: [
      { name: 'Visit__c', label: 'Visit', type: 'Lookup', referenceTo: 'Visit__c', relationshipName: 'Competition_Captures' },
      { name: 'Retailer__c', label: 'Retailer', type: 'Lookup', referenceTo: 'Retailer__c', relationshipName: 'Competition_Captures' },
      { name: 'Competitor_Brand__c', label: 'Competitor Brand', type: 'Text', length: 100, required: true },
      { name: 'Competitor_Product__c', label: 'Competitor Product', type: 'Text', length: 100 },
      { name: 'Competitor_Price__c', label: 'Competitor Price', type: 'Currency', precision: 10, scale: 2 },
      { name: 'Competitor_Scheme_Offer__c', label: 'Competitor Scheme / Offer', type: 'Text', length: 255 },
      { name: 'Stock_Visibility__c', label: 'Stock Visibility', type: 'Picklist', values: ['High', 'Moderate', 'Low'], defaultValue: 'Moderate' }
    ]
  },
  {
    name: 'Shop_Stock_Check__c',
    label: 'Shop Stock Check',
    pluralLabel: 'Shop Stock Checks',
    description: 'Shelf stock count during visit to suggest reorders',
    sharingModel: 'ReadWrite',
    fields: [
      { name: 'Visit__c', label: 'Visit', type: 'Lookup', referenceTo: 'Visit__c', relationshipName: 'Shop_Stock_Checks' },
      { name: 'Retailer__c', label: 'Retailer', type: 'Lookup', referenceTo: 'Retailer__c', relationshipName: 'Shop_Stock_Checks' },
      { name: 'Product__c', label: 'Product', type: 'Lookup', referenceTo: 'Product2', relationshipName: 'Shop_Stock_Checks' },
      { name: 'Shelf_Stock_Quantity__c', label: 'Shelf Stock Quantity', type: 'Number', precision: 10, scale: 0, defaultValue: '0' },
      { name: 'Suggested_Order_Quantity__c', label: 'Suggested Order Quantity', type: 'Number', precision: 10, scale: 0, defaultValue: '0' }
    ]
  },
  {
    name: 'Return_Order__c',
    label: 'Return Order',
    pluralLabel: 'Return Orders',
    description: 'Damaged or expired goods returned by retailer to distributor',
    sharingModel: 'ReadWrite',
    tabMotif: 'Custom77: Locked',
    fields: [
      { name: 'Return_Number__c', label: 'Return Number', type: 'Text', length: 30, unique: true, externalId: true, required: true },
      { name: 'Retailer__c', label: 'Retailer', type: 'Lookup', referenceTo: 'Retailer__c', relationshipName: 'Return_Orders' },
      { name: 'Distributor__c', label: 'Distributor', type: 'Lookup', referenceTo: 'Distributor__c', relationshipName: 'Return_Orders' },
      { name: 'Warehouse__c', label: 'Warehouse', type: 'Lookup', referenceTo: 'Warehouse__c', relationshipName: 'Return_Orders' },
      { name: 'Return_Date__c', label: 'Return Date', type: 'Date' },
      { name: 'Status__c', label: 'Status', type: 'Picklist', values: ['Draft', 'Submitted', 'Approved', 'Rejected', 'Stock_Received', 'Credit_Note_Issued'], defaultValue: 'Draft' },
      { name: 'Total_Return_Amount__c', label: 'Total Return Amount', type: 'Currency', precision: 16, scale: 2, defaultValue: '0' },
      { name: 'Remarks__c', label: 'Remarks', type: 'LongTextArea', length: 32768, visibleLines: 3 }
    ]
  },
  {
    name: 'Return_Line__c',
    label: 'Return Line',
    pluralLabel: 'Return Lines',
    description: 'Line item of returned products with batch and reason',
    sharingModel: 'ControlledByParent',
    fields: [
      { name: 'Return_Order__c', label: 'Return Order', type: 'MasterDetail', referenceTo: 'Return_Order__c', relationshipName: 'Return_Lines', writeRequiresMasterRead: false },
      { name: 'Product__c', label: 'Product', type: 'Lookup', referenceTo: 'Product2', relationshipName: 'Return_Lines' },
      { name: 'Quantity__c', label: 'Quantity', type: 'Number', precision: 10, scale: 2, defaultValue: '1', required: true },
      { name: 'Unit_Price__c', label: 'Unit Price', type: 'Currency', precision: 12, scale: 2, defaultValue: '0' },
      {
        name: 'Total_Amount__c',
        label: 'Total Amount',
        type: 'Formula',
        formula: 'Quantity__c * Unit_Price__c',
        formulaTreatBlanksAs: 'BlankAsZero',
        precision: 16,
        scale: 2
      },
      { name: 'Batch_Number__c', label: 'Batch Number', type: 'Text', length: 50 },
      { name: 'Return_Reason__c', label: 'Return Reason', type: 'Picklist', values: ['Expired_Stock', 'Damaged_In_Transit', 'Slow_Moving', 'Leakage_Seal_Broken', 'Wrong_Shipment'], defaultValue: 'Damaged_In_Transit' }
    ]
  },
  {
    name: 'Credit_Note__c',
    label: 'Credit Note',
    pluralLabel: 'Credit Notes',
    description: 'Credit balance given back to shop for returns, scheme claims, and price adjustments',
    sharingModel: 'ReadWrite',
    tabMotif: 'Custom16: Bank',
    fields: [
      { name: 'Credit_Note_Number__c', label: 'Credit Note Number', type: 'Text', length: 30, unique: true, externalId: true, required: true },
      { name: 'Retailer__c', label: 'Retailer', type: 'Lookup', referenceTo: 'Retailer__c', relationshipName: 'Credit_Notes' },
      { name: 'Distributor__c', label: 'Distributor', type: 'Lookup', referenceTo: 'Distributor__c', relationshipName: 'Credit_Notes' },
      { name: 'Invoice__c', label: 'Invoice', type: 'Lookup', referenceTo: 'Invoice__c', relationshipName: 'Credit_Notes' },
      { name: 'Return_Order__c', label: 'Return Order', type: 'Lookup', referenceTo: 'Return_Order__c', relationshipName: 'Credit_Notes' },
      { name: 'Credit_Amount__c', label: 'Credit Amount', type: 'Currency', precision: 16, scale: 2, required: true },
      { name: 'Issue_Date__c', label: 'Issue Date', type: 'Date' },
      { name: 'Reason__c', label: 'Reason', type: 'Picklist', values: ['Goods_Return', 'Scheme_Discount_Claim', 'Rate_Difference', 'Damage_Allowance', 'Cash_Discount'], defaultValue: 'Goods_Return' },
      { name: 'Status__c', label: 'Status', type: 'Picklist', values: ['Issued', 'Adjusted_Against_Invoice', 'Refunded'], defaultValue: 'Issued' }
    ]
  }
];

// 2. Custom Fields on Existing Objects
const existingObjectFields = [
  // Product2 enhancements
  {
    objectName: 'Product2',
    fields: [
      { name: 'Brand__c', label: 'Brand', type: 'Text', length: 50 },
      { name: 'Category__c', label: 'Category', type: 'Picklist', values: ['Beverages', 'Personal_Care', 'Packaged_Foods', 'Home_Care', 'Dairy', 'Staples', 'Snacks', 'Oral_Care'], defaultValue: 'Personal_Care' },
      { name: 'Sub_Category__c', label: 'Sub Category', type: 'Text', length: 50 },
      { name: 'UOM__c', label: 'Unit of Measure (UOM)', type: 'Picklist', values: ['Piece', 'Box', 'Carton', 'Bottle', 'Pack', 'Case', 'Kg', 'Liter'], defaultValue: 'Piece' },
      { name: 'Pack_Size__c', label: 'Pack Size', type: 'Text', length: 30 },
      { name: 'MRP__c', label: 'MRP (Maximum Retail Price)', type: 'Currency', precision: 16, scale: 2 },
      { name: 'Base_Price__c', label: 'Base Wholesale Price', type: 'Currency', precision: 16, scale: 2 },
      { name: 'HSN_Code__c', label: 'HSN Code', type: 'Text', length: 20 },
      { name: 'GST_Rate__c', label: 'GST Rate (%)', type: 'Percent', precision: 5, scale: 2, defaultValue: '18' },
      { name: 'EAN_Barcode__c', label: 'EAN Barcode', type: 'Text', length: 50 }
    ]
  },
  // Attendance enhancements
  {
    objectName: 'Attendance__c',
    fields: [
      { name: 'Day_Type__c', label: 'Day Type', type: 'Picklist', values: ['Full_Day', 'Half_Day', 'Leave', 'Weekly_Off'], defaultValue: 'Full_Day' },
      { name: 'Daily_Allowance_Eligible__c', label: 'Daily Allowance Eligible', type: 'Checkbox', defaultValue: 'true' },
      { name: 'Selfie_Image_URL__c', label: 'Selfie Image URL', type: 'Url' }
    ]
  },
  // Order enhancements
  {
    objectName: 'Order__c',
    fields: [
      { name: 'Applied_Scheme__c', label: 'Applied Scheme', type: 'Lookup', referenceTo: 'Scheme__c', relationshipName: 'Orders' }
    ]
  },
  // Order Line enhancements
  {
    objectName: 'Order_Line__c',
    fields: [
      { name: 'Applied_Scheme__c', label: 'Applied Scheme', type: 'Lookup', referenceTo: 'Scheme__c', relationshipName: 'Order_Lines' },
      { name: 'Free_Goods_Quantity__c', label: 'Free Goods Quantity', type: 'Number', precision: 10, scale: 0, defaultValue: '0' }
    ]
  }
];

// Helper to write Field XML
function writeFieldXml(dir, f) {
  let typeXml = '';
  if (f.type === 'Text') {
    typeXml = `<type>Text</type>
    <length>${f.length || 255}</length>
    ${f.unique ? '<unique>true</unique>' : ''}
    ${f.externalId ? '<externalId>true</externalId>' : ''}`;
  } else if (f.type === 'LongTextArea') {
    typeXml = `<type>LongTextArea</type>
    <length>${f.length || 32768}</length>
    <visibleLines>${f.visibleLines || 3}</visibleLines>`;
  } else if (f.type === 'Currency') {
    typeXml = `<type>Currency</type>
    <precision>${f.precision || 16}</precision>
    <scale>${f.scale || 2}</scale>
    ${f.defaultValue ? `<defaultValue>${f.defaultValue}</defaultValue>` : ''}`;
  } else if (f.type === 'Number') {
    typeXml = `<type>Number</type>
    <precision>${f.precision || 10}</precision>
    <scale>${f.scale || 0}</scale>
    ${f.defaultValue ? `<defaultValue>${f.defaultValue}</defaultValue>` : ''}`;
  } else if (f.type === 'Percent') {
    typeXml = `<type>Percent</type>
    <precision>${f.precision || 5}</precision>
    <scale>${f.scale || 2}</scale>
    ${f.defaultValue ? `<defaultValue>${f.defaultValue}</defaultValue>` : ''}`;
  } else if (f.type === 'Checkbox') {
    typeXml = `<type>Checkbox</type>
    <defaultValue>${f.defaultValue || 'false'}</defaultValue>`;
  } else if (f.type === 'Date') {
    typeXml = `<type>Date</type>`;
  } else if (f.type === 'DateTime') {
    typeXml = `<type>DateTime</type>`;
  } else if (f.type === 'Url') {
    typeXml = `<type>Url</type>`;
  } else if (f.type === 'Formula') {
    typeXml = `<type>Number</type>
    <formula>${f.formula}</formula>
    <formulaTreatBlanksAs>${f.formulaTreatBlanksAs || 'BlankAsZero'}</formulaTreatBlanksAs>
    <precision>${f.precision || 10}</precision>
    <scale>${f.scale || 2}</scale>`;
  } else if (f.type === 'Picklist') {
    const valueSet = f.values.map(v => `                <value>
                    <fullName>${v}</fullName>
                    <default>${v === f.defaultValue}</default>
                    <label>${v.replace(/_/g, ' ')}</label>
                </value>`).join('\n');
    typeXml = `<type>Picklist</type>
    <valueSet>
        <valueSetDefinition>
            <sorted>false</sorted>
${valueSet}
        </valueSetDefinition>
    </valueSet>`;
  } else if (f.type === 'Lookup') {
    typeXml = `<type>Lookup</type>
    <referenceTo>${f.referenceTo}</referenceTo>
    <relationshipName>${f.relationshipName || f.name.replace('__c', 's')}</relationshipName>
    <deleteConstraint>SetNull</deleteConstraint>`;
  } else if (f.type === 'MasterDetail') {
    typeXml = `<type>MasterDetail</type>
    <referenceTo>${f.referenceTo}</referenceTo>
    <relationshipName>${f.relationshipName || f.name.replace('__c', 's')}</relationshipName>
    <writeRequiresMasterRead>${f.writeRequiresMasterRead !== undefined ? f.writeRequiresMasterRead : false}</writeRequiresMasterRead>`;
  }

  // MasterDetail CANNOT have required tag in Salesforce XML
  const requiredTag = (f.required && f.type !== 'MasterDetail') ? '<required>true</required>' : '';

  const xml = `<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>${f.name}</fullName>
    <label>${f.label}</label>
    ${requiredTag}
    ${typeXml}
</CustomField>
`;
  fs.writeFileSync(path.join(dir, `${f.name}.field-meta.xml`), xml, 'utf8');
}

// Write Object XML
function writeObjectXml(obj) {
  const dir = path.join(objectsDir, obj.name);
  ensureDir(dir);
  ensureDir(path.join(dir, 'fields'));

  const xml = `<?xml version="1.0" encoding="UTF-8"?>
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
    <enableActivities>false</enableActivities>
    <enableBulkApi>true</enableBulkApi>
    <enableFeeds>false</enableFeeds>
    <enableHistory>false</enableHistory>
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
  fs.writeFileSync(path.join(dir, `${obj.name}.object-meta.xml`), xml, 'utf8');

  // Fields
  obj.fields.forEach(f => writeFieldXml(path.join(dir, 'fields'), f));

  // Tab if specified
  if (obj.tabMotif) {
    const tabXml = `<?xml version="1.0" encoding="UTF-8"?>
<CustomTab xmlns="http://soap.sforce.com/2006/04/metadata">
    <customObject>true</customObject>
    <motif>${obj.tabMotif}</motif>
</CustomTab>
`;
    fs.writeFileSync(path.join(tabsDir, `${obj.name}.tab-meta.xml`), tabXml, 'utf8');
  }

  // List View "All"
  const lvDir = listViewsDir(obj.name);
  ensureDir(lvDir);
  const lvXml = `<?xml version="1.0" encoding="UTF-8"?>
<ListView xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>All</fullName>
    <columns>NAME</columns>
${obj.fields.slice(0, 5).map(f => `    <columns>${f.name}</columns>`).join('\n')}
    <filterScope>Everything</filterScope>
    <label>All</label>
</ListView>
`;
  fs.writeFileSync(path.join(lvDir, 'All.listView-meta.xml'), lvXml, 'utf8');
}

// Execute Object Creation
console.log('Writing updated Custom Objects...');
newObjects.forEach(obj => {
  writeObjectXml(obj);
  console.log(`- Created object ${obj.name}`);
});

// Execute Existing Object Field Additions
console.log('Writing updated fields to existing objects...');
existingObjectFields.forEach(ef => {
  const dir = path.join(objectsDir, ef.objectName);
  ensureDir(dir);
  ensureDir(path.join(dir, 'fields'));
  ef.fields.forEach(f => {
    writeFieldXml(path.join(dir, 'fields'), f);
    console.log(`- Added field ${ef.objectName}.${f.name}`);
  });
});

console.log('Done updating metadata files.');
