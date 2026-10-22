// ==========================================
// SEED MOCK DATA MATCHING BRD & SCRIPT (JS)
// ==========================================

const INITIAL_DISTRIBUTOR = {
  id: 'DIST-001',
  code: 'DIST-MYF-001',
  name: 'Myfair Distribution Hub',
  area: 'Mumbai East Central & Suburbs',
  phone: '+91 98200 44550',
  email: 'operations@myfairdistributors.com',
  status: 'Active',
  creditLimit: 1200000,
  currentOutstanding: 345000,
  defaultWarehouseName: 'Myfair Central Godown - Depot #4',
  totalOutlets: 70,
  salesReps: [
    {
      id: 'SR-01',
      name: 'Rahul Sharma',
      code: 'EMP-SR-101',
      phone: '+91 98112 33441',
      email: 'rahul.sfa@myfair.com',
      assignedBeats: ['Monday Market Beat', 'Wednesday Central Route', 'Friday High-Street'],
      totalAssignedOutlets: 36,
      monthlyTarget: 450000,
      achievedAmount: 395000,
      strikeRate: 86.4,
      status: 'Active'
    },
    {
      id: 'SR-02',
      name: 'Amit Verma',
      code: 'EMP-SR-102',
      phone: '+91 98334 55662',
      email: 'amit.sfa@myfair.com',
      assignedBeats: ['Tuesday Coastal Beat', 'Thursday Retail Hub', 'Saturday Corner Shops'],
      totalAssignedOutlets: 34,
      monthlyTarget: 400000,
      achievedAmount: 368000,
      strikeRate: 82.1,
      status: 'Active'
    }
  ],
  beats: [
    { id: 'BEAT-01', name: 'Monday Market Beat', code: 'BT-MON-01', dayOfWeek: 'Monday', assignedSR: 'Rahul Sharma', outletCount: 12 },
    { id: 'BEAT-02', name: 'Tuesday Coastal Beat', code: 'BT-TUE-02', dayOfWeek: 'Tuesday', assignedSR: 'Amit Verma', outletCount: 11 },
    { id: 'BEAT-03', name: 'Wednesday Central Route', code: 'BT-WED-03', dayOfWeek: 'Wednesday', assignedSR: 'Rahul Sharma', outletCount: 12 },
    { id: 'BEAT-04', name: 'Thursday Retail Hub', code: 'BT-THU-04', dayOfWeek: 'Thursday', assignedSR: 'Amit Verma', outletCount: 11 },
    { id: 'BEAT-05', name: 'Friday High-Street', code: 'BT-FRI-05', dayOfWeek: 'Friday', assignedSR: 'Rahul Sharma', outletCount: 12 },
    { id: 'BEAT-06', name: 'Saturday Corner Shops', code: 'BT-SAT-06', dayOfWeek: 'Saturday', assignedSR: 'Amit Verma', outletCount: 12 }
  ]
};

// Generate 70 outlets managed by Myfair (including Balaji Stores, Gupta, Sharma, etc.)
const generate70Outlets = () => {
  const list = [
    {
      id: 'OUT-01',
      code: 'RET-MYF-01',
      name: 'Balaji Stores',
      shopName: 'Balaji Super Mart & General Provision',
      ownerName: 'Venkatesh Iyer',
      ownerPhone: '+91 98450 11223',
      address: 'Shop 4, Balaji Tower, Chembur Naka, Mumbai',
      beatName: 'Monday Market Beat',
      assignedSRName: 'Rahul Sharma',
      creditLimit: 75000,
      outstandingBalance: 14200,
      creditHold: false,
      status: 'Active Buyer',
      lastOrderDate: '2026-10-18',
      monthlyOrderCount: 4
    },
    {
      id: 'OUT-02',
      code: 'RET-MYF-02',
      name: 'Gupta Supermarket',
      shopName: 'Gupta Kirana & Confectionery',
      ownerName: 'Ramesh Gupta',
      ownerPhone: '+91 98765 43210',
      address: 'G-12, Station Road, Kurla West, Mumbai',
      beatName: 'Monday Market Beat',
      assignedSRName: 'Rahul Sharma',
      creditLimit: 100000,
      outstandingBalance: 24500,
      creditHold: false,
      status: 'Active Buyer',
      lastOrderDate: '2026-10-19',
      monthlyOrderCount: 5
    },
    {
      id: 'OUT-03',
      code: 'RET-MYF-03',
      name: 'Sharma Departmental Store',
      shopName: 'Sharma Daily Needs & FMCG',
      ownerName: 'Dinesh Sharma',
      ownerPhone: '+91 98111 22233',
      address: 'Opp. Jain Temple, Ghatkopar East, Mumbai',
      beatName: 'Tuesday Coastal Beat',
      assignedSRName: 'Amit Verma',
      creditLimit: 40000,
      outstandingBalance: 42500,
      creditHold: true,
      status: 'Inactive / Needs Attention',
      lastOrderDate: '2026-09-12',
      monthlyOrderCount: 0
    },
    {
      id: 'OUT-04',
      code: 'RET-MYF-04',
      name: 'Shree Ganesh Mart',
      shopName: 'Shree Ganesh Provision & Spices',
      ownerName: 'Ganesh Patil',
      ownerPhone: '+91 98220 33445',
      address: 'Bandra Linking Road, Bandra West',
      beatName: 'Wednesday Central Route',
      assignedSRName: 'Rahul Sharma',
      creditLimit: 60000,
      outstandingBalance: 8400,
      creditHold: false,
      status: 'Active Buyer',
      lastOrderDate: '2026-10-17',
      monthlyOrderCount: 3
    },
    {
      id: 'OUT-05',
      code: 'RET-MYF-05',
      name: 'New India Provision',
      shopName: 'New India Mini Mart',
      ownerName: 'Akhtar Ansari',
      ownerPhone: '+91 99300 88776',
      address: 'Sakinaka Junction, Andheri East',
      beatName: 'Thursday Retail Hub',
      assignedSRName: 'Amit Verma',
      creditLimit: 50000,
      outstandingBalance: 12000,
      creditHold: false,
      status: 'Active Buyer',
      lastOrderDate: '2026-10-15',
      monthlyOrderCount: 2
    }
  ];

  const beats = INITIAL_DISTRIBUTOR.beats;
  for (let i = 6; i <= 70; i++) {
    const beatIndex = (i - 1) % beats.length;
    const beat = beats[beatIndex];
    const isInactive = i % 8 === 0;
    list.push({
      id: `OUT-${i.toString().padStart(2, '0')}`,
      code: `RET-MYF-${i.toString().padStart(2, '0')}`,
      name: `Outlet #${i} - ${beat.name.split(' ')[0]} Provision`,
      shopName: `Retail Mart #${i}`,
      ownerName: `Owner ${i}`,
      ownerPhone: `+91 98${(10000000 + i * 1111).toString().substring(0, 8)}`,
      address: `Shop ${i}, Market Complex, Zone ${beatIndex + 1}`,
      beatName: beat.name,
      assignedSRName: beat.assignedSR,
      creditLimit: 30000 + (i % 5) * 10000,
      outstandingBalance: isInactive ? 35000 : 5000 + (i % 10) * 1200,
      creditHold: isInactive,
      status: isInactive ? 'Inactive / Needs Attention' : 'Active Buyer',
      lastOrderDate: isInactive ? '2026-08-25' : `2026-10-${10 + (i % 9)}`,
      monthlyOrderCount: isInactive ? 0 : 2 + (i % 4)
    });
  }
  return list;
};

// 2. Orders from SFA Mobile App
const INITIAL_ORDERS = [
  {
    id: 'ORD-101',
    orderNumber: 'SFA-ORD-2026-001',
    orderDate: '2026-10-20 10:15 AM',
    distributorName: 'Myfair Distribution Hub',
    retailerName: 'Balaji Stores',
    retailerCode: 'RET-MYF-01',
    salesRepName: 'Rahul Sharma',
    status: 'Submitted',
    totalAmount: 18450,
    totalUnits: 140,
    source: 'SFA Mobile App',
    invoiceNumber: 'INV-2026-8801',
    items: [
      { id: 'LI-1', productId: 'P-01', productName: 'Parle-G 100g Glucose Biscuit', quantity: 60, unitPrice: 20, lineTotal: 1200 },
      { id: 'LI-2', productId: 'P-02', productName: 'Malkist Cheese Crackers 120g', quantity: 40, unitPrice: 35, lineTotal: 1400 },
      { id: 'LI-3', productId: 'P-04', productName: 'Frooti Fresh Mango Drink 250ml', quantity: 40, unitPrice: 25, lineTotal: 1000 }
    ]
  },
  {
    id: 'ORD-102',
    orderNumber: 'SFA-ORD-2026-002',
    orderDate: '2026-10-20 11:30 AM',
    distributorName: 'Myfair Distribution Hub',
    retailerName: 'Gupta Supermarket',
    retailerCode: 'RET-MYF-02',
    salesRepName: 'Rahul Sharma',
    status: 'Confirmed',
    totalAmount: 26800,
    totalUnits: 210,
    source: 'SFA Mobile App',
    invoiceNumber: 'INV-2026-8802',
    items: [
      { id: 'LI-4', productId: 'P-01', productName: 'Parle-G 100g Glucose Biscuit', quantity: 100, unitPrice: 20, lineTotal: 2000 },
      { id: 'LI-5', productId: 'P-03', productName: 'Hide & Seek Choco Cookies 120g', quantity: 50, unitPrice: 40, lineTotal: 2000 },
      { id: 'LI-6', productId: 'P-05', productName: 'Appy Fizz Sparkling Apple 300ml', quantity: 60, unitPrice: 38, lineTotal: 2280 }
    ]
  },
  {
    id: 'ORD-103',
    orderNumber: 'SFA-ORD-2026-003',
    orderDate: '2026-10-19 03:45 PM',
    distributorName: 'Myfair Distribution Hub',
    retailerName: 'Shree Ganesh Mart',
    retailerCode: 'RET-MYF-04',
    salesRepName: 'Amit Verma',
    status: 'Dispatched',
    totalAmount: 14500,
    totalUnits: 120,
    source: 'SFA Mobile App',
    invoiceNumber: 'INV-2026-8795',
    dispatchDate: '2026-10-20 09:00 AM',
    items: [
      { id: 'LI-7', productId: 'P-02', productName: 'Malkist Cheese Crackers 120g', quantity: 60, unitPrice: 35, lineTotal: 2100 },
      { id: 'LI-8', productId: 'P-04', productName: 'Frooti Fresh Mango Drink 250ml', quantity: 40, unitPrice: 25, lineTotal: 1500 }
    ]
  },
  {
    id: 'ORD-104',
    orderNumber: 'SFA-ORD-2026-004',
    orderDate: '2026-10-18 02:10 PM',
    distributorName: 'Myfair Distribution Hub',
    retailerName: 'New India Provision',
    retailerCode: 'RET-MYF-05',
    salesRepName: 'Amit Verma',
    status: 'Delivered',
    totalAmount: 31200,
    totalUnits: 250,
    source: 'SFA Mobile App',
    invoiceNumber: 'INV-2026-8780',
    dispatchDate: '2026-10-19 10:00 AM',
    items: [
      { id: 'LI-9', productId: 'P-01', productName: 'Parle-G 100g Glucose Biscuit', quantity: 150, unitPrice: 20, lineTotal: 3000 },
      { id: 'LI-10', productId: 'P-05', productName: 'Appy Fizz Sparkling Apple 300ml', quantity: 100, unitPrice: 38, lineTotal: 3800 }
    ]
  }
];

// 3. Stock & Inventory: The 4 Processes
const INITIAL_STOCK_HELD = [
  {
    id: 'STK-01',
    productId: 'P-01',
    productName: 'Parle-G 100g Glucose Biscuit',
    productCode: 'SKU-PG-100',
    category: 'Biscuits',
    physicalStock: 850,
    reservedStock: 160,
    availableStock: 690,
    batchNo: 'B2610-A1',
    manufacturingDate: '2026-09-01',
    expiryDate: '2027-03-01',
    daysToExpiry: 132,
    unitPrice: 16.5,
    mrp: 20.0,
    status: 'In Stock',
    velocity: 'Fast Moving'
  },
  {
    id: 'STK-02',
    productId: 'P-02',
    productName: 'Malkist Cheese Crackers 120g',
    productCode: 'SKU-MLK-120',
    category: 'Crackers',
    physicalStock: 420,
    reservedStock: 100,
    availableStock: 320,
    batchNo: 'B2609-M2',
    manufacturingDate: '2026-08-15',
    expiryDate: '2027-02-15',
    daysToExpiry: 118,
    unitPrice: 28.0,
    mrp: 35.0,
    status: 'In Stock',
    velocity: 'Fast Moving'
  },
  {
    id: 'STK-03',
    productId: 'P-03',
    productName: 'Hide & Seek Choco Cookies 120g',
    productCode: 'SKU-HNS-120',
    category: 'Premium Cookies',
    physicalStock: 120,
    reservedStock: 50,
    availableStock: 70,
    batchNo: 'B2608-H3',
    manufacturingDate: '2026-08-01',
    expiryDate: '2026-12-01',
    daysToExpiry: 42,
    unitPrice: 32.0,
    mrp: 40.0,
    status: 'Near Expiry',
    velocity: 'Normal'
  },
  {
    id: 'STK-04',
    productId: 'P-04',
    productName: 'Frooti Fresh Mango Drink 250ml',
    productCode: 'SKU-FRT-250',
    category: 'Beverages',
    physicalStock: 600,
    reservedStock: 100,
    availableStock: 500,
    batchNo: 'B2610-F1',
    manufacturingDate: '2026-09-20',
    expiryDate: '2027-03-20',
    daysToExpiry: 151,
    unitPrice: 19.5,
    mrp: 25.0,
    status: 'In Stock',
    velocity: 'Fast Moving'
  },
  {
    id: 'STK-05',
    productId: 'P-05',
    productName: 'Appy Fizz Sparkling Apple 300ml',
    productCode: 'SKU-AFZ-300',
    category: 'Beverages',
    physicalStock: 80,
    reservedStock: 60,
    availableStock: 20,
    batchNo: 'B2607-A5',
    manufacturingDate: '2026-07-10',
    expiryDate: '2027-01-10',
    daysToExpiry: 82,
    unitPrice: 30.0,
    mrp: 38.0,
    status: 'Low Stock',
    velocity: 'Slow Moving'
  }
];

const INITIAL_STOCK_MOVEMENTS = [
  {
    id: 'MOV-01',
    movementDate: '2026-10-18 09:30 AM',
    type: 'STOCK_IN_GRN',
    referenceNumber: 'GRN-2026-1044',
    productName: 'Parle-G 100g Glucose Biscuit',
    batchNo: 'B2610-A1',
    quantityDelta: 500,
    resultingStock: 850,
    entityName: 'Parle Products Ltd (Central Plant)',
    notes: 'Primary shipment received as per PO #7721'
  },
  {
    id: 'MOV-02',
    movementDate: '2026-10-19 11:00 AM',
    type: 'STOCK_OUT_SALE',
    referenceNumber: 'INV-2026-8780',
    productName: 'Parle-G 100g Glucose Biscuit',
    batchNo: 'B2610-A1',
    quantityDelta: -150,
    resultingStock: 700,
    entityName: 'New India Provision',
    notes: 'Secondary order fulfilled & delivered'
  },
  {
    id: 'MOV-03',
    movementDate: '2026-10-19 02:00 PM',
    type: 'RETURN_RESTOCK',
    referenceNumber: 'RET-2026-009',
    productName: 'Frooti Fresh Mango Drink 250ml',
    batchNo: 'B2610-F1',
    quantityDelta: 20,
    resultingStock: 600,
    entityName: 'Balaji Stores',
    notes: 'Salable excess stock returned & inspected'
  }
];

// 4. Tickets (Product, Portal, Delivery issues with 4 statuses)
const INITIAL_TICKETS = [
  {
    id: 'TCK-01',
    ticketNumber: 'TCK-2026-041',
    distributorName: 'Myfair Distribution Hub',
    category: 'Product Issue',
    subject: 'Damaged outer carton of Malkist Cheese Crackers batch B2609-M2',
    description: 'During primary delivery unloading, 4 outer cartons were found crushed and 20 individual packs were torn.',
    priority: 'High',
    status: 'In Progress',
    raisedDate: '2026-10-19 02:30 PM',
    assignedOfficer: 'Suresh Menon (DO Mumbai Central)',
    resolutionNotes: 'Distributor Officer inspected goods. Credit note of ₹700 authorized under warranty.'
  },
  {
    id: 'TCK-02',
    ticketNumber: 'TCK-2026-042',
    distributorName: 'Myfair Distribution Hub',
    category: 'Delivery Delay',
    subject: 'Primary shipment PO-7780 delayed by 48 hours',
    description: 'The transport truck from Pune mother plant has not reached the depot. Buffer stock running low.',
    priority: 'Critical',
    status: 'Open',
    raisedDate: '2026-10-20 09:15 AM',
    assignedOfficer: 'Logistics Desk'
  },
  {
    id: 'TCK-03',
    ticketNumber: 'TCK-2026-039',
    distributorName: 'Myfair Distribution Hub',
    category: 'Portal Issue',
    subject: 'Sync delay observed for Balaji Stores past order lines',
    description: 'Order lines submitted at 10 AM took 20 minutes to populate in DMS table.',
    priority: 'Medium',
    status: 'Closed',
    raisedDate: '2026-10-18 11:20 AM',
    assignedOfficer: 'SFA IT Admin',
    resolutionNotes: 'Apex REST webhook retry worker cleared queue delay. Sync running at sub-second latency.',
    closedDate: '2026-10-18 01:00 PM'
  },
  {
    id: 'TCK-04',
    ticketNumber: 'TCK-2026-038',
    distributorName: 'Myfair Distribution Hub',
    category: 'Billing Dispute',
    subject: 'Request for extra trade discount on expired biscuit batch',
    description: 'Retailer requested company credit for stock expired at shop shelf after 6 months.',
    priority: 'Low',
    status: 'Rejected',
    raisedDate: '2026-10-16 04:00 PM',
    assignedOfficer: 'Ramesh Kulkarni (Zonal Manager)',
    rejectionReason: 'Expiry policy permits credit only within 30 days prior to expiry. Expired past shelf-life threshold.',
    closedDate: '2026-10-17 10:30 AM'
  }
];

// 5. Returns & Assets
const INITIAL_RETURNS = [
  {
    id: 'RET-01',
    returnNumber: 'RET-2026-012',
    retailerName: 'Gupta Supermarket',
    distributorName: 'Myfair Distribution Hub',
    productName: 'Hide & Seek Choco Cookies 120g',
    quantity: 15,
    reason: 'Damaged Packaging',
    condition: 'Damaged/Scrap',
    status: 'Approved & Restocked',
    requestDate: '2026-10-18',
    approvedDate: '2026-10-19',
    creditNoteNumber: 'CN-2026-081'
  },
  {
    id: 'RET-02',
    returnNumber: 'RET-2026-013',
    retailerName: 'Balaji Stores',
    distributorName: 'Myfair Distribution Hub',
    productName: 'Frooti Fresh Mango Drink 250ml',
    quantity: 24,
    reason: 'Wrong Delivery',
    condition: 'Salable',
    status: 'Pending Approval',
    requestDate: '2026-10-20'
  }
];

const INITIAL_ASSETS = [
  {
    id: 'AST-01',
    assetCode: 'FRZ-MYF-001',
    assetType: 'Visicooler / Freezer',
    modelNumber: 'Voltas VC-300 Eco',
    serialNumber: 'SN-VOLT-2025-9921',
    assignedLocation: 'Balaji Stores',
    assignedType: 'Retail Outlet',
    installedDate: '2025-06-15',
    status: 'Operational',
    lastServiceDate: '2026-09-10',
    serviceRemarks: 'Compressor check passed. Cooling temperature stable at 4°C.'
  },
  {
    id: 'AST-02',
    assetCode: 'FRZ-MYF-002',
    assetType: 'Deep Freezer',
    modelNumber: 'BlueStar Hard-Top 400L',
    serialNumber: 'SN-BST-2024-4412',
    assignedLocation: 'Gupta Supermarket',
    assignedType: 'Retail Outlet',
    installedDate: '2024-11-20',
    status: 'Needs Service',
    lastServiceDate: '2026-07-02',
    serviceRemarks: 'Thermostat knob loose, temperature fluctuating.'
  },
  {
    id: 'AST-03',
    assetCode: 'POSM-MYF-010',
    assetType: 'POSM Display Rack',
    modelNumber: 'Heavy-Duty 4-Tier Metal Rack',
    serialNumber: 'POSM-RCK-881',
    assignedLocation: 'Shree Ganesh Mart',
    assignedType: 'Retail Outlet',
    installedDate: '2026-01-10',
    status: 'Operational',
    lastServiceDate: '2026-01-10'
  },
  {
    id: 'AST-04',
    assetCode: 'NEON-MYF-004',
    assetType: 'Neon Signboard',
    modelNumber: 'Parle Glowing LED Brand Board',
    serialNumber: 'NEON-BRD-551',
    assignedLocation: 'Sharma Departmental Store',
    assignedType: 'Retail Outlet',
    installedDate: '2025-03-12',
    status: 'Damaged',
    lastServiceDate: '2025-03-12',
    serviceRemarks: 'Right side backlight transformer burned out.'
  }
];

// ==========================================
// LOCAL STORAGE PERSISTENCE ENGINE
// ==========================================

const STORAGE_KEYS = {
  DISTRIBUTOR: 'dms_distributor_data',
  OUTLETS: 'dms_outlets_data',
  ORDERS: 'dms_orders_data',
  STOCK: 'dms_stock_data',
  MOVEMENTS: 'dms_movements_data',
  TICKETS: 'dms_tickets_data',
  RETURNS: 'dms_returns_data',
  ASSETS: 'dms_assets_data'
};

const getFromStorage = (key, defaultData) => {
  try {
    const raw = localStorage.getItem(key);
    if (!raw) {
      localStorage.setItem(key, JSON.stringify(defaultData));
      return defaultData;
    }
    return JSON.parse(raw);
  } catch {
    return defaultData;
  }
};

const saveToStorage = (key, data) => {
  try {
    localStorage.setItem(key, JSON.stringify(data));
  } catch (e) {
    console.error('Storage save error:', e);
  }
};

// ==========================================
// API SERVICE EXPORT (JS)
// ==========================================

export class DMSDataService {
  // 1. Distributor & Outlets
  static getDistributor() {
    return getFromStorage(STORAGE_KEYS.DISTRIBUTOR, INITIAL_DISTRIBUTOR);
  }

  static getRetailerOutlets() {
    return getFromStorage(STORAGE_KEYS.OUTLETS, generate70Outlets());
  }

  // 2. Orders
  static getOrders() {
    return getFromStorage(STORAGE_KEYS.ORDERS, INITIAL_ORDERS);
  }

  static updateOrderStatus(orderId, newStatus) {
    const orders = this.getOrders();
    const updated = orders.map(o => {
      if (o.id === orderId) {
        return {
          ...o,
          status: newStatus,
          dispatchDate: newStatus === 'Dispatched' ? new Date().toLocaleString() : o.dispatchDate
        };
      }
      return o;
    });
    saveToStorage(STORAGE_KEYS.ORDERS, updated);

    // If marked Dispatched, trigger Stock Out movement automatically
    if (newStatus === 'Dispatched') {
      const order = orders.find(o => o.id === orderId);
      if (order) {
        for (const item of order.items) {
          this.recordStockMovement({
            type: 'STOCK_OUT_SALE',
            referenceNumber: order.invoiceNumber || order.orderNumber,
            productName: item.productName,
            batchNo: 'B2610-A1',
            quantityDelta: -item.quantity,
            entityName: order.retailerName,
            notes: `Dispatched against ${order.orderNumber}`
          });
        }
      }
    }

    return updated;
  }

  // 3. Stock & Inventory (The 4 Processes)
  static getStockHeld() {
    return getFromStorage(STORAGE_KEYS.STOCK, INITIAL_STOCK_HELD);
  }

  static getStockMovements() {
    return getFromStorage(STORAGE_KEYS.MOVEMENTS, INITIAL_STOCK_MOVEMENTS);
  }

  // Process 1: Stock In — Goods Received Note (GRN)
  static createGRN(entry) {
    const stocks = this.getStockHeld();
    let currentStock = 0;
    const updatedStocks = stocks.map(s => {
      if (s.productName.toLowerCase() === entry.productName.toLowerCase()) {
        const newPhys = s.physicalStock + entry.quantity;
        const newAvail = s.availableStock + entry.quantity;
        currentStock = newAvail;
        return {
          ...s,
          physicalStock: newPhys,
          availableStock: newAvail,
          batchNo: entry.batchNo || s.batchNo,
          expiryDate: entry.expiryDate || s.expiryDate,
          status: newAvail > 50 ? 'In Stock' : 'Low Stock'
        };
      }
      return s;
    });

    saveToStorage(STORAGE_KEYS.STOCK, updatedStocks);

    // Log Stock Movement
    this.recordStockMovement({
      type: 'STOCK_IN_GRN',
      referenceNumber: `GRN-${Date.now().toString().substring(7)}`,
      productName: entry.productName,
      batchNo: entry.batchNo,
      quantityDelta: entry.quantity,
      entityName: 'Parle Central Plant / Factory Warehouse',
      notes: `Primary GRN received for PO #${entry.poNumber}`
    });

    return { success: true, newStock: currentStock };
  }

  static recordStockMovement(data) {
    const movements = this.getStockMovements();
    const stocks = this.getStockHeld();
    const targetProduct = stocks.find(s => s.productName.toLowerCase() === data.productName.toLowerCase());
    const resultingStock = targetProduct ? targetProduct.availableStock : 0;

    const newMov = {
      id: `MOV-${Date.now()}`,
      movementDate: new Date().toLocaleString(),
      ...data,
      resultingStock
    };

    movements.unshift(newMov);
    saveToStorage(STORAGE_KEYS.MOVEMENTS, movements);
    return newMov;
  }

  // 4. Ticket Management
  static getTickets() {
    return getFromStorage(STORAGE_KEYS.TICKETS, INITIAL_TICKETS);
  }

  static createTicket(ticket) {
    const tickets = this.getTickets();
    const newTicket = {
      id: `TCK-${Date.now()}`,
      ticketNumber: `TCK-2026-${(tickets.length + 45).toString().padStart(3, '0')}`,
      raisedDate: new Date().toLocaleString(),
      status: 'Open',
      assignedOfficer: 'DO Desk Assigned',
      ...ticket
    };
    tickets.unshift(newTicket);
    saveToStorage(STORAGE_KEYS.TICKETS, tickets);
    return newTicket;
  }

  static updateTicketStatus(ticketId, newStatus, notes, rejectionReason) {
    const tickets = this.getTickets();
    const updated = tickets.map(t => {
      if (t.id === ticketId) {
        return {
          ...t,
          status: newStatus,
          resolutionNotes: notes ?? t.resolutionNotes,
          rejectionReason: rejectionReason ?? t.rejectionReason,
          closedDate: (newStatus === 'Closed' || newStatus === 'Rejected') ? new Date().toLocaleString() : undefined
        };
      }
      return t;
    });
    saveToStorage(STORAGE_KEYS.TICKETS, updated);
    return updated;
  }

  // 5. Returns & Assets
  static getReturns() {
    return getFromStorage(STORAGE_KEYS.RETURNS, INITIAL_RETURNS);
  }

  static updateReturnStatus(returnId, newStatus) {
    const returns = this.getReturns();
    const updated = returns.map(r => {
      if (r.id === returnId) {
        return {
          ...r,
          status: newStatus,
          approvedDate: newStatus.includes('Approved') ? new Date().toLocaleDateString() : undefined,
          creditNoteNumber: newStatus.includes('Approved') ? `CN-2026-${Math.floor(100 + Math.random() * 900)}` : undefined
        };
      }
      return r;
    });
    saveToStorage(STORAGE_KEYS.RETURNS, updated);
    return updated;
  }

  static getAssets() {
    return getFromStorage(STORAGE_KEYS.ASSETS, INITIAL_ASSETS);
  }

  static updateAssetStatus(assetId, newStatus, remarks) {
    const assets = this.getAssets();
    const updated = assets.map(a => {
      if (a.id === assetId) {
        return {
          ...a,
          status: newStatus,
          lastServiceDate: new Date().toLocaleDateString(),
          serviceRemarks: remarks ?? a.serviceRemarks
        };
      }
      return a;
    });
    saveToStorage(STORAGE_KEYS.ASSETS, updated);
    return updated;
  }

  // 6. Dashboards & Reports
  static getSalesVsTarget() {
    return {
      period: 'October 2026 (Month-to-Date)',
      srMetrics: [
        {
          srName: 'Rahul Sharma (Senior SR)',
          target: 450000,
          actual: 395000,
          achievementPct: 87.7,
          lastMonthActual: 360000,
          growthPct: 9.7
        },
        {
          srName: 'Amit Verma (Area SR)',
          target: 400000,
          actual: 368000,
          achievementPct: 92.0,
          lastMonthActual: 330000,
          growthPct: 11.5
        }
      ],
      productMetrics: [
        { category: 'Biscuits', productName: 'Parle-G 100g Glucose', target: 350000, actual: 320000, achievementPct: 91.4 },
        { category: 'Crackers', productName: 'Malkist Cheese Crackers', target: 220000, actual: 195000, achievementPct: 88.6 },
        { category: 'Beverages', productName: 'Frooti Mango 250ml', target: 180000, actual: 165000, achievementPct: 91.6 },
        { category: 'Beverages', productName: 'Appy Fizz Sparkling 300ml', target: 100000, actual: 83000, achievementPct: 83.0 }
      ]
    };
  }

  static getBeatProductivity() {
    return [
      { beatName: 'Monday Market Beat', assignedSR: 'Rahul Sharma', totalPlannedShops: 12, visitedShops: 12, billedOrders: 11, strikeRatePct: 91.6, totalOrderValue: 88400 },
      { beatName: 'Tuesday Coastal Beat', assignedSR: 'Amit Verma', totalPlannedShops: 11, visitedShops: 11, billedOrders: 9, strikeRatePct: 81.8, totalOrderValue: 71200 },
      { beatName: 'Wednesday Central Route', assignedSR: 'Rahul Sharma', totalPlannedShops: 12, visitedShops: 12, billedOrders: 10, strikeRatePct: 83.3, totalOrderValue: 79500 },
      { beatName: 'Thursday Retail Hub', assignedSR: 'Amit Verma', totalPlannedShops: 11, visitedShops: 11, billedOrders: 10, strikeRatePct: 90.9, totalOrderValue: 84600 },
      { beatName: 'Friday High-Street', assignedSR: 'Rahul Sharma', totalPlannedShops: 12, visitedShops: 11, billedOrders: 9, strikeRatePct: 81.8, totalOrderValue: 68900 },
      { beatName: 'Saturday Corner Shops', assignedSR: 'Amit Verma', totalPlannedShops: 12, visitedShops: 12, billedOrders: 10, strikeRatePct: 83.3, totalOrderValue: 74200 }
    ];
  }

  static getOutletCoverage() {
    const outlets = this.getRetailerOutlets();
    const active = outlets.filter(o => o.status === 'Active Buyer').length;
    const inactive = outlets.filter(o => o.status === 'Inactive / Needs Attention');

    return {
      totalOutlets: outlets.length,
      activeBuyers: active,
      inactiveOutlets: inactive.length,
      coveragePct: Math.round((active / outlets.length) * 100),
      inactiveList: inactive.map(o => ({
        outletName: o.name,
        beatName: o.beatName,
        assignedSR: o.assignedSRName,
        daysSinceLastOrder: 38,
        ownerPhone: o.ownerPhone
      }))
    };
  }

  static resetAllData() {
    localStorage.removeItem(STORAGE_KEYS.DISTRIBUTOR);
    localStorage.removeItem(STORAGE_KEYS.OUTLETS);
    localStorage.removeItem(STORAGE_KEYS.ORDERS);
    localStorage.removeItem(STORAGE_KEYS.STOCK);
    localStorage.removeItem(STORAGE_KEYS.MOVEMENTS);
    localStorage.removeItem(STORAGE_KEYS.TICKETS);
    localStorage.removeItem(STORAGE_KEYS.RETURNS);
    localStorage.removeItem(STORAGE_KEYS.ASSETS);
  }
}
