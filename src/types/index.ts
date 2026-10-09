export interface Distributor {
  id: string;
  code: string;
  name: string;
  status: 'Active' | 'Suspended' | 'Onboarding';
  creditLimit: number;
  currentOutstanding: number;
  defaultWarehouseId?: string;
  defaultWarehouseName?: string;
}

export interface Warehouse {
  id: string;
  code: string;
  name: string;
  distributorId: string;
  distributorName: string;
  isActive: boolean;
  address: string;
}

export interface Retailer {
  id: string;
  code: string;
  name: string;
  shopName: string;
  ownerPhone: string;
  primaryDistributorId: string;
  primaryDistributorName: string;
  backupDistributorId?: string;
  backupDistributorName?: string;
  allowBackupFulfillment: boolean;
  creditLimit: number;
  outstandingBalance: number;
  creditHold: boolean;
  latitude: number;
  longitude: number;
}

export interface InventoryItem {
  id: string;
  warehouseId: string;
  warehouseName: string;
  productId: string;
  productName: string;
  productCode: string;
  physicalStock: number;
  reservedStock: number;
  blockedStock: number;
  damagedStock: number;
  expiredStock: number;
  availableStock: number; // Formula: Physical - (Reserved + Blocked + Damaged + Expired)
}

export interface OrderLine {
  id: string;
  productId: string;
  productName: string;
  quantity: number;
  unitPrice: number;
  lineTotal: number;
  fulfillingDistributorId: string;
  fulfillingDistributorName: string;
  fulfillmentStatus: 'Allocated_Primary' | 'Allocated_Backup' | 'Backordered' | 'Cancelled';
}

export interface Order {
  id: string;
  orderNumber: string;
  idempotencyKey: string;
  retailerId: string;
  retailerName: string;
  salesExecutiveName: string;
  orderDate: string;
  status: 'Draft' | 'Submitted' | 'Allocated' | 'Approved' | 'Picking' | 'Packed' | 'Dispatched' | 'Delivered' | 'Cancelled';
  totalAmount: number;
  items: OrderLine[];
}

export interface AllocationDetail {
  productId: string;
  requestedQty: number;
  allocatedQty: number;
  backorderQty: number;
  fulfillingDistributorId: string;
  fulfillmentType: 'PRIMARY' | 'SPLIT_PRIMARY_BACKUP' | 'PARTIAL_BACKORDER';
}

export interface OrderSubmissionResponse {
  success: boolean;
  orderId?: string;
  status?: string;
  message: string;
  allocations: AllocationDetail[];
}

export interface OverviewStats {
  distributorCount: number;
  warehouseCount: number;
  retailerCount: number;
  productCount: number;
  totalInventoryUnits: number;
  totalReservedUnits: number;
  totalAvailableUnits: number;
  totalOrderCount: number;
  pendingFulfillmentCount: number;
  recentOrders: Order[];
}

