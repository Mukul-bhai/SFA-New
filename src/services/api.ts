import type { Distributor, Warehouse, Retailer, InventoryItem, Order, OrderSubmissionResponse, OverviewStats } from '../types';

// Fallback in-memory state matching Salesforce seed data
let distributors: Distributor[] = [
  {
    id: 'a02g800000DBHIzAAP',
    code: 'DIST-PRI-001',
    name: 'Apex Traders Primary',
    status: 'Active',
    creditLimit: 500000,
    currentOutstanding: 120000,
    defaultWarehouseId: 'a0Eg8000006L3UeEAK',
    defaultWarehouseName: 'Primary Central Depot A'
  },
  {
    id: 'a02g800000DBHJ0AAP',
    code: 'DIST-BAK-002',
    name: 'Zenith Logistics Backup',
    status: 'Active',
    creditLimit: 300000,
    currentOutstanding: 45000,
    defaultWarehouseId: 'a0Eg8000006L3UfEAK',
    defaultWarehouseName: 'Backup Regional Depot B'
  }
];

let warehouses: Warehouse[] = [
  {
    id: 'a0Eg8000006L3UeEAK',
    code: 'WH-PRI-A',
    name: 'Primary Central Depot A',
    distributorId: 'a02g800000DBHIzAAP',
    distributorName: 'Apex Traders Primary',
    isActive: true,
    address: 'Plot 42, Industrial Area Phase 1, Mumbai'
  },
  {
    id: 'a0Eg8000006L3UfEAK',
    code: 'WH-BAK-B',
    name: 'Backup Regional Depot B',
    distributorId: 'a02g800000DBHJ0AAP',
    distributorName: 'Zenith Logistics Backup',
    isActive: true,
    address: 'Warehouse Hub 9, Ring Road, Pune'
  }
];

let retailers: Retailer[] = [
  {
    id: 'a0Bg800000QEBHZEA5',
    code: 'RET-1001',
    name: 'Gupta Supermarket',
    shopName: 'Gupta Kirana & General Store',
    ownerPhone: '+91 98765 43210',
    primaryDistributorId: 'a02g800000DBHIzAAP',
    primaryDistributorName: 'Apex Traders Primary',
    backupDistributorId: 'a02g800000DBHJ0AAP',
    backupDistributorName: 'Zenith Logistics Backup',
    allowBackupFulfillment: true,
    creditLimit: 50000,
    outstandingBalance: 12000,
    creditHold: false,
    latitude: 19.0760,
    longitude: 72.8777
  },
  {
    id: 'a0Bg800000QEBHaEAP',
    code: 'RET-1002',
    name: 'Sharma Departmental Store',
    shopName: 'Sharma Daily Needs',
    ownerPhone: '+91 98111 22233',
    primaryDistributorId: 'a02g800000DBHIzAAP',
    primaryDistributorName: 'Apex Traders Primary',
    allowBackupFulfillment: false,
    creditLimit: 25000,
    outstandingBalance: 27500,
    creditHold: true,
    latitude: 18.5204,
    longitude: 73.8567
  }
];

let inventory: InventoryItem[] = [
  {
    id: 'a04g800000SHMP01',
    warehouseId: 'a0Eg8000006L3UeEAK',
    warehouseName: 'Primary Central Depot A',
    productId: '01tg8000006yXorAAE',
    productName: 'Herbal Shampoo 200ml',
    productCode: 'SHMP-200',
    physicalStock: 150,
    reservedStock: 80,
    blockedStock: 0,
    damagedStock: 0,
    expiredStock: 0,
    availableStock: 70
  },
  {
    id: 'a04g800000SHMP02',
    warehouseId: 'a0Eg8000006L3UfEAK',
    warehouseName: 'Backup Regional Depot B',
    productId: '01tg8000006yXorAAE',
    productName: 'Herbal Shampoo 200ml',
    productCode: 'SHMP-200',
    physicalStock: 200,
    reservedStock: 20,
    blockedStock: 0,
    damagedStock: 0,
    expiredStock: 0,
    availableStock: 180
  },
  {
    id: 'a04g800000SOAP01',
    warehouseId: 'a0Eg8000006L3UeEAK',
    warehouseName: 'Primary Central Depot A',
    productId: '01tg8000006yXosAAE',
    productName: 'Neem Glow Soap 125g',
    productCode: 'SOAP-125',
    physicalStock: 300,
    reservedStock: 50,
    blockedStock: 10,
    damagedStock: 5,
    expiredStock: 0,
    availableStock: 235
  }
];

let orders: Order[] = [];

export const SalesforceApiService = {
  // Live connection status tracker
  isLive: true,
  lastSyncTime: new Date().toLocaleTimeString(),
  orgId: '00Dg800000LROVBEA5',

  getOverview: async (): Promise<OverviewStats> => {
    try {
      const res = await fetch('/api/salesforce/services/apexrest/api/v1/dms/overview');
      if (res.ok) {
        const json = await res.json();
        if (json.success && json.data) {
          SalesforceApiService.isLive = true;
          SalesforceApiService.lastSyncTime = new Date().toLocaleTimeString();
          if (json.data.recentOrders) {
            orders = json.data.recentOrders;
          }
          return json.data as OverviewStats;
        }
      }
    } catch (e) {
      console.warn('Live Salesforce call failed, using fallback cache:', e);
    }

    SalesforceApiService.isLive = false;
    return {
      distributorCount: distributors.length,
      warehouseCount: warehouses.length,
      retailerCount: retailers.length,
      productCount: 20,
      totalInventoryUnits: inventory.reduce((acc, i) => acc + i.physicalStock, 0),
      totalReservedUnits: inventory.reduce((acc, i) => acc + i.reservedStock, 0),
      totalAvailableUnits: inventory.reduce((acc, i) => acc + (i.physicalStock - i.reservedStock), 0),
      totalOrderCount: orders.length,
      pendingFulfillmentCount: orders.filter(o => o.status === 'Submitted' || o.status === 'Allocated').length,
      recentOrders: orders
    };
  },

  getDistributors: async (): Promise<Distributor[]> => {
    try {
      const res = await fetch('/api/salesforce/services/apexrest/api/v1/dms/distributors');
      if (res.ok) {
        const json = await res.json();
        if (json.success && Array.isArray(json.data)) {
          distributors = json.data;
          SalesforceApiService.isLive = true;
          return distributors;
        }
      }
    } catch (e) {
      console.warn('Fetch distributors from Salesforce failed:', e);
    }
    return [...distributors];
  },

  getWarehouses: async (): Promise<Warehouse[]> => {
    try {
      const res = await fetch('/api/salesforce/services/apexrest/api/v1/dms/warehouses');
      if (res.ok) {
        const json = await res.json();
        if (json.success && Array.isArray(json.data)) {
          warehouses = json.data;
          SalesforceApiService.isLive = true;
          return warehouses;
        }
      }
    } catch (e) {
      console.warn('Fetch warehouses from Salesforce failed:', e);
    }
    return [...warehouses];
  },

  getRetailers: async (): Promise<Retailer[]> => {
    try {
      const res = await fetch('/api/salesforce/services/apexrest/api/v1/dms/retailers');
      if (res.ok) {
        const json = await res.json();
        if (json.success && Array.isArray(json.data)) {
          retailers = json.data;
          SalesforceApiService.isLive = true;
          return retailers;
        }
      }
    } catch (e) {
      console.warn('Fetch retailers from Salesforce failed:', e);
    }
    return [...retailers];
  },

  getInventory: async (): Promise<InventoryItem[]> => {
    try {
      const res = await fetch('/api/salesforce/services/apexrest/api/v1/dms/inventory');
      if (res.ok) {
        const json = await res.json();
        if (json.success && Array.isArray(json.data)) {
          inventory = json.data;
          SalesforceApiService.isLive = true;
          return inventory;
        }
      }
    } catch (e) {
      console.warn('Fetch inventory from Salesforce failed:', e);
    }
    return inventory.map(item => ({
      ...item,
      availableStock: item.physicalStock - (item.reservedStock + item.blockedStock + item.damagedStock + item.expiredStock)
    }));
  },

  getOrders: async (): Promise<Order[]> => {
    try {
      const res = await fetch('/api/salesforce/services/apexrest/api/v1/dms/orders');
      if (res.ok) {
        const json = await res.json();
        if (json.success && Array.isArray(json.data)) {
          orders = json.data;
          SalesforceApiService.isLive = true;
          return orders;
        }
      }
    } catch (e) {
      console.warn('Fetch orders from Salesforce failed:', e);
    }
    return [...orders];
  },

  fulfillOrder: async (orderId: string): Promise<any> => {
    try {
      const res = await fetch('/api/salesforce/services/apexrest/api/v1/dms/orders/fulfill', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ orderId })
      });
      if (res.ok) {
        const json = await res.json();
        if (json.success) {
          // Refresh orders & inventory
          await SalesforceApiService.getOrders();
          await SalesforceApiService.getInventory();
          return json.data;
        }
      }
    } catch (e) {
      console.warn('Fulfill order live call failed:', e);
    }

    // Local fallback update
    const ord = orders.find(o => o.id === orderId);
    if (ord) {
      ord.status = 'Dispatched';
    }
    return { orderId, status: 'Dispatched' };
  },

  updateOrderStatus: async (orderId: string, newStatus: Order['status']): Promise<Order> => {
    if (newStatus === 'Dispatched') {
      await SalesforceApiService.fulfillOrder(orderId);
    }
    const orderIndex = orders.findIndex(o => o.id === orderId);
    if (orderIndex !== -1) {
      orders[orderIndex].status = newStatus;
      return orders[orderIndex];
    }
    throw new Error('Order not found');
  },

  // Direct Apex REST Order Reservation
  // Submits live to Salesforce: urlMapping='/api/v1/orders/reserve-and-submit'
  reserveAndSubmitOrder: async (payload: {
    retailerId: string;
    productId: string;
    quantity: number;
    unitPrice: number;
    idempotencyKey: string;
  }): Promise<OrderSubmissionResponse> => {
    try {
      const res = await fetch('/api/salesforce/services/apexrest/api/v1/orders/reserve-and-submit', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          idempotencyKey: payload.idempotencyKey,
          retailerId: payload.retailerId,
          items: [
            {
              productId: payload.productId,
              quantity: payload.quantity,
              unitPrice: payload.unitPrice
            }
          ]
        })
      });

      if (res.ok) {
        const json = await res.json();
        if (json.success) {
          // Re-fetch live orders and inventory
          await SalesforceApiService.getOrders();
          await SalesforceApiService.getInventory();
          return {
            success: true,
            orderId: json.orderId,
            status: json.status || 'Submitted',
            message: json.message || 'Order placed and reserved on Salesforce Core.',
            allocations: json.allocations || []
          };
        } else {
          return {
            success: false,
            message: json.message || 'Order rejected by Salesforce business logic.',
            allocations: []
          };
        }
      }
    } catch (e) {
      console.warn('Live submit order failed, using local simulation:', e);
    }

    // Local simulation fallback
    const retailer = retailers.find(r => r.id === payload.retailerId);
    if (!retailer) {
      return { success: false, message: 'Retailer not found', allocations: [] };
    }
    if (retailer.creditHold) {
      return {
        success: false,
        message: `Credit Hold Active: Outstanding balance (₹${retailer.outstandingBalance}) exceeds credit limit (₹${retailer.creditLimit}).`,
        allocations: []
      };
    }

    const primaryDist = distributors.find(d => d.id === retailer.primaryDistributorId);
    const primaryInv = inventory.find(
      i => i.warehouseId === primaryDist?.defaultWarehouseId && i.productId === payload.productId
    );
    const backupDist = retailer.allowBackupFulfillment && retailer.backupDistributorId
      ? distributors.find(d => d.id === retailer.backupDistributorId)
      : null;
    const backupInv = backupDist
      ? inventory.find(i => i.warehouseId === backupDist.defaultWarehouseId && i.productId === payload.productId)
      : null;

    let requested = payload.quantity;
    let allocatedPrimary = 0;
    let allocatedBackup = 0;

    const primaryAvail = primaryInv
      ? primaryInv.physicalStock - (primaryInv.reservedStock + primaryInv.blockedStock + primaryInv.damagedStock + primaryInv.expiredStock)
      : 0;

    if (primaryAvail > 0) {
      allocatedPrimary = Math.min(primaryAvail, requested);
      primaryInv!.reservedStock += allocatedPrimary;
      requested -= allocatedPrimary;
    }

    if (requested > 0 && backupInv) {
      const backupAvail = backupInv.physicalStock - (backupInv.reservedStock + backupInv.blockedStock + backupInv.damagedStock + backupInv.expiredStock);
      if (backupAvail > 0) {
        allocatedBackup = Math.min(backupAvail, requested);
        backupInv.reservedStock += allocatedBackup;
        requested -= allocatedBackup;
      }
    }

    const newOrderId = `a08g800000${Date.now().toString().slice(-6)}`;
    const newLines: Order['items'] = [];

    if (allocatedPrimary > 0) {
      newLines.push({
        id: `LINE_${Date.now()}_1`,
        productId: payload.productId,
        productName: primaryInv?.productName || 'Product',
        quantity: allocatedPrimary,
        unitPrice: payload.unitPrice,
        lineTotal: allocatedPrimary * payload.unitPrice,
        fulfillingDistributorId: primaryDist?.id || '',
        fulfillingDistributorName: primaryDist?.name || 'Primary Distributor',
        fulfillmentStatus: 'Allocated_Primary'
      });
    }

    if (allocatedBackup > 0) {
      newLines.push({
        id: `LINE_${Date.now()}_2`,
        productId: payload.productId,
        productName: backupInv?.productName || 'Product',
        quantity: allocatedBackup,
        unitPrice: payload.unitPrice,
        lineTotal: allocatedBackup * payload.unitPrice,
        fulfillingDistributorId: backupDist?.id || '',
        fulfillingDistributorName: backupDist?.name || 'Backup Distributor',
        fulfillmentStatus: 'Allocated_Backup'
      });
    }

    const newOrder: Order = {
      id: newOrderId,
      orderNumber: `ORD-${Date.now().toString().slice(-4)}`,
      idempotencyKey: payload.idempotencyKey,
      retailerId: retailer.id,
      retailerName: retailer.name,
      salesExecutiveName: 'Mukul Yadav (Logged-In User)',
      orderDate: new Date().toISOString(),
      status: 'Submitted',
      totalAmount: (allocatedPrimary + allocatedBackup + requested) * payload.unitPrice,
      items: newLines
    };

    orders.unshift(newOrder);

    return {
      success: true,
      orderId: newOrderId,
      status: 'Submitted',
      message: requested === 0
        ? `Order placed successfully! ${allocatedBackup > 0 ? 'Split between Primary & Backup Distributors.' : 'Fulfilled completely by Primary Distributor.'}`
        : `Partial fulfillment: ${allocatedPrimary + allocatedBackup} units allocated, ${requested} backordered due to distributor stock limits.`,
      allocations: [
        {
          productId: payload.productId,
          requestedQty: payload.quantity,
          allocatedQty: allocatedPrimary + allocatedBackup,
          backorderQty: requested,
          fulfillingDistributorId: primaryDist?.id || '',
          fulfillmentType: allocatedBackup > 0 ? 'SPLIT_PRIMARY_BACKUP' : 'PRIMARY'
        }
      ]
    };
  }
};
