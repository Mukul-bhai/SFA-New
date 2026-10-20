// ==========================================
// DMS PORTAL CORE DOMAIN DATA MODELS
// ==========================================

// 1. Distributor & SR Management
export interface SalesRepresentative {
  id: string;
  name: string;
  code: string;
  phone: string;
  email: string;
  assignedBeats: string[];
  totalAssignedOutlets: number;
  monthlyTarget: number;
  achievedAmount: number;
  strikeRate: number; // Percentage
  status: 'Active' | 'On Leave';
}

export interface Beat {
  id: string;
  name: string;
  code: string;
  dayOfWeek: string;
  assignedSR: string;
  outletCount: number;
}

export interface Distributor {
  id: string;
  code: string;
  name: string;
  area: string;
  phone: string;
  email: string;
  status: 'Active' | 'Suspended';
  creditLimit: number;
  currentOutstanding: number;
  defaultWarehouseName: string;
  salesReps: SalesRepresentative[];
  beats: Beat[];
  totalOutlets: number;
}

export interface RetailerOutlet {
  id: string;
  code: string;
  name: string;
  shopName: string;
  ownerName: string;
  ownerPhone: string;
  address: string;
  beatName: string;
  assignedSRName: string;
  creditLimit: number;
  outstandingBalance: number;
  creditHold: boolean;
  status: 'Active Buyer' | 'Inactive / Needs Attention';
  lastOrderDate: string;
  monthlyOrderCount: number;
}

// 2. Order Management & Sync
export interface OrderLineItem {
  id: string;
  productId: string;
  productName: string;
  quantity: number;
  unitPrice: number;
  lineTotal: number;
}

export interface DMSOrder {
  id: string;
  orderNumber: string;
  orderDate: string;
  distributorName: string;
  retailerName: string;
  retailerCode: string;
  salesRepName: string;
  status: 'Submitted' | 'Confirmed' | 'Dispatched' | 'Delivered' | 'Cancelled';
  totalAmount: number;
  totalUnits: number;
  source: 'SFA Mobile App' | 'Direct DMS';
  items: OrderLineItem[];
  invoiceNumber?: string;
  dispatchDate?: string;
}

// 3. Stock & Inventory (The 4 Processes)
export interface StockHeldItem {
  id: string;
  productId: string;
  productName: string;
  productCode: string;
  category: string;
  physicalStock: number;
  reservedStock: number;
  availableStock: number;
  batchNo: string;
  manufacturingDate: string;
  expiryDate: string;
  daysToExpiry: number;
  unitPrice: number;
  mrp: number;
  status: 'In Stock' | 'Low Stock' | 'Out of Stock' | 'Near Expiry';
  velocity: 'Fast Moving' | 'Normal' | 'Slow Moving';
}

export interface StockMovement {
  id: string;
  movementDate: string;
  type: 'STOCK_IN_GRN' | 'STOCK_OUT_SALE' | 'RETURN_RESTOCK' | 'ADJUSTMENT_DAMAGE';
  referenceNumber: string; // GRN-xxx or INV-xxx or RET-xxx
  productName: string;
  batchNo: string;
  quantityDelta: number; // + for In, - for Out
  resultingStock: number;
  entityName: string; // Company Plant, Outlet Name, etc.
  notes: string;
}

// 4. Ticket Management
export interface DMSTicket {
  id: string;
  ticketNumber: string;
  distributorName: string;
  category: 'Product Issue' | 'Portal Issue' | 'Delivery Delay' | 'Billing Dispute';
  subject: string;
  description: string;
  priority: 'Critical' | 'High' | 'Medium' | 'Low';
  status: 'Open' | 'In Progress' | 'Closed' | 'Rejected';
  raisedDate: string;
  rejectionReason?: string;
  assignedOfficer?: string;
  resolutionNotes?: string;
  closedDate?: string;
}

// 5. Returns & Asset Management
export interface ProductReturn {
  id: string;
  returnNumber: string;
  retailerName: string;
  distributorName: string;
  productName: string;
  quantity: number;
  reason: 'Damaged Packaging' | 'Expired Stock' | 'Quality Defect' | 'Wrong Delivery';
  condition: 'Salable' | 'Damaged/Scrap' | 'Pending Inspection';
  status: 'Pending Approval' | 'Approved & Restocked' | 'Scrapped' | 'Rejected';
  requestDate: string;
  approvedDate?: string;
  creditNoteNumber?: string;
}

export interface CompanyAsset {
  id: string;
  assetCode: string;
  assetType: 'Visicooler / Freezer' | 'Deep Freezer' | 'POSM Display Rack' | 'Neon Signboard';
  modelNumber: string;
  serialNumber: string;
  assignedLocation: string; // Outlet or Distributor Warehouse
  assignedType: 'Retail Outlet' | 'Distributor Warehouse';
  installedDate: string;
  status: 'Operational' | 'Damaged' | 'Missing' | 'Needs Service';
  lastServiceDate: string;
  serviceRemarks?: string;
}

// 6. Dashboards & Reports
export interface SalesVsTargetReport {
  period: string;
  srMetrics: {
    srName: string;
    target: number;
    actual: number;
    achievementPct: number;
    lastMonthActual: number;
    growthPct: number;
  }[];
  productMetrics: {
    category: string;
    productName: string;
    target: number;
    actual: number;
    achievementPct: number;
  }[];
}

export interface BeatProductivityReport {
  beatName: string;
  assignedSR: string;
  totalPlannedShops: number;
  visitedShops: number;
  billedOrders: number;
  strikeRatePct: number;
  totalOrderValue: number;
}

export interface OutletCoverageReport {
  totalOutlets: number;
  activeBuyers: number;
  inactiveOutlets: number;
  coveragePct: number;
  inactiveList: {
    outletName: string;
    beatName: string;
    assignedSR: string;
    daysSinceLastOrder: number;
    ownerPhone: string;
  }[];
}
