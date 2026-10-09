import { useState, useEffect } from 'react';
import { 
  Building2, 
  Store, 
  Package, 
  ShoppingCart, 
  TrendingUp, 
  AlertTriangle, 
  CheckCircle2, 
  DollarSign, 
  Play, 
  RefreshCw, 
  Layers, 
  ShieldCheck, 
  Sliders
} from 'lucide-react';
import { SalesforceApiService } from './services/api';
import type { Distributor, Retailer, InventoryItem, Order, OrderSubmissionResponse } from './types';

export default function App() {
  const [activeTab, setActiveTab] = useState<'dashboard' | 'orders' | 'inventory' | 'distributors' | 'retailers' | 'simulator'>('dashboard');
  const [distributors, setDistributors] = useState<Distributor[]>([]);
  const [retailers, setRetailers] = useState<Retailer[]>([]);
  const [inventory, setInventory] = useState<InventoryItem[]>([]);
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);

  // Simulator State
  const [simRetailerId, setSimRetailerId] = useState('003_RET_1');
  const [simQty, setSimQty] = useState(100);
  const [simResult, setSimResult] = useState<OrderSubmissionResponse | null>(null);
  const [simRunning, setSimRunning] = useState(false);

  const loadData = async () => {
    setLoading(true);
    try {
      const [d, r, inv, o] = await Promise.all([
        SalesforceApiService.getDistributors(),
        SalesforceApiService.getRetailers(),
        SalesforceApiService.getInventory(),
        SalesforceApiService.getOrders()
      ]);
      setDistributors(d);
      setRetailers(r);
      setInventory(inv);
      setOrders(o);
      if (r.length > 0 && (!simRetailerId || simRetailerId === '003_RET_1')) {
        setSimRetailerId(r[0].id);
      }
    } catch (e) {
      console.error('Error loading Salesforce data:', e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleStatusChange = async (orderId: string, newStatus: Order['status']) => {
    await SalesforceApiService.updateOrderStatus(orderId, newStatus);
    await loadData();
  };

  const runSimulation = async () => {
    setSimRunning(true);
    setSimResult(null);
    try {
      const selectedProdId = inventory[0]?.productId || '01tg8000006yXorAAE';
      const resp = await SalesforceApiService.reserveAndSubmitOrder({
        retailerId: simRetailerId || retailers[0]?.id || '',
        productId: selectedProdId,
        quantity: Number(simQty),
        unitPrice: 120,
        idempotencyKey: `SIM_UUID_${Date.now()}`
      });
      setSimResult(resp);
      await loadData();
    } catch (err: any) {
      alert(err.message);
    } finally {
      setSimRunning(false);
    }
  };

  const totalRevenue = orders.reduce((acc, o) => acc + o.totalAmount, 0);
  const pendingOrders = orders.filter(o => o.status !== 'Delivered' && o.status !== 'Cancelled').length;
  const totalPhysicalStock = inventory.reduce((acc, i) => acc + i.physicalStock, 0);
  const totalAvailableStock = inventory.reduce((acc, i) => acc + i.availableStock, 0);

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 flex flex-col font-sans">
      {/* Top Header */}
      <header className="bg-slate-900 text-white border-b border-slate-800 px-6 py-4 flex flex-wrap justify-between items-center shadow-md">
        <div className="flex items-center space-x-3">
          <div className="bg-blue-600 p-2 rounded-lg">
            <Building2 className="w-6 h-6 text-white" />
          </div>
          <div>
            <h1 className="text-xl font-bold tracking-tight">Enterprise DMS Portal</h1>
            <p className="text-xs text-slate-400">Distributor Management System • Powered by Salesforce Core Cloud</p>
          </div>
        </div>

        <div className="flex items-center space-x-4 mt-3 sm:mt-0">
          <div className="flex items-center space-x-2 bg-emerald-950/80 border border-emerald-500/30 px-3 py-1.5 rounded-full text-xs text-emerald-400">
            <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
            <span>Salesforce Org: <b>orgfarm-03c6654659-dev-ed</b></span>
          </div>

          <div className="flex items-center space-x-2 bg-slate-800 border border-slate-700 px-3 py-1.5 rounded-lg text-xs">
            <ShieldCheck className="w-4 h-4 text-blue-400" />
            <span>Role: <b>National Sales & Operations Admin</b></span>
          </div>
        </div>
      </header>

      {/* Main Navigation Bar */}
      <nav className="bg-white border-b border-slate-200 px-6 flex space-x-2 overflow-x-auto shadow-sm">
        {[
          { id: 'dashboard', label: 'Overview Dashboard', icon: TrendingUp },
          { id: 'orders', label: `Orders (${orders.length})`, icon: ShoppingCart },
          { id: 'inventory', label: 'Multi-Echelon Stock', icon: Layers },
          { id: 'distributors', label: `Distributors (${distributors.length})`, icon: Building2 },
          { id: 'retailers', label: `Retailers (${retailers.length})`, icon: Store },
          { id: 'simulator', label: 'Allocation Simulator', icon: Sliders },
        ].map((tab) => {
          const Icon = tab.icon;
          const active = activeTab === tab.id;
          return (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id as any)}
              className={`flex items-center space-x-2 py-3.5 px-4 text-sm font-semibold border-b-2 transition-colors whitespace-nowrap ${
                active 
                  ? 'border-blue-600 text-blue-600' 
                  : 'border-transparent text-slate-600 hover:text-slate-900 hover:border-slate-300'
              }`}
            >
              <Icon className="w-4 h-4" />
              <span>{tab.label}</span>
            </button>
          );
        })}
      </nav>

      {/* Main Content Area */}
      <main className="flex-1 p-6 max-w-7xl w-full mx-auto">
        {loading ? (
          <div className="flex items-center justify-center py-20">
            <RefreshCw className="w-8 h-8 text-blue-600 animate-spin" />
            <span className="ml-3 font-medium text-slate-600">Loading Salesforce Live Records...</span>
          </div>
        ) : (
          <>
            {/* TAB: DASHBOARD */}
            {activeTab === 'dashboard' && (
              <div className="space-y-6">
                {/* Metric Summary Cards */}
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
                  <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm flex items-center justify-between">
                    <div>
                      <p className="text-xs font-semibold text-slate-500 uppercase">Total Net Revenue</p>
                      <h3 className="text-2xl font-bold text-slate-900 mt-1">₹{totalRevenue.toLocaleString()}</h3>
                      <p className="text-xs text-emerald-600 mt-1 font-medium">↑ 14.8% vs last month</p>
                    </div>
                    <div className="p-3 bg-blue-50 text-blue-600 rounded-xl">
                      <DollarSign className="w-6 h-6" />
                    </div>
                  </div>

                  <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm flex items-center justify-between">
                    <div>
                      <p className="text-xs font-semibold text-slate-500 uppercase">Active Orders</p>
                      <h3 className="text-2xl font-bold text-slate-900 mt-1">{pendingOrders}</h3>
                      <p className="text-xs text-amber-600 mt-1 font-medium">{orders.filter(o => o.status === 'Submitted').length} pending picking</p>
                    </div>
                    <div className="p-3 bg-amber-50 text-amber-600 rounded-xl">
                      <ShoppingCart className="w-6 h-6" />
                    </div>
                  </div>

                  <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm flex items-center justify-between">
                    <div>
                      <p className="text-xs font-semibold text-slate-500 uppercase">Available Units</p>
                      <h3 className="text-2xl font-bold text-slate-900 mt-1">{totalAvailableStock}</h3>
                      <p className="text-xs text-slate-500 mt-1 font-medium">Physical on-hand: {totalPhysicalStock}</p>
                    </div>
                    <div className="p-3 bg-emerald-50 text-emerald-600 rounded-xl">
                      <Package className="w-6 h-6" />
                    </div>
                  </div>

                  <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm flex items-center justify-between">
                    <div>
                      <p className="text-xs font-semibold text-slate-500 uppercase">Serviced Retailers</p>
                      <h3 className="text-2xl font-bold text-slate-900 mt-1">{retailers.length}</h3>
                      <p className="text-xs text-red-600 mt-1 font-medium">{retailers.filter(r => r.creditHold).length} on Credit Hold</p>
                    </div>
                    <div className="p-3 bg-purple-50 text-purple-600 rounded-xl">
                      <Store className="w-6 h-6" />
                    </div>
                  </div>
                </div>

                {/* Architecture Highlights & Live Status */}
                <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                  <div className="lg:col-span-2 bg-white rounded-xl border border-slate-200 p-6 shadow-sm">
                    <h2 className="text-base font-bold text-slate-900 flex items-center space-x-2">
                      <CheckCircle2 className="w-5 h-5 text-emerald-600" />
                      <span>Salesforce Single Source of Truth Architecture</span>
                    </h2>
                    <p className="text-sm text-slate-600 mt-1">
                      Both the <b>Flutter SFA Mobile App</b> and this <b>React DMS Portal</b> transact directly against Salesforce Core Cloud using custom Apex REST services.
                    </p>

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mt-5">
                      <div className="border border-slate-100 bg-slate-50 p-4 rounded-lg">
                        <h4 className="font-semibold text-sm text-slate-800">Concurrency Locking Engine</h4>
                        <p className="text-xs text-slate-600 mt-1">
                          Protected by Apex <code>SELECT ... FOR UPDATE</code>. Simultaneous orders from field reps lock inventory rows at the database level, preventing overselling.
                        </p>
                      </div>

                      <div className="border border-slate-100 bg-slate-50 p-4 rounded-lg">
                        <h4 className="font-semibold text-sm text-slate-800">Multi-Tier Distributor Fallback</h4>
                        <p className="text-xs text-slate-600 mt-1">
                          Evaluates Primary Distributor $\rightarrow$ Backup Distributor $\rightarrow$ Split Allocation $\rightarrow$ Backorder automatically without manual dispatcher intervention.
                        </p>
                      </div>
                    </div>
                  </div>

                  <div className="bg-white rounded-xl border border-slate-200 p-6 shadow-sm">
                    <h3 className="font-bold text-sm text-slate-900 mb-3">Quick Actions</h3>
                    <div className="space-y-2.5">
                      <button
                        onClick={() => setActiveTab('simulator')}
                        className="w-full text-left p-3 rounded-lg border border-blue-200 bg-blue-50/60 hover:bg-blue-100/70 transition flex items-center justify-between"
                      >
                        <div>
                          <div className="text-xs font-bold text-blue-900">Run Allocation Simulator</div>
                          <div className="text-xs text-blue-700">Test Primary $\rightarrow$ Backup split live</div>
                        </div>
                        <Play className="w-4 h-4 text-blue-600" />
                      </button>

                      <button
                        onClick={() => setActiveTab('inventory')}
                        className="w-full text-left p-3 rounded-lg border border-slate-200 hover:bg-slate-50 transition flex items-center justify-between"
                      >
                        <div>
                          <div className="text-xs font-bold text-slate-800">Inspect 7-Bucket Stock</div>
                          <div className="text-xs text-slate-500">View physical vs available balances</div>
                        </div>
                        <Layers className="w-4 h-4 text-slate-600" />
                      </button>

                      <button
                        onClick={loadData}
                        className="w-full text-left p-3 rounded-lg border border-slate-200 hover:bg-slate-50 transition flex items-center justify-between"
                      >
                        <div>
                          <div className="text-xs font-bold text-slate-800">Refresh Live Data</div>
                          <div className="text-xs text-slate-500">Fetch latest database state</div>
                        </div>
                        <RefreshCw className="w-4 h-4 text-slate-600" />
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* TAB: ORDERS */}
            {activeTab === 'orders' && (
              <div className="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
                <div className="px-6 py-4 border-b border-slate-200 flex justify-between items-center">
                  <div>
                    <h2 className="text-base font-bold text-slate-900">Sales Order Fulfillment Pipeline</h2>
                    <p className="text-xs text-slate-500">Orders placed by field sales reps via Flutter SFA app</p>
                  </div>
                  <button 
                    onClick={loadData}
                    className="p-2 border border-slate-200 rounded-lg hover:bg-slate-50 text-slate-600"
                  >
                    <RefreshCw className="w-4 h-4" />
                  </button>
                </div>

                <div className="overflow-x-auto">
                  <table className="w-full text-left text-sm text-slate-600">
                    <thead className="bg-slate-50 text-xs uppercase font-semibold text-slate-500 border-b border-slate-200">
                      <tr>
                        <th className="px-6 py-3">Order Number</th>
                        <th className="px-6 py-3">Retailer</th>
                        <th className="px-6 py-3">Sales Rep</th>
                        <th className="px-6 py-3">Items & Fulfillment Split</th>
                        <th className="px-6 py-3">Total (₹)</th>
                        <th className="px-6 py-3">Status</th>
                        <th className="px-6 py-3 text-right">Actions</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-200">
                      {orders.map((ord) => (
                        <tr key={ord.id} className="hover:bg-slate-50/70 transition">
                          <td className="px-6 py-4 font-bold text-slate-900">
                            {ord.orderNumber}
                            <div className="text-xs text-slate-400 font-normal">{new Date(ord.orderDate).toLocaleTimeString()}</div>
                          </td>
                          <td className="px-6 py-4">
                            <div className="font-medium text-slate-900">{ord.retailerName}</div>
                          </td>
                          <td className="px-6 py-4 text-xs">
                            {ord.salesExecutiveName}
                          </td>
                          <td className="px-6 py-4">
                            <div className="space-y-1.5">
                              {ord.items.map((it) => (
                                <div key={it.id} className="text-xs flex items-center space-x-2">
                                  <span className="font-medium text-slate-800">{it.quantity}x {it.productName}</span>
                                  <span className={`px-2 py-0.5 rounded text-[10px] font-semibold ${
                                    it.fulfillmentStatus === 'Allocated_Primary' ? 'bg-blue-100 text-blue-800' :
                                    it.fulfillmentStatus === 'Allocated_Backup' ? 'bg-purple-100 text-purple-800' :
                                    it.fulfillmentStatus === 'Backordered' ? 'bg-amber-100 text-amber-800' :
                                    'bg-slate-100 text-slate-800'
                                  }`}>
                                    {it.fulfillmentStatus.replace('_', ' ')} • {it.fulfillingDistributorName}
                                  </span>
                                </div>
                              ))}
                            </div>
                          </td>
                          <td className="px-6 py-4 font-bold text-slate-900">
                            ₹{ord.totalAmount.toLocaleString()}
                          </td>
                          <td className="px-6 py-4">
                            <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold ${
                              ord.status === 'Delivered' ? 'bg-emerald-100 text-emerald-800' :
                              ord.status === 'Dispatched' ? 'bg-indigo-100 text-indigo-800' :
                              ord.status === 'Picking' ? 'bg-amber-100 text-amber-800' :
                              ord.status === 'Allocated' ? 'bg-blue-100 text-blue-800' :
                              'bg-slate-100 text-slate-800'
                            }`}>
                              {ord.status}
                            </span>
                          </td>
                          <td className="px-6 py-4 text-right space-x-1.5">
                            {ord.status === 'Submitted' && (
                              <button
                                onClick={() => handleStatusChange(ord.id, 'Picking')}
                                className="px-3 py-1 bg-blue-600 text-white rounded text-xs font-semibold hover:bg-blue-700"
                              >
                                Start Picking
                              </button>
                            )}
                            {ord.status === 'Picking' && (
                              <button
                                onClick={() => handleStatusChange(ord.id, 'Dispatched')}
                                className="px-3 py-1 bg-indigo-600 text-white rounded text-xs font-semibold hover:bg-indigo-700"
                              >
                                Mark Dispatched
                              </button>
                            )}
                            {ord.status === 'Dispatched' && (
                              <button
                                onClick={() => handleStatusChange(ord.id, 'Delivered')}
                                className="px-3 py-1 bg-emerald-600 text-white rounded text-xs font-semibold hover:bg-emerald-700"
                              >
                                Confirm Delivery
                              </button>
                            )}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            )}

            {/* TAB: INVENTORY */}
            {activeTab === 'inventory' && (
              <div className="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
                <div className="px-6 py-4 border-b border-slate-200">
                  <h2 className="text-base font-bold text-slate-900">Multi-Echelon 7-Bucket Stock Ledger</h2>
                  <p className="text-xs text-slate-500">
                    Formula: <code>Available = Physical - (Reserved + Blocked + Damaged + Expired)</code>
                  </p>
                </div>

                <div className="overflow-x-auto">
                  <table className="w-full text-left text-sm text-slate-600">
                    <thead className="bg-slate-50 text-xs uppercase font-semibold text-slate-500 border-b border-slate-200">
                      <tr>
                        <th className="px-6 py-3">Warehouse / Depot</th>
                        <th className="px-6 py-3">Product SKU</th>
                        <th className="px-6 py-3 text-center">Physical</th>
                        <th className="px-6 py-3 text-center text-amber-700 bg-amber-50/50">Reserved</th>
                        <th className="px-6 py-3 text-center">Blocked</th>
                        <th className="px-6 py-3 text-center">Damaged</th>
                        <th className="px-6 py-3 text-center">Expired</th>
                        <th className="px-6 py-3 text-center font-bold text-emerald-700 bg-emerald-50/50">Available</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-200">
                      {inventory.map((inv) => (
                        <tr key={inv.id} className="hover:bg-slate-50/70 transition">
                          <td className="px-6 py-4 font-semibold text-slate-800">
                            {inv.warehouseName}
                          </td>
                          <td className="px-6 py-4">
                            <div className="font-bold text-slate-900">{inv.productName}</div>
                            <div className="text-xs text-slate-400 font-mono">{inv.productCode}</div>
                          </td>
                          <td className="px-6 py-4 text-center font-semibold text-slate-700">{inv.physicalStock}</td>
                          <td className="px-6 py-4 text-center font-bold text-amber-700 bg-amber-50/30">{inv.reservedStock}</td>
                          <td className="px-6 py-4 text-center text-slate-500">{inv.blockedStock}</td>
                          <td className="px-6 py-4 text-center text-slate-500">{inv.damagedStock}</td>
                          <td className="px-6 py-4 text-center text-slate-500">{inv.expiredStock}</td>
                          <td className="px-6 py-4 text-center font-black text-emerald-700 bg-emerald-50/30 text-base">
                            {inv.availableStock}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            )}

            {/* TAB: DISTRIBUTORS */}
            {activeTab === 'distributors' && (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {distributors.map((dist) => (
                  <div key={dist.id} className="bg-white rounded-xl border border-slate-200 p-6 shadow-sm">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center space-x-3">
                        <div className="p-3 bg-blue-50 text-blue-600 rounded-lg">
                          <Building2 className="w-6 h-6" />
                        </div>
                        <div>
                          <h3 className="font-bold text-slate-900">{dist.name}</h3>
                          <span className="text-xs font-mono text-slate-400">{dist.code}</span>
                        </div>
                      </div>
                      <span className="px-2.5 py-1 rounded-full text-xs font-semibold bg-emerald-100 text-emerald-800">
                        {dist.status}
                      </span>
                    </div>

                    <div className="mt-5 grid grid-cols-2 gap-4 text-xs border-t border-slate-100 pt-4">
                      <div>
                        <span className="text-slate-400 block">Default Depot</span>
                        <span className="font-semibold text-slate-800">{dist.defaultWarehouseName}</span>
                      </div>
                      <div>
                        <span className="text-slate-400 block">Credit Limit</span>
                        <span className="font-semibold text-slate-800">₹{dist.creditLimit.toLocaleString()}</span>
                      </div>
                      <div>
                        <span className="text-slate-400 block">Current Outstanding</span>
                        <span className="font-semibold text-slate-800">₹{dist.currentOutstanding.toLocaleString()}</span>
                      </div>
                      <div>
                        <span className="text-slate-400 block">Credit Health</span>
                        <span className="font-semibold text-emerald-600">
                          {((1 - dist.currentOutstanding / dist.creditLimit) * 100).toFixed(0)}% available
                        </span>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}

            {/* TAB: RETAILERS */}
            {activeTab === 'retailers' && (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {retailers.map((ret) => (
                  <div key={ret.id} className="bg-white rounded-xl border border-slate-200 p-6 shadow-sm">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center space-x-3">
                        <div className="p-3 bg-purple-50 text-purple-600 rounded-lg">
                          <Store className="w-6 h-6" />
                        </div>
                        <div>
                          <h3 className="font-bold text-slate-900">{ret.name}</h3>
                          <span className="text-xs text-slate-400">{ret.shopName}</span>
                        </div>
                      </div>
                      {ret.creditHold ? (
                        <span className="px-2.5 py-1 rounded-full text-xs font-semibold bg-red-100 text-red-800 flex items-center space-x-1">
                          <AlertTriangle className="w-3 h-3" />
                          <span>Credit Hold</span>
                        </span>
                      ) : (
                        <span className="px-2.5 py-1 rounded-full text-xs font-semibold bg-emerald-100 text-emerald-800">
                          Active
                        </span>
                      )}
                    </div>

                    <div className="mt-4 space-y-2 text-xs border-t border-slate-100 pt-3">
                      <div className="flex justify-between">
                        <span className="text-slate-400">Primary Supplier:</span>
                        <span className="font-semibold text-blue-700">{ret.primaryDistributorName}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-slate-400">Backup Supplier:</span>
                        <span className="font-semibold text-purple-700">
                          {ret.backupDistributorName || 'None assigned'}
                        </span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-slate-400">Backup Fallback Allowed:</span>
                        <span className="font-semibold text-slate-800">{ret.allowBackupFulfillment ? 'Yes' : 'No'}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-slate-400">Outstanding Balance:</span>
                        <span className={`font-semibold ${ret.outstandingBalance > ret.creditLimit ? 'text-red-600' : 'text-slate-800'}`}>
                          ₹{ret.outstandingBalance.toLocaleString()} / ₹{ret.creditLimit.toLocaleString()}
                        </span>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}

            {/* TAB: SIMULATOR */}
            {activeTab === 'simulator' && (
              <div className="max-w-3xl mx-auto bg-white rounded-xl border border-slate-200 p-8 shadow-sm">
                <div className="flex items-center space-x-3 mb-4">
                  <div className="p-3 bg-blue-600 text-white rounded-xl">
                    <Sliders className="w-6 h-6" />
                  </div>
                  <div>
                    <h2 className="text-lg font-bold text-slate-900">Live Allocation & Concurrency Test Bench</h2>
                    <p className="text-xs text-slate-500">
                      Executes the deployed <code>OrderReservationRestService.submitOrder()</code> logic in real-time.
                    </p>
                  </div>
                </div>

                <div className="bg-slate-50 border border-slate-200 p-4 rounded-lg mb-6 text-xs text-slate-600">
                  <b>Current Scenario:</b><br />
                  • Primary Distributor (Apex Traders) has <b>70 units available</b> of Herbal Shampoo.<br />
                  • Backup Distributor (Zenith Logistics) has <b>180 units available</b>.<br />
                  • If you request <b>100 units</b> for Gupta Supermarket (Backup Allowed), it will automatically reserve <b>70 from Primary</b> and <b>30 from Backup</b>!
                </div>

                <div className="space-y-4">
                  <div>
                    <label className="block text-xs font-bold text-slate-700 mb-1">Select Retailer</label>
                    <select
                      value={simRetailerId}
                      onChange={(e) => setSimRetailerId(e.target.value)}
                      className="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm bg-white"
                    >
                      {retailers.map((r) => (
                        <option key={r.id} value={r.id}>
                          {r.name} ({r.primaryDistributorName}) {r.creditHold ? '— [CREDIT HOLD]' : ''}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-slate-700 mb-1">
                      Requested Quantity (Herbal Shampoo @ ₹120)
                    </label>
                    <input
                      type="number"
                      value={simQty}
                      onChange={(e) => setSimQty(Number(e.target.value))}
                      className="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm bg-white"
                    />
                  </div>

                  <button
                    onClick={runSimulation}
                    disabled={simRunning}
                    className="w-full py-3 bg-blue-600 text-white font-bold rounded-lg hover:bg-blue-700 transition flex items-center justify-center space-x-2"
                  >
                    {simRunning ? (
                      <>
                        <RefreshCw className="w-4 h-4 animate-spin" />
                        <span>Reserving Stock in Salesforce...</span>
                      </>
                    ) : (
                      <>
                        <Play className="w-4 h-4" />
                        <span>Submit Live Order with Concurrency Lock</span>
                      </>
                    )}
                  </button>
                </div>

                {simResult && (
                  <div className={`mt-6 p-5 rounded-xl border text-sm ${
                    simResult.success ? 'bg-emerald-50 border-emerald-300 text-emerald-900' : 'bg-red-50 border-red-300 text-red-900'
                  }`}>
                    <div className="font-bold flex items-center space-x-2">
                      {simResult.success ? <CheckCircle2 className="w-5 h-5 text-emerald-600" /> : <AlertTriangle className="w-5 h-5 text-red-600" />}
                      <span>{simResult.success ? 'Order Processed & Inventory Reserved!' : 'Order Denied by Salesforce'}</span>
                    </div>
                    <p className="mt-1 text-xs">{simResult.message}</p>

                    {simResult.allocations.length > 0 && (
                      <div className="mt-4 border-t border-emerald-200/60 pt-3">
                        <div className="font-bold text-xs uppercase mb-2">Allocation Breakdown:</div>
                        {simResult.allocations.map((a, i) => (
                          <div key={i} className="text-xs space-y-1">
                            <div>• Total Requested: <b>{a.requestedQty} units</b></div>
                            <div>• Total Allocated: <b>{a.allocatedQty} units</b></div>
                            {a.backorderQty > 0 && <div className="text-amber-700">• Backordered: <b>{a.backorderQty} units</b></div>}
                            <div>• Strategy Used: <b>{a.fulfillmentType}</b></div>
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                )}
              </div>
            )}
          </>
        )}
      </main>
    </div>
  );
}
