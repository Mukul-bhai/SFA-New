const fs = require('fs');
const path = require('path');

const baseDir = path.join(__dirname, '..', '..', 'force-app', 'main', 'default');
const layoutsDir = path.join(baseDir, 'layouts');

function writeLayout(objName, layoutName, sections) {
    let xml = `<?xml version="1.0" encoding="UTF-8"?>\n<Layout xmlns="http://soap.sforce.com/2006/04/metadata">\n`;
    sections.forEach(sec => {
        xml += `    <layoutSections>\n`;
        xml += `        <customLabel>${sec.customLabel || 'false'}</customLabel>\n`;
        xml += `        <detailHeading>${sec.detailHeading || 'false'}</detailHeading>\n`;
        xml += `        <editHeading>true</editHeading>\n`;
        xml += `        <label>${sec.label}</label>\n`;
        xml += `        <layoutColumns>\n`;
        (sec.left || []).forEach(f => {
            xml += `            <layoutItems>\n                <behavior>${f.behavior || 'Edit'}</behavior>\n                <field>${f.field}</field>\n            </layoutItems>\n`;
        });
        xml += `        </layoutColumns>\n`;
        xml += `        <layoutColumns>\n`;
        (sec.right || []).forEach(f => {
            xml += `            <layoutItems>\n                <behavior>${f.behavior || 'Edit'}</behavior>\n                <field>${f.field}</field>\n            </layoutItems>\n`;
        });
        xml += `        </layoutColumns>\n`;
        xml += `        <style>TwoColumnsTopToBottom</style>\n`;
        xml += `    </layoutSections>\n`;
    });

    // System Information
    xml += `    <layoutSections>\n        <customLabel>false</customLabel>\n        <detailHeading>true</detailHeading>\n        <editHeading>true</editHeading>\n        <label>System Information</label>\n        <layoutColumns>\n            <layoutItems>\n                <behavior>Readonly</behavior>\n                <field>CreatedById</field>\n            </layoutItems>\n        </layoutColumns>\n        <layoutColumns>\n            <layoutItems>\n                <behavior>Readonly</behavior>\n                <field>LastModifiedById</field>\n            </layoutItems>\n        </layoutColumns>\n        <style>TwoColumnsTopToBottom</style>\n    </layoutSections>\n`;
    xml += `</Layout>\n`;

    fs.writeFileSync(path.join(layoutsDir, `${objName}-${layoutName}.layout-meta.xml`), xml, 'utf8');
    console.log('Created layout:', `${objName}-${layoutName}.layout-meta.xml`);
}

// 1. Product__c Layout
writeLayout('Product__c', 'Product Layout', [
    {
        label: 'Product Information',
        left: [
            { behavior: 'Required', field: 'Name' },
            { field: 'Product_Code__c' },
            { field: 'SKU__c' },
            { field: 'Brand__c' },
            { field: 'Sub_Brand__c' },
            { field: 'Brand_Alias__c' },
            { field: 'Category__c' },
            { field: 'Is_Active__c' }
        ],
        right: [
            { field: 'MRP__c' },
            { field: 'RBP__c' },
            { field: 'GST_Percentage__c' },
            { field: 'Quantity__c' },
            { field: 'Available_Stock__c' },
            { field: 'Unit_Conversion__c' },
            { field: 'Package_Type__c' },
            { field: 'Product_Image__c' }
        ]
    },
    {
        label: 'Attributes & Manufacturing',
        detailHeading: 'true',
        left: [
            { field: 'Flavour__c' },
            { field: 'Variant__c' }
        ],
        right: [
            { field: 'Batch_No__c' },
            { field: 'Manufacturing_Date__c' },
            { field: 'Expiry_Date__c' }
        ]
    }
]);

// 2. Asset_Survey__c Layout
writeLayout('Asset_Survey__c', 'Asset Survey Layout', [
    {
        label: 'Information',
        left: [
            { behavior: 'Readonly', field: 'Name' },
            { field: 'Outlet__c' },
            { field: 'Visit__c' },
            { behavior: 'Required', field: 'Asset_Name__c' },
            { field: 'Asset_Code__c' }
        ],
        right: [
            { field: 'Status__c' },
            { field: 'Given_Date__c' },
            { field: 'Survey_Date__c' },
            { field: 'Picture__c' }
        ]
    },
    {
        label: 'Remarks',
        detailHeading: 'true',
        left: [
            { field: 'Remarks__c' }
        ],
        right: []
    }
]);

// 3. Competitor_Activity__c Layout
writeLayout('Competitor_Activity__c', 'Competitor Activity Layout', [
    {
        label: 'Information',
        left: [
            { behavior: 'Readonly', field: 'Name' },
            { field: 'Outlet__c' },
            { field: 'Visit__c' },
            { behavior: 'Required', field: 'Competitor_Name__c' },
            { field: 'Company__c' },
            { field: 'Category__c' }
        ],
        right: [
            { field: 'MRP__c' },
            { field: 'RBP__c' },
            { field: 'Capture_Date__c' },
            { field: 'Image__c' }
        ]
    },
    {
        label: 'Schemes & Notes',
        detailHeading: 'true',
        left: [
            { field: 'Schemes__c' }
        ],
        right: [
            { field: 'Remarks__c' }
        ]
    }
]);

// 4. Stock_Check__c Layout
writeLayout('Stock_Check__c', 'Stock Check Layout', [
    {
        label: 'Information',
        left: [
            { behavior: 'Readonly', field: 'Name' },
            { field: 'Outlet__c' },
            { field: 'Visit__c' },
            { field: 'Product__c' },
            { field: 'Quantity__c' }
        ],
        right: [
            { field: 'Stock_Condition__c' },
            { field: 'Check_Date__c' },
            { field: 'Batch_No__c' },
            { field: 'Manufacturing_Date__c' },
            { field: 'Expiry_Date__c' }
        ]
    },
    {
        label: 'Remarks',
        detailHeading: 'true',
        left: [
            { field: 'Remarks__c' }
        ],
        right: []
    }
]);

// 5. Ticket__c Layout
writeLayout('Ticket__c', 'Ticket Layout', [
    {
        label: 'Ticket Details',
        left: [
            { behavior: 'Readonly', field: 'Name' },
            { field: 'Outlet__c' },
            { field: 'Visit__c' },
            { behavior: 'Required', field: 'Subject__c' },
            { field: 'Category__c' }
        ],
        right: [
            { field: 'Status__c' },
            { field: 'Priority__c' },
            { field: 'Assigned_To__c' },
            { field: 'Image__c' }
        ]
    },
    {
        label: 'Description & Resolution',
        detailHeading: 'true',
        left: [
            { field: 'Description__c' }
        ],
        right: [
            { field: 'Resolution_Notes__c' }
        ]
    }
]);

// 6. Product_Return__c Layout
writeLayout('Product_Return__c', 'Product Return Layout', [
    {
        label: 'Return Information',
        left: [
            { behavior: 'Readonly', field: 'Name' },
            { field: 'Outlet__c' },
            { field: 'Visit__c' },
            { field: 'Product__c' },
            { field: 'Quantity__c' }
        ],
        right: [
            { field: 'Return_Reason__c' },
            { field: 'Status__c' },
            { field: 'Return_Date__c' },
            { field: 'Credit_Amount__c' },
            { field: 'Batch_No__c' },
            { field: 'Manufacturing_Date__c' }
        ]
    },
    {
        label: 'Remarks',
        detailHeading: 'true',
        left: [
            { field: 'Remarks__c' }
        ],
        right: []
    }
]);
