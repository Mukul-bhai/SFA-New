// ==========================================
// DYNAMIC MULTI-DISTRIBUTOR DATA SERVICE (JS)
// Connected with Salesforce Apex REST & Mobile Sync
// ==========================================

const STORAGE_KEYS = {
  ACTIVE_DIST_ID: 'dms_active_distributor_id',
  DISTRIBUTORS_CACHE: 'dms_distributors_cache',
  OUTLETS_CACHE: 'dms_outlets_cache',
  ORDERS_CACHE: 'dms_orders_cache',
  STOCK_CACHE: 'dms_stock_cache',
  TICKETS: 'dms_tickets_data',
  RETURNS: 'dms_returns_data',
  ASSETS: 'dms_assets_data',
  MOVEMENTS: 'dms_movements_data'
};

// Seed Fallback Distributors (Mirrors Salesforce Distributor__c)
const SEED_DISTRIBUTORS = [
  {
    id: 'a02g800000DCme5AAD',
    code: 'DIST-PRI-001',
    name: 'Apex Traders Primary',
    area: 'Mumbai Central & Western Suburbs',
    phone: '+91 98200 11223',
    email: 'ops@apextraders.com',
    status: 'Active',
    creditLimit: 500000,
    currentOutstanding: 85000,
    defaultWarehouseId: 'a04g8000004WXYZAA1',
    defaultWarehouseName: 'Primary Central Depot A',
    gstin: '27AABCT1332L1Z5',
    salesReps: [
      { id: 'SR-01', name: 'Rahul Sharma', code: 'EMP-SR-101', phone: '+91 98112 33441', email: 'rahul.sfa@apex.com', monthlyTarget: 450000, achievedAmount: 395000, strikeRate: 86.4, status: 'Active' },
      { id: 'SR-02', name: 'Amit Verma', code: 'EMP-SR-102', phone: '+91 98334 55662', email: 'amit.sfa@apex.com', monthlyTarget: 400000, achievedAmount: 368000, strikeRate: 82.1, status: 'Active' }
    ],
    beats: [
      { id: 'BEAT-01', name: 'Monday Market Beat', code: 'BT-MON-01', dayOfWeek: 'Monday', assignedSR: 'Rahul Sharma' },
      { id: 'BEAT-02', name: 'Tuesday Coastal Beat', code: 'BT-TUE-02', dayOfWeek: 'Tuesday', assignedSR: 'Amit Verma' }
    ]
  },
  {
    id: 'a02g800000DCyYnAAL',
    code: 'DIST-ROYAL-001',
    name: 'Royal Super Distributors',
    area: 'Delhi NCR South & West Region',
    phone: '+91 98100 99887',
    email: 'contact@royaldistributors.com',
    status: 'Active',
    creditLimit: 50000,
    currentOutstanding: 0,
    defaultWarehouseId: 'a04g8000004WXYZAA2',
    defaultWarehouseName: 'Royal Central Depot 1',
    gstin: '07AABCR9911K1Z2',
    salesReps: [
      { id: 'SR-03', name: 'Vikas Khanna', code: 'EMP-SR-103', phone: '+91 98711 22334', email: 'vikas@royal.com', monthlyTarget: 350000, achievedAmount: 310000, strikeRate: 88.5, status: 'Active' }
    ],
    beats: [
      { id: 'BEAT-03', name: 'South Delhi Daily Route', code: 'BT-DEL-01', dayOfWeek: 'Wednesday', assignedSR: 'Vikas Khanna' }
    ]
  },
  {
    id: 'a02g800000DCme6AAD',
    code: 'DIST-BAK-002',
    name: 'Zenith Logistics Backup',
    area: 'Pune & Western Maharashtra Corridor',
    phone: '+91 98500 77665',
    email: 'support@zenithlogistics.in',
    status: 'Active',
    creditLimit: 300000,
    currentOutstanding: 25000,
    defaultWarehouseId: 'a04g8000004WXYZAA3',
    defaultWarehouseName: 'Backup Warehouse B',
    gstin: '27AABCZ5544M1Z8',
    salesReps: [
      { id: 'SR-04', name: 'Sanjay Deshmukh', code: 'EMP-SR-104', phone: '+91 98220 33445', email: 'sanjay@zenith.in', monthlyTarget: 300000, achievedAmount: 245000, strikeRate: 81.6, status: 'Active' }
    ],
    beats: [
      { id: 'BEAT-04', name: 'Pune High-Street Route', code: 'BT-PUN-01', dayOfWeek: 'Thursday', assignedSR: 'Sanjay Deshmukh' }
    ]
  }
];

// Seed Outlets matching Salesforce Retailer__c
const SEED_OUTLETS = [
  {
    id: 'a0Bg800000QHgOrEAL',
    code: 'RET-1001',
    name: 'Gupta Supermarket',
    shopName: 'Gupta Kirana & General Store',
    ownerName: 'Ramesh Gupta',
    ownerPhone: '+91 98765 43210',
    address: 'G-12, Station Road, Kurla West, Mumbai',
    primaryDistributorId: 'a02g800000DCme5AAD',
    primaryDistributorName: 'Apex Traders Primary',
    beatName: 'Monday Market Beat',
    assignedSRName: 'Rahul Sharma',
    creditLimit: 50000,
    outstandingBalance: 8348.5,
    creditHold: false,
    status: 'Active Buyer',
    lastOrderDate: '2026-10-21',
    monthlyOrderCount: 6
  },
  {
    id: 'a0Bg800000QIXD3EAP',
    code: 'RET-2001',
    name: 'Aggarwal Daily Need',
    shopName: 'Aggarwal Mega Grocery',
    ownerName: 'Suresh Aggarwal',
    ownerPhone: '+91 98990 11223',
    address: 'Shop 8, Ring Road Market, Lajpat Nagar, New Delhi',
    primaryDistributorId: 'a02g800000DCyYnAAL',
    primaryDistributorName: 'Royal Super Distributors',
    beatName: 'South Delhi Daily Route',
    assignedSRName: 'Vikas Khanna',
    creditLimit: 50000,
    outstandingBalance: 0,
    creditHold: false,
    status: 'Active Buyer',
    lastOrderDate: '2026-10-20',
    monthlyOrderCount: 4
  },
  {
    id: 'a0Bg800000QEBHaEAP',
    code: 'RET-1002',
    name: 'Sharma Departmental Store',
    shopName: 'Sharma Daily Needs & FMCG',
    ownerName: 'Dinesh Sharma',
    ownerPhone: '+91 98111 22233',
    address: 'Opp. Jain Temple, Ghatkopar East, Mumbai',
    primaryDistributorId: 'a02g800000DCme5AAD',
    primaryDistributorName: 'Apex Traders Primary',
    beatName: 'Tuesday Coastal Beat',
    assignedSRName: 'Amit Verma',
    creditLimit: 25000,
    outstandingBalance: 27500,
    creditHold: true,
    status: 'Inactive / Needs Attention',
    lastOrderDate: '2026-09-15',
    monthlyOrderCount: 1
  }
];

// Seed Orders matching Salesforce Order__c & Mobile bookings
const SEED_ORDERS = [
  {
    id: 'a08g800000WxlbZAAR',
    orderNumber: 'ORD-20261005-001',
    retailerId: 'a0Bg800000QHgOrEAL',
    retailerName: 'Gupta Supermarket',
    retailerShopName: 'Gupta Kirana & General Store',
    primaryDistributorId: 'a02g800000DCme5AAD',
    primaryDistributorName: 'Apex Traders Primary',
    salesExecutiveName: 'Rahul Sharma',
    orderDate: '2026-10-21 11:30 AM',
    status: 'Approved',
    totalAmount: 8012.5,
    paymentMethod: 'Credit Terms (14 Days)',
    paymentStatus: 'Pending',
    items: [
      { id: 'LI-01', productId: 'a0Xg8000006wk73EAA', productName: 'Parle-G Original Glucose Biscuit', productCode: 'P-GLU-001', quantity: 200, unitPrice: 21.5, lineTotal: 4300, fulfillmentStatus: 'Allocated' },
      { id: 'LI-02', productId: 'a0Xg8000006wk74EAA', productName: 'Monaco Classic Salted Crackers', productCode: 'P-MON-002', quantity: 150, unitPrice: 17.2, lineTotal: 2580, fulfillmentStatus: 'Allocated' },
      { id: 'LI-03', productId: 'a0Xg8000006wk76EAA', productName: 'Hide & Seek Chocolate Chip Cookies', productCode: 'P-HNS-004', quantity: 33, unitPrice: 34.0, lineTotal: 1122, fulfillmentStatus: 'Allocated' }
    ]
  },
  {
    id: 'a08g800000aeiyTAAQ',
    orderNumber: 'ORD-20261022-004',
    retailerId: 'a0Bg800000QHgOrEAL',
    retailerName: 'Gupta Supermarket',
    retailerShopName: 'Gupta Kirana & General Store',
    primaryDistributorId: 'a02g800000DCme5AAD',
    primaryDistributorName: 'Apex Traders Primary',
    salesExecutiveName: 'Rahul Sharma',
    orderDate: '2026-10-22 09:15 AM',
    status: 'Submitted',
    totalAmount: 600.0,
    paymentMethod: 'Cash on Delivery',
    paymentStatus: 'Pending',
    items: [
      { id: 'LI-04', productId: 'a0Xg8000006wk75EAA', productName: 'Krackjack Sweet & Salty Biscuit', productCode: 'P-KRK-003', quantity: 20, unitPrice: 25.8, lineTotal: 516, fulfillmentStatus: 'Pending' }
    ]
  },
  {
    id: 'ORD-ROYAL-LIVE-01',
    orderNumber: 'ORD-20261020-009',
    retailerId: 'a0Bg800000QIXD3EAP',
    retailerName: 'Aggarwal Daily Need',
    retailerShopName: 'Aggarwal Mega Grocery',
    primaryDistributorId: 'a02g800000DCyYnAAL',
    primaryDistributorName: 'Royal Super Distributors',
    salesExecutiveName: 'Vikas Khanna',
    orderDate: '2026-10-20 03:45 PM',
    status: 'Pending Fulfillment',
    totalAmount: 4850.0,
    paymentMethod: 'UPI / Online',
    paymentStatus: 'Paid',
    items: [
      { id: 'LI-05', productId: 'a0Xg8000006wk73EAA', productName: 'Parle-G Original Glucose Biscuit', productCode: 'P-GLU-001', quantity: 150, unitPrice: 21.5, lineTotal: 3225, fulfillmentStatus: 'Pending' },
      { id: 'LI-06', productId: 'a0Xg8000006wk77EAA', productName: 'Parle 20-20 Cashew Butter Cookies', productCode: 'P-TTW-005', quantity: 76, unitPrice: 21.25, lineTotal: 1615, fulfillmentStatus: 'Pending' }
    ]
  }
];

// Seed Inventory matching Salesforce Inventory__c
const SEED_STOCK = [
  { id: 'INV-01', warehouseName: 'Primary Central Depot A', distributorId: 'a02g800000DCme5AAD', productName: 'Parle-G Original Glucose Biscuit', productCode: 'P-GLU-001', batchNo: 'B2610-A1', expiryDate: '2027-04-30', physicalStock: 1200, reservedStock: 350, availableStock: 850, unit: 'Cases', status: 'In Stock' },
  { id: 'INV-02', warehouseName: 'Primary Central Depot A', distributorId: 'a02g800000DCme5AAD', productName: 'Monaco Classic Salted Crackers', productCode: 'P-MON-002', batchNo: 'B2610-A2', expiryDate: '2027-03-31', physicalStock: 600, reservedStock: 150, availableStock: 450, unit: 'Cases', status: 'In Stock' },
  { id: 'INV-03', warehouseName: 'Primary Central Depot A', distributorId: 'a02g800000DCme5AAD', productName: 'Krackjack Sweet & Salty Biscuit', productCode: 'P-KRK-003', batchNo: 'B2609-K1', expiryDate: '2027-02-28', physicalStock: 400, reservedStock: 20, availableStock: 380, unit: 'Cases', status: 'In Stock' },
  { id: 'INV-04', warehouseName: 'Primary Central Depot A', distributorId: 'a02g800000DCme5AAD', productName: 'Hide & Seek Chocolate Chip Cookies', productCode: 'P-HNS-004', batchNo: 'B2610-H1', expiryDate: '2027-05-15', physicalStock: 180, reservedStock: 33, availableStock: 147, unit: 'Cases', status: 'In Stock' },
  { id: 'INV-05', warehouseName: 'Primary Central Depot A', distributorId: 'a02g800000DCme5AAD', productName: 'Kopiko Coffee Candy Jar', productCode: 'P-KOP-010', batchNo: 'B2608-KP', expiryDate: '2026-12-31', physicalStock: 40, reservedStock: 0, availableStock: 40, unit: 'Jars', status: 'Low Stock' },
  { id: 'INV-06', warehouseName: 'Royal Central Depot 1', distributorId: 'a02g800000DCyYnAAL', productName: 'Parle-G Original Glucose Biscuit', productCode: 'P-GLU-001', batchNo: 'B2610-R1', expiryDate: '2027-04-30', physicalStock: 800, reservedStock: 150, availableStock: 650, unit: 'Cases', status: 'In Stock' },
  { id: 'INV-07', warehouseName: 'Royal Central Depot 1', distributorId: 'a02g800000DCyYnAAL', productName: 'Parle 20-20 Cashew Butter Cookies', productCode: 'P-TTW-005', batchNo: 'B2610-R2', expiryDate: '2027-03-31', physicalStock: 500, reservedStock: 76, availableStock: 424, unit: 'Cases', status: 'In Stock' },
  { id: 'INV-08', warehouseName: 'Backup Warehouse B', distributorId: 'a02g800000DCme6AAD', productName: 'Parle Gold Rich Glucose Biscuit', productCode: 'P-GLD-009', batchNo: 'B2610-Z1', expiryDate: '2027-06-30', physicalStock: 450, reservedStock: 0, availableStock: 450, unit: 'Cases', status: 'In Stock' }
];

const SEED_TICKETS = [
  { id: 'TCK-01', ticketNumber: 'TCK-2026-088', distributorId: 'a02g800000DCme5AAD', category: 'Product Issue', priority: 'High', subject: 'Crushed cartons in morning factory delivery (Parle-G)', description: 'Batch B2610-A1 had 12 outer corrugated cartons crushed during transit from Factory.', status: 'Open', assignedOfficer: 'DO Ramesh Kadam (Plant Desk)', raisedDate: '2026-10-21 10:15 AM' },
  { id: 'TCK-02', ticketNumber: 'TCK-2026-084', distributorId: 'a02g800000DCme5AAD', category: 'Delivery Delay', priority: 'Critical', subject: 'Truck dispatch delay for Weekly Secondary Beat', description: 'Primary vehicle #MH-04-AZ-2021 arrived 6 hours late, causing beat departure delays.', status: 'Under Review', assignedOfficer: 'Logistics Desk', raisedDate: '2026-10-19 02:40 PM' }
];

const SEED_RETURNS = [
  { id: 'RET-01', returnNumber: 'RET-2026-031', distributorId: 'a02g800000DCme5AAD', outletName: 'Gupta Supermarket', outletCode: 'RET-1001', productName: 'Parle-G Original Glucose Biscuit', batchNo: 'B2608-01', quantity: 15, returnReason: 'Damaged Packaging', status: 'Pending Review', value: 322.5, requestDate: '2026-10-20' }
];

const SEED_ASSETS = [
  { id: 'AST-01', assetNumber: 'AST-FRZ-092', distributorId: 'a02g800000DCme5AAD', assetName: 'Parle Visicooler 350L (Single Glass Door)', category: 'Visicooler', placedOutletName: 'Gupta Supermarket', outletCode: 'RET-1001', serialNumber: 'VC-350L-2025-9921', installationDate: '2025-06-15', status: 'Operational', lastServiceDate: '2026-09-10', serviceRemarks: 'Cooling gas checked, regular maintenance OK' }
];

const getStored = (key, fallback) => {
  try {
    const val = localStorage.getItem(key);
    return val ? JSON.parse(val) : fallback;
  } catch (_) {
    return fallback;
  }
};

const setStored = (key, val) => {
  try {
    localStorage.setItem(key, JSON.stringify(val));
  } catch (_) {}
};

export class DMSDataService {
  // 1. Multi-Distributor Selection & Live Salesforce Sync
  static getActiveDistributorId() {
    return localStorage.getItem(STORAGE_KEYS.ACTIVE_DIST_ID) || 'a02g800000DCme5AAD';
  }

  static setActiveDistributorId(distributorId) {
    localStorage.setItem(STORAGE_KEYS.ACTIVE_DIST_ID, distributorId);
  }

  // Fetch all distributors dynamically from Salesforce REST (via Vite Proxy)
  static async syncDistributorsFromSalesforce() {
    try {
      const res = await fetch('/api/salesforce/services/apexrest/api/v1/dms/distributors');
      if (res.ok) {
        const json = await res.json();
        if (json && json.success && Array.isArray(json.data) && json.data.length > 0) {
          // Merge with UI metadata like beats and SRs
          const sfDistributors = json.data.map(d => {
            const existingSeed = SEED_DISTRIBUTORS.find(s => s.id === d.id) || {};
            return {
              id: d.id,
              code: d.code || existingSeed.code || 'DIST-CODE',
              name: d.name,
              status: d.status || 'Active',
              creditLimit: d.creditLimit ?? existingSeed.creditLimit ?? 500000,
              currentOutstanding: d.currentOutstanding ?? existingSeed.currentOutstanding ?? 0,
              defaultWarehouseName: d.defaultWarehouseName || existingSeed.defaultWarehouseName || 'Central Depot',
              gstin: d.gstin || existingSeed.gstin || '27AABCT0000L1Z0',
              area: existingSeed.area || 'Regional Operating Zone',
              phone: existingSeed.phone || '+91 98000 00000',
              email: existingSeed.email || 'ops@distributor.com',
              salesReps: existingSeed.salesReps || [
                { id: `SR-${d.id.substring(d.id.length - 2)}`, name: 'Field Sales Executive', code: 'EMP-SR-01', phone: '+91 98112 33441', email: 'sales@dist.com', monthlyTarget: 400000, achievedAmount: 320000, strikeRate: 85.0, status: 'Active' }
              ],
              beats: existingSeed.beats || [
                { id: `BEAT-${d.id.substring(d.id.length - 2)}`, name: 'Main City Beat Route', code: 'BT-01', dayOfWeek: 'Monday', assignedSR: 'Field Sales Executive' }
              ]
            };
          });
          setStored(STORAGE_KEYS.DISTRIBUTORS_CACHE, sfDistributors);
          return sfDistributors;
        }
      }
    } catch (e) {
      console.warn('Live Salesforce distributors fetch error, using local cache:', e);
    }
    return this.getAllDistributors();
  }

  static getAllDistributors() {
    return getStored(STORAGE_KEYS.DISTRIBUTORS_CACHE, SEED_DISTRIBUTORS);
  }

  static getDistributor() {
    const list = this.getAllDistributors();
    const activeId = this.getActiveDistributorId();
    return list.find(d => d.id === activeId) || list[0] || SEED_DISTRIBUTORS[0];
  }

  // 2. Retailer Outlets (Filtered by Active Distributor)
  static async syncRetailersFromSalesforce() {
    try {
      const res = await fetch('/api/salesforce/services/apexrest/api/v1/dms/retailers');
      if (res.ok) {
        const json = await res.json();
        if (json && json.success && Array.isArray(json.data) && json.data.length > 0) {
          const sfOutlets = json.data.map(r => ({
            id: r.id,
            code: r.code || 'RET-000',
            name: r.name,
            shopName: r.shopName || r.name,
            ownerName: r.name,
            ownerPhone: r.ownerPhone || '+91 98000 00000',
            address: `${r.shopName || r.name}, Market Hub`,
            primaryDistributorId: r.primaryDistributorId,
            primaryDistributorName: r.primaryDistributorName,
            beatName: 'Assigned Beat Route',
            assignedSRName: 'Field Sales Rep',
            creditLimit: r.creditLimit ?? 50000,
            outstandingBalance: r.outstandingBalance ?? 0,
            creditHold: r.creditHold || false,
            status: r.creditHold ? 'Inactive / Needs Attention' : 'Active Buyer',
            lastOrderDate: '2026-10-21',
            monthlyOrderCount: 4
          }));
          setStored(STORAGE_KEYS.OUTLETS_CACHE, sfOutlets);
          return sfOutlets;
        }
      }
    } catch (e) {
      console.warn('Live Salesforce retailers fetch error, using local cache:', e);
    }
    return getStored(STORAGE_KEYS.OUTLETS_CACHE, SEED_OUTLETS);
  }

  static getRetailerOutlets() {
    const all = getStored(STORAGE_KEYS.OUTLETS_CACHE, SEED_OUTLETS);
    const activeDistId = this.getActiveDistributorId();
    // Return all outlets assigned to this distributor, or all unassigned outlets if none
    const assigned = all.filter(o => o.primaryDistributorId === activeDistId);
    return assigned.length > 0 ? assigned : all;
  }

  // 3. Orders (Filtered by Active Distributor)
  static async syncOrdersFromSalesforce() {
    try {
      const res = await fetch('/api/salesforce/services/apexrest/api/v1/dms/orders');
      if (res.ok) {
        const json = await res.json();
        if (json && json.success && Array.isArray(json.data) && json.data.length > 0) {
          const sfOrders = json.data.map(o => ({
            id: o.id,
            orderNumber: o.orderNumber || o.name || `ORD-${o.id.substring(o.id.length - 4)}`,
            retailerId: o.retailerId,
            retailerName: o.retailerName || 'Retail Shop',
            retailerShopName: o.retailerShopName || o.retailerName || 'Retail Shop',
            primaryDistributorId: o.primaryDistributorId,
            primaryDistributorName: o.primaryDistributorName,
            salesExecutiveName: o.salesExecutiveName || 'Field Sales Rep',
            orderDate: o.orderDate ? new Date(o.orderDate).toLocaleString() : '2026-10-22',
            status: o.status || 'Submitted',
            totalAmount: o.totalAmount || 0,
            paymentMethod: 'Credit Terms',
            paymentStatus: o.status === 'Dispatched' ? 'Paid' : 'Pending',
            items: (o.items || []).map((li, idx) => ({
              id: li.id || `LI-${idx}`,
              productId: li.productId,
              productName: li.productName || 'Parle Product',
              productCode: li.productCode || 'SKU',
              quantity: li.quantity || 1,
              unitPrice: li.unitPrice || 0,
              lineTotal: li.lineTotal || (li.quantity * li.unitPrice),
              fulfillmentStatus: li.fulfillmentStatus || 'Pending'
            }))
          }));
          setStored(STORAGE_KEYS.ORDERS_CACHE, sfOrders);
          return sfOrders;
        }
      }
    } catch (e) {
      console.warn('Live Salesforce orders fetch error, using local cache:', e);
    }
    return getStored(STORAGE_KEYS.ORDERS_CACHE, SEED_ORDERS);
  }

  static getOrders() {
    const all = getStored(STORAGE_KEYS.ORDERS_CACHE, SEED_ORDERS);
    const activeDistId = this.getActiveDistributorId();
    const filtered = all.filter(o => o.primaryDistributorId === activeDistId);
    return filtered.length > 0 ? filtered : all;
  }

  static async updateOrderStatus(orderId, newStatus) {
    const orders = getStored(STORAGE_KEYS.ORDERS_CACHE, SEED_ORDERS);
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
    setStored(STORAGE_KEYS.ORDERS_CACHE, updated);

    // Call Salesforce Fulfill API if Dispatched
    if (newStatus === 'Dispatched') {
      try {
        await fetch('/api/salesforce/services/apexrest/api/v1/dms/orders/fulfill', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ orderId })
        });
      } catch (err) {
        console.warn('Salesforce fulfill API call skipped:', err);
      }
    }

    return updated;
  }

  // 4. Stock & Inventory (Filtered by Active Distributor)
  static async syncInventoryFromSalesforce() {
    try {
      const res = await fetch('/api/salesforce/services/apexrest/api/v1/dms/inventory');
      if (res.ok) {
        const json = await res.json();
        if (json && json.success && Array.isArray(json.data) && json.data.length > 0) {
          const sfStock = json.data.map(i => ({
            id: i.id,
            warehouseId: i.warehouseId,
            warehouseName: i.warehouseName || 'Main Depot',
            productName: i.productName || 'Product',
            productCode: i.productCode || 'SKU',
            batchNo: 'B2610-SF',
            expiryDate: '2027-04-30',
            physicalStock: i.physicalStock || 0,
            reservedStock: i.reservedStock || 0,
            availableStock: i.availableStock || 0,
            unit: 'Units',
            status: (i.availableStock || 0) > 50 ? 'In Stock' : 'Low Stock'
          }));
          setStored(STORAGE_KEYS.STOCK_CACHE, sfStock);
          return sfStock;
        }
      }
    } catch (e) {
      console.warn('Live Salesforce inventory fetch error, using local cache:', e);
    }
    return getStored(STORAGE_KEYS.STOCK_CACHE, SEED_STOCK);
  }

  static getStockHeld() {
    const all = getStored(STORAGE_KEYS.STOCK_CACHE, SEED_STOCK);
    const activeDist = this.getDistributor();
    const filtered = all.filter(s => s.distributorId === activeDist.id || s.warehouseName === activeDist.defaultWarehouseName);
    return filtered.length > 0 ? filtered : all;
  }

  static getStockMovements() {
    return getStored(STORAGE_KEYS.MOVEMENTS, [
      { id: 'MOV-01', movementDate: '2026-10-21 11:30 AM', type: 'STOCK_OUT_SALE', referenceNumber: 'ORD-20261005-001', productName: 'Parle-G Original Glucose Biscuit', batchNo: 'B2610-A1', quantityDelta: -200, entityName: 'Gupta Supermarket', notes: 'Dispatched to shop', resultingStock: 850 },
      { id: 'MOV-02', movementDate: '2026-10-20 09:00 AM', type: 'STOCK_IN_GRN', referenceNumber: 'GRN-PO-9021', productName: 'Parle-G Original Glucose Biscuit', batchNo: 'B2610-A1', quantityDelta: 500, entityName: 'Parle Central Plant', notes: 'Primary supply received', resultingStock: 1050 }
    ]);
  }

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

    setStored(STORAGE_KEYS.STOCK_CACHE, updatedStocks);

    // Record movement
    const movements = this.getStockMovements();
    movements.unshift({
      id: `MOV-${Date.now()}`,
      movementDate: new Date().toLocaleString(),
      type: 'STOCK_IN_GRN',
      referenceNumber: `GRN-${Date.now().toString().substring(7)}`,
      productName: entry.productName,
      batchNo: entry.batchNo,
      quantityDelta: entry.quantity,
      entityName: 'Factory Central Plant',
      notes: `Primary GRN received for PO #${entry.poNumber}`,
      resultingStock: currentStock
    });
    setStored(STORAGE_KEYS.MOVEMENTS, movements);

    return { success: true, newStock: currentStock };
  }

  // 5. Ticket Management
  static getTickets() {
    const all = getStored(STORAGE_KEYS.TICKETS, SEED_TICKETS);
    const activeDistId = this.getActiveDistributorId();
    const filtered = all.filter(t => t.distributorId === activeDistId);
    return filtered.length > 0 ? filtered : all;
  }

  static createTicket(ticket) {
    const tickets = getStored(STORAGE_KEYS.TICKETS, SEED_TICKETS);
    const activeDistId = this.getActiveDistributorId();
    const newTicket = {
      id: `TCK-${Date.now()}`,
      ticketNumber: `TCK-2026-${(tickets.length + 50).toString().padStart(3, '0')}`,
      distributorId: activeDistId,
      raisedDate: new Date().toLocaleString(),
      status: 'Open',
      assignedOfficer: 'DO Desk Assigned',
      ...ticket
    };
    tickets.unshift(newTicket);
    setStored(STORAGE_KEYS.TICKETS, tickets);
    return newTicket;
  }

  static updateTicketStatus(ticketId, newStatus, notes, rejectionReason) {
    const tickets = getStored(STORAGE_KEYS.TICKETS, SEED_TICKETS);
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
    setStored(STORAGE_KEYS.TICKETS, updated);
    return updated;
  }

  // 6. Returns & Assets
  static getReturns() {
    const all = getStored(STORAGE_KEYS.RETURNS, SEED_RETURNS);
    const activeDistId = this.getActiveDistributorId();
    const filtered = all.filter(r => r.distributorId === activeDistId);
    return filtered.length > 0 ? filtered : all;
  }

  static updateReturnStatus(returnId, newStatus) {
    const returns = getStored(STORAGE_KEYS.RETURNS, SEED_RETURNS);
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
    setStored(STORAGE_KEYS.RETURNS, updated);
    return updated;
  }

  static getAssets() {
    const all = getStored(STORAGE_KEYS.ASSETS, SEED_ASSETS);
    const activeDistId = this.getActiveDistributorId();
    const filtered = all.filter(a => a.distributorId === activeDistId);
    return filtered.length > 0 ? filtered : all;
  }

  static updateAssetStatus(assetId, newStatus, remarks) {
    const assets = getStored(STORAGE_KEYS.ASSETS, SEED_ASSETS);
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
    setStored(STORAGE_KEYS.ASSETS, updated);
    return updated;
  }

  // 7. Dashboards & Reports
  static getSalesVsTarget() {
    const dist = this.getDistributor();
    const srMetrics = (dist.salesReps || []).map(sr => ({
      srName: `${sr.name} (${sr.code})`,
      target: sr.monthlyTarget || 400000,
      actual: sr.achievedAmount || 350000,
      achievementPct: sr.monthlyTarget ? Math.round((sr.achievedAmount / sr.monthlyTarget) * 1000) / 10 : 85.0,
      lastMonthActual: Math.round((sr.achievedAmount || 350000) * 0.9),
      growthPct: 10.5
    }));

    return {
      period: 'October 2026 (Month-to-Date)',
      distributorName: dist.name,
      srMetrics: srMetrics.length > 0 ? srMetrics : [
        { srName: 'Rahul Sharma', target: 450000, actual: 395000, achievementPct: 87.7, lastMonthActual: 360000, growthPct: 9.7 }
      ],
      productMetrics: [
        { category: 'Biscuits', productName: 'Parle-G Original Glucose', target: 350000, actual: 320000, achievementPct: 91.4 },
        { category: 'Crackers', productName: 'Monaco Classic Crackers', target: 220000, actual: 195000, achievementPct: 88.6 },
        { category: 'Cookies', productName: 'Hide & Seek Chocolate Chip', target: 180000, actual: 165000, achievementPct: 91.6 }
      ]
    };
  }

  static getBeatProductivity() {
    const dist = this.getDistributor();
    return (dist.beats || []).map((b, idx) => ({
      beatName: b.name,
      assignedSR: b.assignedSR || 'Sales Rep',
      totalPlannedShops: 12 + idx,
      visitedShops: 12 + idx,
      billedOrders: 10 + idx,
      strikeRatePct: Math.round(((10 + idx) / (12 + idx)) * 100),
      totalOrderValue: 75000 + (idx * 6000)
    }));
  }

  static getOutletCoverage() {
    const outlets = this.getRetailerOutlets();
    const active = outlets.filter(o => o.status === 'Active Buyer').length;
    const inactive = outlets.filter(o => o.status === 'Inactive / Needs Attention');

    return {
      totalOutlets: outlets.length,
      activeBuyers: active,
      inactiveOutlets: inactive.length,
      coveragePct: outlets.length > 0 ? Math.round((active / outlets.length) * 100) : 100,
      inactiveList: inactive.map(o => ({
        outletName: o.name,
        beatName: o.beatName,
        assignedSR: o.assignedSRName,
        daysSinceLastOrder: 35,
        ownerPhone: o.ownerPhone
      }))
    };
  }
}
