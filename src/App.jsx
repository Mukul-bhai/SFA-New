import { useState, useEffect } from 'react';
import {
  Building2,
  Users,
  Store,
  ShoppingCart,
  Package,
  ArrowDownToLine,
  ArrowUpFromLine,
  FileText,
  LifeBuoy,
  RotateCcw,
  ShieldCheck,
  BarChart3,
  TrendingUp,
  CheckCircle2,
  Search,
  Plus,
  RefreshCw,
  Phone,
  Calendar,
  Eye,
  Truck
} from 'lucide-react';
import { DMSDataService } from './services/api';

export default function App() {
  // Navigation Tabs: 6 Core Modules from Script
  const [activeTab, setActiveTab] = useState('distributor_outlets');

  // Sub-tabs
  const [invSubTab, setInvSubTab] = useState('stock_held');
  const [returnAssetSubTab, setReturnAssetSubTab] = useState('returns');

  // State Collections
  const [distributor, setDistributor] = useState(DMSDataService.getDistributor());
  const [outlets, setOutlets] = useState([]);
  const [orders, setOrders] = useState([]);
  const [stockHeld, setStockHeld] = useState([]);
  const [stockMovements, setStockMovements] = useState([]);
  const [tickets, setTickets] = useState([]);
  const [returns, setReturns] = useState([]);
  const [assets, setAssets] = useState([]);

  // Reports
  const [salesReport, setSalesReport] = useState(DMSDataService.getSalesVsTarget());
  const [beatReport, setBeatReport] = useState(DMSDataService.getBeatProductivity());
  const [coverageReport, setCoverageReport] = useState(DMSDataService.getOutletCoverage());

  // Search & Filter State
  const [outletSearch, setOutletSearch] = useState('');
  const [selectedBeatFilter, setSelectedBeatFilter] = useState('All');
  const [selectedTicketFilter, setSelectedTicketFilter] = useState('All');

  // Modals
  const [selectedOrderForModal, setSelectedOrderForModal] = useState(null);
  const [showGRNModal, setShowGRNModal] = useState(false);
  const [showNewTicketModal, setShowNewTicketModal] = useState(false);

  // Form State: GRN
  const [grnProduct, setGrnProduct] = useState('Parle-G 100g Glucose Biscuit');
  const [grnQty, setGrnQty] = useState(200);
  const [grnBatch, setGrnBatch] = useState('B2610-GRN9');
  const [grnExpiry, setGrnExpiry] = useState('2027-04-30');
  const [grnPO, setGrnPO] = useState('PO-2026-9021');

  // Form State: Ticket
  const [ticketCategory, setTicketCategory] = useState('Product Issue');
  const [ticketPriority, setTicketPriority] = useState('High');
  const [ticketSubject, setTicketSubject] = useState('');
  const [ticketDesc, setTicketDesc] = useState('');

  // Toast / Notification
  const [notification, setNotification] = useState(null);

  const triggerToast = (msg) => {
    setNotification(msg);
    setTimeout(() => setNotification(null), 3500);
  };

  const reloadData = () => {
    setDistributor(DMSDataService.getDistributor());
    setOutlets(DMSDataService.getRetailerOutlets());
    setOrders(DMSDataService.getOrders());
    setStockHeld(DMSDataService.getStockHeld());
    setStockMovements(DMSDataService.getStockMovements());
    setTickets(DMSDataService.getTickets());
    setReturns(DMSDataService.getReturns());
    setAssets(DMSDataService.getAssets());
    setSalesReport(DMSDataService.getSalesVsTarget());
    setBeatReport(DMSDataService.getBeatProductivity());
    setCoverageReport(DMSDataService.getOutletCoverage());
  };

  useEffect(() => {
    reloadData();
  }, []);

  // Handlers
  const handleOrderStatusUpdate = (orderId, status) => {
    DMSDataService.updateOrderStatus(orderId, status);
    reloadData();
    triggerToast(`Order status updated to ${status}. Stock movements recorded.`);
  };

  const handleCreateGRN = (e) => {
    e.preventDefault();
    if (grnQty <= 0) return;
    DMSDataService.createGRN({
      productName: grnProduct,
      quantity: Number(grnQty),
      batchNo: grnBatch,
      expiryDate: grnExpiry,
      poNumber: grnPO
    });
    setShowGRNModal(false);
    reloadData();
    triggerToast(`GRN Created successfully! Added ${grnQty} units to live stock.`);
  };

  const handleCreateTicket = (e) => {
    e.preventDefault();
    if (!ticketSubject.trim()) return;
    DMSDataService.createTicket({
      distributorName: distributor.name,
      category: ticketCategory,
      priority: ticketPriority,
      subject: ticketSubject,
      description: ticketDesc
    });
    setShowNewTicketModal(false);
    setTicketSubject('');
    setTicketDesc('');
    reloadData();
    triggerToast('Support ticket raised and dispatched to DO desk!');
  };

  const handleUpdateTicketStatus = (ticketId, status, notes, reason) => {
    DMSDataService.updateTicketStatus(ticketId, status, notes, reason);
    reloadData();
    triggerToast(`Ticket updated to ${status}`);
  };

  const handleApproveReturn = (returnId) => {
    DMSDataService.updateReturnStatus(returnId, 'Approved & Restocked');
    reloadData();
    triggerToast('Return approved! Salable items restocked & Credit Note generated.');
  };

  const handleAssetServiceUpdate = (assetId, status, remarks) => {
    DMSDataService.updateAssetStatus(assetId, status, remarks);
    reloadData();
    triggerToast(`Asset status updated to ${status}`);
  };

  // Filtered Outlets
  const filteredOutlets = outlets.filter(o => {
    const matchesSearch =
      o.name.toLowerCase().includes(outletSearch.toLowerCase()) ||
      o.shopName.toLowerCase().includes(outletSearch.toLowerCase()) ||
      o.code.toLowerCase().includes(outletSearch.toLowerCase()) ||
      o.assignedSRName.toLowerCase().includes(outletSearch.toLowerCase());
    const matchesBeat = selectedBeatFilter === 'All' || o.beatName === selectedBeatFilter;
    return matchesSearch && matchesBeat;
  });

  // Filtered Tickets
  const filteredTickets = tickets.filter(t => {
    if (selectedTicketFilter === 'All') return true;
    return t.status === selectedTicketFilter;
  });

  // Quick Stats
  const totalStockUnits = stockHeld.reduce((acc, s) => acc + s.availableStock, 0);
  const totalStockValue = stockHeld.reduce((acc, s) => acc + s.availableStock * s.unitPrice, 0);
  const pendingOrdersCount = orders.filter(o => o.status === 'Submitted' || o.status === 'Confirmed').length;
  const openTicketsCount = tickets.filter(t => t.status === 'Open' || t.status === 'In Progress').length;

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 flex flex-col font-sans">
      {/* Toast Notification */}
      {notification && (
        <div className="fixed top-5 right-5 z-50 bg-slate-900 text-white px-5 py-3 rounded-xl shadow-2xl border border-slate-700 flex items-center space-x-3 transition-all animate-bounce">
          <CheckCircle2 className="w-5 h-5 text-emerald-400" />
          <span className="text-sm font-medium">{notification}</span>
        </div>
      )}

      {/* Top Corporate Navbar */}
      <header className="bg-slate-900 text-white border-b border-slate-800 px-6 py-4 flex flex-wrap justify-between items-center shadow-lg sticky top-0 z-40">
        <div className="flex items-center space-x-3">
          <div className="bg-blue-600 p-2.5 rounded-xl shadow-md">
            <Building2 className="w-6 h-6 text-white" />
          </div>
          <div>
            <div className="flex items-center space-x-2">
              <h1 className="text-xl font-bold tracking-tight text-white">{distributor.name}</h1>
              <span className="text-xs bg-blue-500/20 text-blue-300 border border-blue-500/30 px-2 py-0.5 rounded-full font-mono">
                {distributor.code}
              </span>
            </div>
            <p className="text-xs text-slate-400 flex items-center space-x-2">
              <span>{distributor.area}</span>
              <span>•</span>
              <span>Primary Depot: {distributor.defaultWarehouseName}</span>
            </p>
          </div>
        </div>

        {/* Live Salesforce SFA Sync Pill */}
        <div className="flex items-center space-x-4 mt-3 sm:mt-0">
          <div className="flex items-center space-x-2 bg-emerald-950/60 border border-emerald-500/30 px-3 py-1.5 rounded-full text-xs font-medium text-emerald-400">
            <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
            <span>SFA Mobile & Salesforce Live Synced</span>
          </div>

          <button
            onClick={() => {
              reloadData();
              triggerToast('Refreshed data directly from SFA Cloud sync!');
            }}
            className="p-2 hover:bg-slate-800 rounded-lg text-slate-300 hover:text-white transition"
            title="Refresh DMS Data"
          >
            <RefreshCw className="w-4 h-4" />
          </button>
        </div>
      </header>

      {/* Primary DMS Module Navigation Tabs */}
      <nav className="bg-white border-b border-slate-200 px-6 py-2 flex space-x-1 overflow-x-auto shadow-sm">
        <button
          onClick={() => setActiveTab('distributor_outlets')}
          className={`flex items-center space-x-2 px-4 py-2.5 rounded-lg text-sm font-semibold transition ${
            activeTab === 'distributor_outlets'
              ? 'bg-blue-50 text-blue-700 shadow-sm'
              : 'text-slate-600 hover:bg-slate-100 hover:text-slate-900'
          }`}
        >
          <Users className="w-4 h-4" />
          <span>Distributor & Outlets ({distributor.totalOutlets})</span>
        </button>

        <button
          onClick={() => setActiveTab('orders')}
          className={`flex items-center space-x-2 px-4 py-2.5 rounded-lg text-sm font-semibold transition relative ${
            activeTab === 'orders'
              ? 'bg-blue-50 text-blue-700 shadow-sm'
              : 'text-slate-600 hover:bg-slate-100 hover:text-slate-900'
          }`}
        >
          <ShoppingCart className="w-4 h-4" />
          <span>Orders & Mobile Sync</span>
          {pendingOrdersCount > 0 && (
            <span className="bg-amber-500 text-white text-xs px-2 py-0.5 rounded-full ml-1">
              {pendingOrdersCount}
            </span>
          )}
        </button>

        <button
          onClick={() => setActiveTab('inventory')}
          className={`flex items-center space-x-2 px-4 py-2.5 rounded-lg text-sm font-semibold transition ${
            activeTab === 'inventory'
              ? 'bg-blue-50 text-blue-700 shadow-sm'
              : 'text-slate-600 hover:bg-slate-100 hover:text-slate-900'
          }`}
        >
          <Package className="w-4 h-4" />
          <span>Stock & Inventory (4 Processes)</span>
        </button>

        <button
          onClick={() => setActiveTab('tickets')}
          className={`flex items-center space-x-2 px-4 py-2.5 rounded-lg text-sm font-semibold transition relative ${
            activeTab === 'tickets'
              ? 'bg-blue-50 text-blue-700 shadow-sm'
              : 'text-slate-600 hover:bg-slate-100 hover:text-slate-900'
          }`}
        >
          <LifeBuoy className="w-4 h-4" />
          <span>Tickets ({openTicketsCount} Open)</span>
        </button>

        <button
          onClick={() => setActiveTab('returns_assets')}
          className={`flex items-center space-x-2 px-4 py-2.5 rounded-lg text-sm font-semibold transition ${
            activeTab === 'returns_assets'
              ? 'bg-blue-50 text-blue-700 shadow-sm'
              : 'text-slate-600 hover:bg-slate-100 hover:text-slate-900'
          }`}
        >
          <RotateCcw className="w-4 h-4" />
          <span>Returns & Assets</span>
        </button>

        <button
          onClick={() => setActiveTab('reports')}
          className={`flex items-center space-x-2 px-4 py-2.5 rounded-lg text-sm font-semibold transition ${
            activeTab === 'reports'
              ? 'bg-blue-50 text-blue-700 shadow-sm'
              : 'text-slate-600 hover:bg-slate-100 hover:text-slate-900'
          }`}
        >
          <BarChart3 className="w-4 h-4" />
          <span>Manager Dashboards & Reports</span>
        </button>
      </nav>

      {/* Main Content Area */}
      <main className="flex-1 p-6 max-w-7xl w-full mx-auto space-y-6">
        {/* ========================================================= */}
        {/* MODULE 1: DISTRIBUTOR, SR & OUTLET MANAGEMENT */}
        {/* ========================================================= */}
        {activeTab === 'distributor_outlets' && (
          <div className="space-y-6">
            {/* Header info */}
            <div className="bg-gradient-to-r from-blue-900 to-indigo-900 text-white rounded-2xl p-6 shadow-md flex flex-wrap justify-between items-center">
              <div>
                <span className="text-blue-300 text-xs font-semibold uppercase tracking-wider">
                  Distributor Operations
                </span>
                <h2 className="text-2xl font-bold mt-1">Distributor, SR & 70 Retail Outlets</h2>
                <p className="text-sm text-blue-100 max-w-2xl mt-1">
                  Myfair manages 2 Sales Representatives (SRs), 6 Beat routes, and 70 assigned retail outlets across Mumbai East.
                </p>
              </div>

              <div className="flex space-x-4 mt-4 lg:mt-0">
                <div className="bg-white/10 backdrop-blur-md px-4 py-2 rounded-xl text-center border border-white/10">
                  <span className="text-xs text-blue-200">Total Outlets</span>
                  <div className="text-2xl font-bold">{distributor.totalOutlets}</div>
                </div>
                <div className="bg-white/10 backdrop-blur-md px-4 py-2 rounded-xl text-center border border-white/10">
                  <span className="text-xs text-blue-200">Active SRs</span>
                  <div className="text-2xl font-bold">{distributor.salesReps.length}</div>
                </div>
                <div className="bg-white/10 backdrop-blur-md px-4 py-2 rounded-xl text-center border border-white/10">
                  <span className="text-xs text-blue-200">Total Beats</span>
                  <div className="text-2xl font-bold">{distributor.beats.length}</div>
                </div>
              </div>
            </div>

            {/* Sales Representatives Cards */}
            <div>
              <h3 className="text-md font-bold text-slate-800 flex items-center space-x-2 mb-3">
                <Users className="w-5 h-5 text-blue-600" />
                <span>Assigned Sales Representatives (SRs)</span>
              </h3>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {distributor.salesReps.map(sr => (
                  <div key={sr.id} className="bg-white border border-slate-200 rounded-xl p-5 shadow-sm hover:border-blue-400 transition">
                    <div className="flex justify-between items-start">
                      <div className="flex items-center space-x-3">
                        <div className="w-11 h-11 bg-blue-100 text-blue-700 font-bold rounded-full flex items-center justify-center text-lg">
                          {sr.name.split(' ').map(n => n[0]).join('')}
                        </div>
                        <div>
                          <h4 className="font-bold text-slate-900">{sr.name}</h4>
                          <span className="text-xs text-slate-500 font-mono">{sr.code} • {sr.phone}</span>
                        </div>
                      </div>
                      <span className="text-xs px-2.5 py-1 bg-emerald-100 text-emerald-800 font-semibold rounded-full">
                        {sr.status}
                      </span>
                    </div>

                    <div className="grid grid-cols-3 gap-2 mt-4 pt-4 border-t border-slate-100 text-center">
                      <div className="bg-slate-50 p-2 rounded-lg">
                        <span className="text-xs text-slate-500 block">Outlets</span>
                        <span className="font-bold text-slate-800">{sr.totalAssignedOutlets} Outlets</span>
                      </div>
                      <div className="bg-slate-50 p-2 rounded-lg">
                        <span className="text-xs text-slate-500 block">Target Achieved</span>
                        <span className="font-bold text-emerald-600">
                          {Math.round((sr.achievedAmount / sr.monthlyTarget) * 100)}%
                        </span>
                      </div>
                      <div className="bg-slate-50 p-2 rounded-lg">
                        <span className="text-xs text-slate-500 block">Strike Rate</span>
                        <span className="font-bold text-blue-600">{sr.strikeRate}%</span>
                      </div>
                    </div>

                    <div className="mt-3 text-xs text-slate-600">
                      <span className="font-semibold text-slate-700">Assigned Beats: </span>
                      {sr.assignedBeats.join(' • ')}
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* 70 Retail Outlets Management */}
            <div className="bg-white border border-slate-200 rounded-xl shadow-sm overflow-hidden">
              <div className="p-4 border-b border-slate-200 flex flex-wrap justify-between items-center gap-3">
                <div>
                  <h3 className="font-bold text-slate-900 flex items-center space-x-2">
                    <Store className="w-5 h-5 text-blue-600" />
                    <span>Retail Outlets Network (Showing {filteredOutlets.length} of {outlets.length})</span>
                  </h3>
                  <p className="text-xs text-slate-500">Retail shops under Myfair where SR takes orders using SFA mobile</p>
                </div>

                <div className="flex items-center space-x-3 w-full sm:w-auto">
                  <div className="relative flex-1 sm:w-64">
                    <Search className="w-4 h-4 text-slate-400 absolute left-3 top-2.5" />
                    <input
                      type="text"
                      placeholder="Search Balaji, Gupta, code..."
                      value={outletSearch}
                      onChange={e => setOutletSearch(e.target.value)}
                      className="w-full pl-9 pr-3 py-1.5 text-sm bg-slate-50 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>

                  <select
                    value={selectedBeatFilter}
                    onChange={e => setSelectedBeatFilter(e.target.value)}
                    className="text-sm bg-slate-50 border border-slate-200 rounded-lg px-3 py-1.5 focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="All">All Beats</option>
                    {distributor.beats.map(b => (
                      <option key={b.id} value={b.name}>{b.name}</option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="overflow-x-auto">
                <table className="w-full text-left text-sm text-slate-700">
                  <thead className="bg-slate-100 text-slate-700 text-xs uppercase font-semibold border-b border-slate-200">
                    <tr>
                      <th className="px-4 py-3">Outlet Code & Name</th>
                      <th className="px-4 py-3">Shop & Owner Details</th>
                      <th className="px-4 py-3">Beat / Route</th>
                      <th className="px-4 py-3">Assigned SR</th>
                      <th className="px-4 py-3">Credit Limit / Balance</th>
                      <th className="px-4 py-3">Last Order</th>
                      <th className="px-4 py-3">Status</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                    {filteredOutlets.slice(0, 15).map(outlet => (
                      <tr key={outlet.id} className="hover:bg-slate-50/80 transition">
                        <td className="px-4 py-3">
                          <div className="font-bold text-slate-900">{outlet.name}</div>
                          <span className="text-xs font-mono text-slate-500">{outlet.code}</span>
                        </td>
                        <td className="px-4 py-3">
                          <div className="text-slate-800">{outlet.shopName}</div>
                          <div className="text-xs text-slate-500 flex items-center space-x-1">
                            <Phone className="w-3 h-3" />
                            <span>{outlet.ownerPhone}</span>
                          </div>
                        </td>
                        <td className="px-4 py-3 text-xs font-medium text-slate-700">
                          {outlet.beatName}
                        </td>
                        <td className="px-4 py-3 text-xs font-semibold text-blue-700">
                          {outlet.assignedSRName}
                        </td>
                        <td className="px-4 py-3 text-xs">
                          <div>Limit: ₹{outlet.creditLimit.toLocaleString()}</div>
                          <div className={outlet.creditHold ? 'text-red-600 font-bold' : 'text-slate-600'}>
                            Due: ₹{outlet.outstandingBalance.toLocaleString()}
                          </div>
                        </td>
                        <td className="px-4 py-3 text-xs text-slate-600">
                          {outlet.lastOrderDate}
                        </td>
                        <td className="px-4 py-3">
                          <span
                            className={`text-xs px-2.5 py-1 rounded-full font-semibold ${
                              outlet.status === 'Active Buyer'
                                ? 'bg-emerald-100 text-emerald-800'
                                : 'bg-rose-100 text-rose-800'
                            }`}
                          >
                            {outlet.status}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              {filteredOutlets.length > 15 && (
                <div className="p-3 bg-slate-50 border-t border-slate-200 text-center text-xs text-slate-500">
                  Showing first 15 of {filteredOutlets.length} retail outlets. Use search or beat filter to locate specific stores.
                </div>
              )}
            </div>
          </div>
        )}

        {/* ========================================================= */}
        {/* MODULE 2: ORDER MANAGEMENT & SYNCHRONIZATION */}
        {/* ========================================================= */}
        {activeTab === 'orders' && (
          <div className="space-y-6">
            <div className="bg-white border border-slate-200 rounded-xl p-6 shadow-sm flex flex-wrap justify-between items-center gap-4">
              <div>
                <span className="text-xs font-bold text-blue-600 uppercase tracking-wider">
                  Mobile SFA Integration
                </span>
                <h2 className="text-2xl font-bold text-slate-900 mt-1">Order Management & Sync</h2>
                <p className="text-sm text-slate-500">
                  Orders submitted by Sales Representatives (SRs) in the SFA mobile application synchronize automatically here and into Salesforce.
                </p>
              </div>

              <div className="flex items-center space-x-3">
                <div className="px-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-center">
                  <span className="text-xs text-slate-500">Total Orders</span>
                  <div className="text-xl font-bold text-slate-800">{orders.length}</div>
                </div>
                <div className="px-4 py-2 bg-blue-50 border border-blue-200 rounded-xl text-center">
                  <span className="text-xs text-blue-600">Order Value</span>
                  <div className="text-xl font-bold text-blue-700">
                    ₹{orders.reduce((acc, o) => acc + o.totalAmount, 0).toLocaleString()}
                  </div>
                </div>
              </div>
            </div>

            {/* Orders Table */}
            <div className="bg-white border border-slate-200 rounded-xl shadow-sm overflow-hidden">
              <div className="p-4 border-b border-slate-200 flex justify-between items-center">
                <h3 className="font-bold text-slate-900 flex items-center space-x-2">
                  <ShoppingCart className="w-5 h-5 text-blue-600" />
                  <span>SFA Incoming Orders</span>
                </h3>
                <span className="text-xs text-slate-500 font-mono">DMS Order Dispatch Desk</span>
              </div>

              <div className="overflow-x-auto">
                <table className="w-full text-left text-sm text-slate-700">
                  <thead className="bg-slate-100 text-slate-700 text-xs uppercase font-semibold border-b border-slate-200">
                    <tr>
                      <th className="px-4 py-3">Order # & Date</th>
                      <th className="px-4 py-3">Retail Outlet</th>
                      <th className="px-4 py-3">Sales Rep (SR)</th>
                      <th className="px-4 py-3">Total Amount</th>
                      <th className="px-4 py-3">Status Progression</th>
                      <th className="px-4 py-3 text-right">Actions</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                    {orders.map(order => {
                      const getStatusBadge = () => {
                        switch (order.status) {
                          case 'Submitted':
                            return 'bg-blue-100 text-blue-800 border-blue-200';
                          case 'Confirmed':
                            return 'bg-amber-100 text-amber-800 border-amber-200';
                          case 'Dispatched':
                            return 'bg-purple-100 text-purple-800 border-purple-200';
                          case 'Delivered':
                            return 'bg-emerald-100 text-emerald-800 border-emerald-200';
                          default:
                            return 'bg-slate-100 text-slate-800 border-slate-200';
                        }
                      };

                      return (
                        <tr key={order.id} className="hover:bg-slate-50 transition">
                          <td className="px-4 py-3">
                            <div className="font-bold text-slate-900 font-mono">{order.orderNumber}</div>
                            <div className="text-xs text-slate-500 flex items-center space-x-1">
                              <Calendar className="w-3 h-3" />
                              <span>{order.orderDate}</span>
                            </div>
                            <span className="text-[10px] bg-slate-100 text-slate-600 px-1.5 py-0.5 rounded">
                              {order.source}
                            </span>
                          </td>
                          <td className="px-4 py-3">
                            <div className="font-semibold text-slate-900">{order.retailerName}</div>
                            <span className="text-xs text-slate-500 font-mono">{order.retailerCode}</span>
                          </td>
                          <td className="px-4 py-3 text-xs font-semibold text-blue-700">
                            {order.salesRepName}
                          </td>
                          <td className="px-4 py-3">
                            <div className="font-bold text-slate-900">₹{order.totalAmount.toLocaleString()}</div>
                            <div className="text-xs text-slate-500">{order.totalUnits} Units ({order.items.length} SKUs)</div>
                          </td>
                          <td className="px-4 py-3">
                            <span className={`text-xs px-2.5 py-1 rounded-full font-bold border ${getStatusBadge()}`}>
                              {order.status}
                            </span>
                            {order.dispatchDate && (
                              <div className="text-[10px] text-slate-500 mt-1">
                                Dispatched: {order.dispatchDate}
                              </div>
                            )}
                          </td>
                          <td className="px-4 py-3 text-right space-x-2">
                            <button
                              onClick={() => setSelectedOrderForModal(order)}
                              className="px-2.5 py-1 text-xs bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-lg font-medium inline-flex items-center space-x-1"
                            >
                              <Eye className="w-3.5 h-3.5" />
                              <span>Items</span>
                            </button>

                            {order.status === 'Submitted' && (
                              <button
                                onClick={() => handleOrderStatusUpdate(order.id, 'Confirmed')}
                                className="px-2.5 py-1 text-xs bg-amber-600 hover:bg-amber-700 text-white rounded-lg font-medium"
                              >
                                Confirm
                              </button>
                            )}

                            {order.status === 'Confirmed' && (
                              <button
                                onClick={() => handleOrderStatusUpdate(order.id, 'Dispatched')}
                                className="px-2.5 py-1 text-xs bg-purple-600 hover:bg-purple-700 text-white rounded-lg font-medium inline-flex items-center space-x-1"
                              >
                                <Truck className="w-3.5 h-3.5" />
                                <span>Dispatch (Stock Out)</span>
                              </button>
                            )}

                            {order.status === 'Dispatched' && (
                              <button
                                onClick={() => handleOrderStatusUpdate(order.id, 'Delivered')}
                                className="px-2.5 py-1 text-xs bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg font-medium"
                              >
                                Delivered
                              </button>
                            )}
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}

        {/* ========================================================= */}
        {/* MODULE 3: STOCK & INVENTORY MANAGEMENT (4 PROCESSES) */}
        {/* ========================================================= */}
        {activeTab === 'inventory' && (
          <div className="space-y-6">
            <div className="bg-white border border-slate-200 rounded-xl p-6 shadow-sm flex flex-wrap justify-between items-center gap-4">
              <div>
                <span className="text-xs font-bold text-blue-600 uppercase tracking-wider">
                  Module 2 Reference
                </span>
                <h2 className="text-2xl font-bold text-slate-900 mt-1">Stock and Inventory Management</h2>
                <p className="text-sm text-slate-500">
                  Strictly follows the 4 Core Processes: Stock In (GRN) ➔ Stock Held (Live Stock) ➔ Stock Out (Sales) ➔ Closing Stock & Reports.
                </p>
              </div>

              <div className="flex space-x-3">
                <button
                  onClick={() => setShowGRNModal(true)}
                  className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white text-sm font-semibold rounded-xl shadow-sm flex items-center space-x-2 transition"
                >
                  <ArrowDownToLine className="w-4 h-4" />
                  <span>Receive Stock (Create GRN)</span>
                </button>
              </div>
            </div>

            {/* Inventory 4 Processes Sub-tab Switcher */}
            <div className="flex border-b border-slate-200 bg-white rounded-t-xl px-4 pt-3 space-x-2">
              <button
                onClick={() => setInvSubTab('stock_held')}
                className={`px-4 py-2.5 text-sm font-semibold border-b-2 transition flex items-center space-x-2 ${
                  invSubTab === 'stock_held'
                    ? 'border-blue-600 text-blue-600'
                    : 'border-transparent text-slate-500 hover:text-slate-800'
                }`}
              >
                <Package className="w-4 h-4" />
                <span>2. Stock Held (Live Stock)</span>
              </button>

              <button
                onClick={() => setInvSubTab('stock_in')}
                className={`px-4 py-2.5 text-sm font-semibold border-b-2 transition flex items-center space-x-2 ${
                  invSubTab === 'stock_in'
                    ? 'border-blue-600 text-blue-600'
                    : 'border-transparent text-slate-500 hover:text-slate-800'
                }`}
              >
                <ArrowDownToLine className="w-4 h-4" />
                <span>1. Stock In (GRN Receipts)</span>
              </button>

              <button
                onClick={() => setInvSubTab('stock_out')}
                className={`px-4 py-2.5 text-sm font-semibold border-b-2 transition flex items-center space-x-2 ${
                  invSubTab === 'stock_out'
                    ? 'border-blue-600 text-blue-600'
                    : 'border-transparent text-slate-500 hover:text-slate-800'
                }`}
              >
                <ArrowUpFromLine className="w-4 h-4" />
                <span>3. Stock Out (Sales to Shops)</span>
              </button>

              <button
                onClick={() => setInvSubTab('ledger')}
                className={`px-4 py-2.5 text-sm font-semibold border-b-2 transition flex items-center space-x-2 ${
                  invSubTab === 'ledger'
                    ? 'border-blue-600 text-blue-600'
                    : 'border-transparent text-slate-500 hover:text-slate-800'
                }`}
              >
                <FileText className="w-4 h-4" />
                <span>4. Closing Stock & Movement Ledger</span>
              </button>
            </div>

            {/* Sub-tab 1: Stock Held (Live Stock) */}
            {invSubTab === 'stock_held' && (
              <div className="bg-white border border-slate-200 rounded-b-xl shadow-sm overflow-hidden p-4 space-y-4">
                <div className="grid grid-cols-1 sm:grid-cols-4 gap-4">
                  <div className="p-4 bg-blue-50 border border-blue-100 rounded-xl">
                    <span className="text-xs text-blue-600 font-semibold">Total Stock on Hand</span>
                    <div className="text-2xl font-bold text-blue-900">{totalStockUnits.toLocaleString()} Units</div>
                  </div>
                  <div className="p-4 bg-emerald-50 border border-emerald-100 rounded-xl">
                    <span className="text-xs text-emerald-600 font-semibold">Warehouse Valuation</span>
                    <div className="text-2xl font-bold text-emerald-900">₹{totalStockValue.toLocaleString()}</div>
                  </div>
                  <div className="p-4 bg-amber-50 border border-amber-100 rounded-xl">
                    <span className="text-xs text-amber-600 font-semibold">Reserved for Orders</span>
                    <div className="text-2xl font-bold text-amber-900">
                      {stockHeld.reduce((a, s) => a + s.reservedStock, 0)} Units
                    </div>
                  </div>
                  <div className="p-4 bg-rose-50 border border-rose-100 rounded-xl">
                    <span className="text-xs text-rose-600 font-semibold">Near Expiry / Alerts</span>
                    <div className="text-2xl font-bold text-rose-900">
                      {stockHeld.filter(s => s.status === 'Near Expiry' || s.status === 'Low Stock').length} SKUs
                    </div>
                  </div>
                </div>

                <div className="overflow-x-auto">
                  <table className="w-full text-left text-sm text-slate-700">
                    <thead className="bg-slate-100 text-slate-700 text-xs uppercase font-semibold border-b border-slate-200">
                      <tr>
                        <th className="px-4 py-3">Product Name & Code</th>
                        <th className="px-4 py-3">Category</th>
                        <th className="px-4 py-3">Physical Stock</th>
                        <th className="px-4 py-3">Reserved</th>
                        <th className="px-4 py-3">Available Stock</th>
                        <th className="px-4 py-3">Batch & Expiry</th>
                        <th className="px-4 py-3">Velocity & Status</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100">
                      {stockHeld.map(item => (
                        <tr key={item.id} className="hover:bg-slate-50 transition">
                          <td className="px-4 py-3 font-semibold text-slate-900">
                            <div>{item.productName}</div>
                            <span className="text-xs text-slate-400 font-mono">{item.productCode}</span>
                          </td>
                          <td className="px-4 py-3 text-xs text-slate-600">{item.category}</td>
                          <td className="px-4 py-3 font-bold text-slate-800">{item.physicalStock}</td>
                          <td className="px-4 py-3 text-amber-600 font-semibold">{item.reservedStock}</td>
                          <td className="px-4 py-3 font-bold text-emerald-600 text-base">
                            {item.availableStock}
                          </td>
                          <td className="px-4 py-3 text-xs">
                            <div className="font-mono">{item.batchNo}</div>
                            <div className={item.daysToExpiry < 60 ? 'text-rose-600 font-bold' : 'text-slate-500'}>
                              Exp: {item.expiryDate} ({item.daysToExpiry}d left)
                            </div>
                          </td>
                          <td className="px-4 py-3">
                            <span
                              className={`text-xs px-2.5 py-0.5 rounded-full font-semibold ${
                                item.status === 'In Stock'
                                  ? 'bg-emerald-100 text-emerald-800'
                                  : item.status === 'Low Stock'
                                  ? 'bg-amber-100 text-amber-800'
                                  : 'bg-rose-100 text-rose-800'
                              }`}
                            >
                              {item.status}
                            </span>
                            <div className="text-[10px] text-slate-400 mt-0.5">{item.velocity}</div>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            )}

            {/* Sub-tab 2: Stock In (GRN Receipts) */}
            {invSubTab === 'stock_in' && (
              <div className="bg-white border border-slate-200 rounded-b-xl shadow-sm p-6 space-y-4">
                <div className="flex justify-between items-center">
                  <div>
                    <h3 className="text-lg font-bold text-slate-900">1. Stock In — Goods Received Note (GRN)</h3>
                    <p className="text-xs text-slate-500">
                      When primary orders arrive from company plant, goods are received, verified and added to live stock.
                    </p>
                  </div>
                  <button
                    onClick={() => setShowGRNModal(true)}
                    className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white text-xs font-bold rounded-lg shadow-sm"
                  >
                    + Enter New GRN
                  </button>
                </div>

                <div className="divide-y divide-slate-100">
                  {stockMovements.filter(m => m.type === 'STOCK_IN_GRN').map(m => (
                    <div key={m.id} className="py-4 flex justify-between items-center">
                      <div className="flex items-center space-x-3">
                        <div className="w-10 h-10 rounded-xl bg-emerald-100 text-emerald-700 flex items-center justify-center">
                          <ArrowDownToLine className="w-5 h-5" />
                        </div>
                        <div>
                          <div className="font-bold text-slate-900">{m.referenceNumber} • {m.productName}</div>
                          <div className="text-xs text-slate-500">
                            Batch: <span className="font-mono">{m.batchNo}</span> • Source: {m.entityName}
                          </div>
                          <div className="text-xs text-slate-400">{m.notes}</div>
                        </div>
                      </div>

                      <div className="text-right">
                        <span className="text-emerald-600 font-bold text-base">+{m.quantityDelta} Units</span>
                        <div className="text-xs text-slate-400">{m.movementDate}</div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Sub-tab 3: Stock Out (Sales to Shops) */}
            {invSubTab === 'stock_out' && (
              <div className="bg-white border border-slate-200 rounded-b-xl shadow-sm p-6 space-y-4">
                <h3 className="text-lg font-bold text-slate-900">3. Stock Out — Sales to Retail Shops</h3>
                <p className="text-xs text-slate-500">
                  When goods are dispatched to retail outlets against secondary invoices, stock is automatically deducted.
                </p>

                <div className="divide-y divide-slate-100">
                  {stockMovements.filter(m => m.type === 'STOCK_OUT_SALE').map(m => (
                    <div key={m.id} className="py-4 flex justify-between items-center">
                      <div className="flex items-center space-x-3">
                        <div className="w-10 h-10 rounded-xl bg-purple-100 text-purple-700 flex items-center justify-center">
                          <ArrowUpFromLine className="w-5 h-5" />
                        </div>
                        <div>
                          <div className="font-bold text-slate-900">{m.referenceNumber} • {m.productName}</div>
                          <div className="text-xs text-slate-500">
                            Delivered to: <span className="font-semibold text-slate-700">{m.entityName}</span>
                          </div>
                          <div className="text-xs text-slate-400">{m.notes}</div>
                        </div>
                      </div>

                      <div className="text-right">
                        <span className="text-purple-600 font-bold text-base">{m.quantityDelta} Units</span>
                        <div className="text-xs text-slate-400">{m.movementDate}</div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Sub-tab 4: Closing Stock & Movement Ledger */}
            {invSubTab === 'ledger' && (
              <div className="bg-white border border-slate-200 rounded-b-xl shadow-sm p-6 space-y-4">
                <h3 className="text-lg font-bold text-slate-900">4. Closing Stock & Movement Audit Ledger</h3>
                <p className="text-xs text-slate-500">
                  Maintains complete stock movement history: receipts, dispatches, returns, and closing balance calculation.
                </p>

                <div className="overflow-x-auto">
                  <table className="w-full text-left text-sm text-slate-700">
                    <thead className="bg-slate-100 text-slate-700 text-xs uppercase font-semibold border-b border-slate-200">
                      <tr>
                        <th className="px-4 py-3">Date & Time</th>
                        <th className="px-4 py-3">Movement Type</th>
                        <th className="px-4 py-3">Reference #</th>
                        <th className="px-4 py-3">Product Name</th>
                        <th className="px-4 py-3">Quantity Delta</th>
                        <th className="px-4 py-3">Closing Stock Balance</th>
                        <th className="px-4 py-3">Entity / Notes</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100">
                      {stockMovements.map(m => (
                        <tr key={m.id} className="hover:bg-slate-50 transition">
                          <td className="px-4 py-3 text-xs text-slate-500">{m.movementDate}</td>
                          <td className="px-4 py-3">
                            <span
                              className={`text-[11px] font-bold px-2 py-0.5 rounded-full ${
                                m.type === 'STOCK_IN_GRN'
                                  ? 'bg-emerald-100 text-emerald-800'
                                  : m.type === 'STOCK_OUT_SALE'
                                  ? 'bg-purple-100 text-purple-800'
                                  : 'bg-blue-100 text-blue-800'
                              }`}
                            >
                              {m.type}
                            </span>
                          </td>
                          <td className="px-4 py-3 font-mono text-xs font-semibold">{m.referenceNumber}</td>
                          <td className="px-4 py-3 font-medium text-slate-900">{m.productName}</td>
                          <td
                            className={`px-4 py-3 font-bold ${
                              m.quantityDelta > 0 ? 'text-emerald-600' : 'text-purple-600'
                            }`}
                          >
                            {m.quantityDelta > 0 ? `+${m.quantityDelta}` : m.quantityDelta}
                          </td>
                          <td className="px-4 py-3 font-bold text-slate-800">{m.resultingStock} Units</td>
                          <td className="px-4 py-3 text-xs text-slate-500">{m.notes}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            )}
          </div>
        )}

        {/* ========================================================= */}
        {/* MODULE 4: TICKET MANAGEMENT */}
        {/* ========================================================= */}
        {activeTab === 'tickets' && (
          <div className="space-y-6">
            <div className="bg-white border border-slate-200 rounded-xl p-6 shadow-sm flex flex-wrap justify-between items-center gap-4">
              <div>
                <span className="text-xs font-bold text-blue-600 uppercase tracking-wider">
                  Distributor Officer & Admin Support
                </span>
                <h2 className="text-2xl font-bold text-slate-900 mt-1">Ticket Management</h2>
                <p className="text-sm text-slate-500">
                  Raise and resolve issues across Product, Portal, and Delivery with the 4 statuses: Open, In Progress, Closed, Rejected.
                </p>
              </div>

              <button
                onClick={() => setShowNewTicketModal(true)}
                className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white text-sm font-semibold rounded-xl shadow-sm flex items-center space-x-2"
              >
                <Plus className="w-4 h-4" />
                <span>Raise New Ticket</span>
              </button>
            </div>

            {/* Filter Tabs */}
            <div className="flex border-b border-slate-200 space-x-2">
              {['All', 'Open', 'In Progress', 'Closed', 'Rejected'].map(status => (
                <button
                  key={status}
                  onClick={() => setSelectedTicketFilter(status)}
                  className={`px-4 py-2 text-sm font-semibold border-b-2 transition ${
                    selectedTicketFilter === status
                      ? 'border-blue-600 text-blue-600'
                      : 'border-transparent text-slate-500 hover:text-slate-800'
                  }`}
                >
                  {status}
                </button>
              ))}
            </div>

            {/* Tickets Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {filteredTickets.map(ticket => {
                const getStatusPill = () => {
                  switch (ticket.status) {
                    case 'Open':
                      return 'bg-blue-100 text-blue-800 border-blue-200';
                    case 'In Progress':
                      return 'bg-amber-100 text-amber-800 border-amber-200';
                    case 'Closed':
                      return 'bg-emerald-100 text-emerald-800 border-emerald-200';
                    case 'Rejected':
                      return 'bg-rose-100 text-rose-800 border-rose-200';
                  }
                };

                return (
                  <div key={ticket.id} className="bg-white border border-slate-200 rounded-xl p-5 shadow-sm space-y-3">
                    <div className="flex justify-between items-start">
                      <div>
                        <span className="text-xs font-mono text-slate-400">{ticket.ticketNumber}</span>
                        <h4 className="font-bold text-slate-900 mt-0.5">{ticket.subject}</h4>
                      </div>
                      <span className={`text-xs px-2.5 py-0.5 rounded-full font-bold border ${getStatusPill()}`}>
                        {ticket.status}
                      </span>
                    </div>

                    <p className="text-xs text-slate-600">{ticket.description}</p>

                    <div className="text-xs text-slate-500 flex flex-wrap gap-2 pt-2 border-t border-slate-100">
                      <span className="bg-slate-100 px-2 py-0.5 rounded font-medium">Category: {ticket.category}</span>
                      <span className="bg-slate-100 px-2 py-0.5 rounded font-medium">Priority: {ticket.priority}</span>
                      <span className="bg-slate-100 px-2 py-0.5 rounded font-medium">Raised: {ticket.raisedDate}</span>
                    </div>

                    {ticket.assignedOfficer && (
                      <div className="text-xs text-blue-700 font-medium">
                        DO Officer: {ticket.assignedOfficer}
                      </div>
                    )}

                    {ticket.resolutionNotes && (
                      <div className="bg-emerald-50 border border-emerald-200 p-2.5 rounded-lg text-xs text-emerald-900">
                        <span className="font-bold block">Resolution:</span>
                        {ticket.resolutionNotes}
                      </div>
                    )}

                    {ticket.rejectionReason && (
                      <div className="bg-rose-50 border border-rose-200 p-2.5 rounded-lg text-xs text-rose-900">
                        <span className="font-bold block">Rejection Reason:</span>
                        {ticket.rejectionReason}
                      </div>
                    )}

                    {/* Action Dropdown / Controls */}
                    <div className="pt-2 flex justify-end space-x-2">
                      {ticket.status === 'Open' && (
                        <button
                          onClick={() => handleUpdateTicketStatus(ticket.id, 'In Progress')}
                          className="px-2.5 py-1 text-xs bg-amber-600 text-white rounded font-medium"
                        >
                          Mark In Progress
                        </button>
                      )}

                      {ticket.status === 'In Progress' && (
                        <>
                          <button
                            onClick={() =>
                              handleUpdateTicketStatus(
                                ticket.id,
                                'Closed',
                                'Issue investigated and credit/delivery adjustment confirmed by DO.'
                              )
                            }
                            className="px-2.5 py-1 text-xs bg-emerald-600 text-white rounded font-medium"
                          >
                            Resolve / Close
                          </button>
                          <button
                            onClick={() =>
                              handleUpdateTicketStatus(
                                ticket.id,
                                'Rejected',
                                undefined,
                                'Claims outside standard return/service policy parameters.'
                              )
                            }
                            className="px-2.5 py-1 text-xs bg-rose-600 text-white rounded font-medium"
                          >
                            Reject
                          </button>
                        </>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        )}

        {/* ========================================================= */}
        {/* MODULE 5: RETURNS & ASSET MANAGEMENT */}
        {/* ========================================================= */}
        {activeTab === 'returns_assets' && (
          <div className="space-y-6">
            <div className="bg-white border border-slate-200 rounded-xl p-6 shadow-sm flex flex-wrap justify-between items-center gap-4">
              <div>
                <span className="text-xs font-bold text-blue-600 uppercase tracking-wider">
                  Field Assets & Reverse Logistics
                </span>
                <h2 className="text-2xl font-bold text-slate-900 mt-1">Returns and Asset Management</h2>
                <p className="text-sm text-slate-500">
                  Track returned products from retail outlets and maintain company assets (Freezers, POSM racks, Signboards).
                </p>
              </div>

              <div className="flex border border-slate-200 bg-slate-50 p-1 rounded-xl">
                <button
                  onClick={() => setReturnAssetSubTab('returns')}
                  className={`px-4 py-1.5 rounded-lg text-xs font-bold transition ${
                    returnAssetSubTab === 'returns'
                      ? 'bg-white text-blue-700 shadow-sm'
                      : 'text-slate-600 hover:text-slate-900'
                  }`}
                >
                  Product Returns ({returns.length})
                </button>
                <button
                  onClick={() => setReturnAssetSubTab('assets')}
                  className={`px-4 py-1.5 rounded-lg text-xs font-bold transition ${
                    returnAssetSubTab === 'assets'
                      ? 'bg-white text-blue-700 shadow-sm'
                      : 'text-slate-600 hover:text-slate-900'
                  }`}
                >
                  Company Assets ({assets.length})
                </button>
              </div>
            </div>

            {/* Sub-view: Returns */}
            {returnAssetSubTab === 'returns' && (
              <div className="bg-white border border-slate-200 rounded-xl shadow-sm overflow-hidden p-4 space-y-4">
                <h3 className="font-bold text-slate-900 flex items-center space-x-2">
                  <RotateCcw className="w-5 h-5 text-blue-600" />
                  <span>Retailer Returns Processing</span>
                </h3>

                <div className="overflow-x-auto">
                  <table className="w-full text-left text-sm text-slate-700">
                    <thead className="bg-slate-100 text-slate-700 text-xs uppercase font-semibold border-b border-slate-200">
                      <tr>
                        <th className="px-4 py-3">Return # & Date</th>
                        <th className="px-4 py-3">Retail Outlet</th>
                        <th className="px-4 py-3">Product Name</th>
                        <th className="px-4 py-3">Quantity</th>
                        <th className="px-4 py-3">Reason</th>
                        <th className="px-4 py-3">Physical Condition</th>
                        <th className="px-4 py-3">Status</th>
                        <th className="px-4 py-3 text-right">Actions</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100">
                      {returns.map(ret => (
                        <tr key={ret.id} className="hover:bg-slate-50 transition">
                          <td className="px-4 py-3 font-mono text-xs font-bold">{ret.returnNumber}</td>
                          <td className="px-4 py-3 font-semibold text-slate-900">{ret.retailerName}</td>
                          <td className="px-4 py-3">{ret.productName}</td>
                          <td className="px-4 py-3 font-bold text-slate-800">{ret.quantity} Units</td>
                          <td className="px-4 py-3 text-xs text-rose-700 font-medium">{ret.reason}</td>
                          <td className="px-4 py-3 text-xs font-semibold">{ret.condition}</td>
                          <td className="px-4 py-3">
                            <span
                              className={`text-xs px-2 py-0.5 rounded-full font-bold ${
                                ret.status.includes('Approved')
                                  ? 'bg-emerald-100 text-emerald-800'
                                  : 'bg-amber-100 text-amber-800'
                              }`}
                            >
                              {ret.status}
                            </span>
                            {ret.creditNoteNumber && (
                              <div className="text-[10px] text-slate-500 font-mono mt-0.5">
                                CN: {ret.creditNoteNumber}
                              </div>
                            )}
                          </td>
                          <td className="px-4 py-3 text-right">
                            {ret.status === 'Pending Approval' && (
                              <button
                                onClick={() => handleApproveReturn(ret.id)}
                                className="px-2.5 py-1 text-xs bg-emerald-600 hover:bg-emerald-700 text-white rounded font-medium"
                              >
                                Approve & Restock
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

            {/* Sub-view: Assets */}
            {returnAssetSubTab === 'assets' && (
              <div className="bg-white border border-slate-200 rounded-xl shadow-sm overflow-hidden p-4 space-y-4">
                <h3 className="font-bold text-slate-900 flex items-center space-x-2">
                  <ShieldCheck className="w-5 h-5 text-blue-600" />
                  <span>Company Assigned Assets Tracking</span>
                </h3>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  {assets.map(asset => (
                    <div key={asset.id} className="bg-slate-50 border border-slate-200 rounded-xl p-4 space-y-2">
                      <div className="flex justify-between items-start">
                        <div>
                          <span className="text-xs font-mono text-slate-400">{asset.assetCode}</span>
                          <h4 className="font-bold text-slate-900">{asset.assetType}</h4>
                          <span className="text-xs text-slate-500">{asset.modelNumber} • SN: {asset.serialNumber}</span>
                        </div>
                        <span
                          className={`text-xs px-2.5 py-0.5 rounded-full font-bold ${
                            asset.status === 'Operational'
                              ? 'bg-emerald-100 text-emerald-800'
                              : asset.status === 'Needs Service'
                              ? 'bg-amber-100 text-amber-800'
                              : 'bg-rose-100 text-rose-800'
                          }`}
                        >
                          {asset.status}
                        </span>
                      </div>

                      <div className="text-xs text-slate-600 pt-2 border-t border-slate-200 flex justify-between">
                        <span>Assigned to: <strong className="text-slate-800">{asset.assignedLocation}</strong></span>
                        <span>Last Service: {asset.lastServiceDate}</span>
                      </div>

                      {asset.serviceRemarks && (
                        <div className="text-xs text-slate-500 italic bg-white p-2 rounded border border-slate-200">
                          {asset.serviceRemarks}
                        </div>
                      )}

                      <div className="pt-2 flex justify-end space-x-2">
                        {asset.status !== 'Operational' && (
                          <button
                            onClick={() =>
                              handleAssetServiceUpdate(asset.id, 'Operational', 'Technician serviced and certified operational.')
                            }
                            className="px-2.5 py-1 text-xs bg-emerald-600 hover:bg-emerald-700 text-white rounded font-medium"
                          >
                            Mark Repaired
                          </button>
                        )}
                        {asset.status === 'Operational' && (
                          <button
                            onClick={() =>
                              handleAssetServiceUpdate(asset.id, 'Needs Service', 'Outlet reported cooling/knob issue.')
                            }
                            className="px-2.5 py-1 text-xs bg-amber-600 hover:bg-amber-700 text-white rounded font-medium"
                          >
                            Report Service Needed
                          </button>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        )}

        {/* ========================================================= */}
        {/* MODULE 6: MANAGERS — DASHBOARDS AND REPORTS */}
        {/* ========================================================= */}
        {activeTab === 'reports' && (
          <div className="space-y-6">
            <div className="bg-white border border-slate-200 rounded-xl p-6 shadow-sm flex flex-wrap justify-between items-center gap-4">
              <div>
                <span className="text-xs font-bold text-blue-600 uppercase tracking-wider">
                  Manager Analytics
                </span>
                <h2 className="text-2xl font-bold text-slate-900 mt-1">Managers — Dashboards and Reports</h2>
                <p className="text-sm text-slate-500">
                  The 4 essential reports: Sales vs Target, Beat Productivity, Outlet Coverage, and Distributor Stock.
                </p>
              </div>
              <span className="text-xs bg-slate-100 text-slate-600 px-3 py-1.5 rounded-lg font-mono">
                Period: {salesReport.period}
              </span>
            </div>

            {/* REPORT 1: SALES VS TARGET */}
            <div className="bg-white border border-slate-200 rounded-xl p-6 shadow-sm space-y-4">
              <h3 className="font-bold text-slate-900 text-lg flex items-center space-x-2">
                <TrendingUp className="w-5 h-5 text-blue-600" />
                <span>Report 1: Sales vs Target (Achievement & Growth)</span>
              </h3>
              <p className="text-xs text-slate-500">
                Compares actual sales with targets by Sales Representative and category, comparing this month versus last month.
              </p>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {salesReport.srMetrics.map((sr, idx) => (
                  <div key={idx} className="bg-slate-50 border border-slate-200 rounded-xl p-4 space-y-3">
                    <div className="flex justify-between items-start">
                      <div>
                        <h4 className="font-bold text-slate-900">{sr.srName}</h4>
                        <span className="text-xs text-slate-500">Target: ₹{sr.target.toLocaleString()}</span>
                      </div>
                      <span className="text-sm font-bold text-emerald-600 bg-emerald-50 border border-emerald-200 px-2.5 py-1 rounded-lg">
                        {sr.achievementPct}% Achieved
                      </span>
                    </div>

                    {/* Progress Bar */}
                    <div className="w-full bg-slate-200 rounded-full h-3 overflow-hidden">
                      <div
                        className="bg-blue-600 h-3 rounded-full transition-all"
                        style={{ width: `${Math.min(sr.achievementPct, 100)}%` }}
                      ></div>
                    </div>

                    <div className="flex justify-between text-xs text-slate-600 pt-1">
                      <span>Actual MTD: <strong>₹{sr.actual.toLocaleString()}</strong></span>
                      <span>Last Month: ₹{sr.lastMonthActual.toLocaleString()} (+{sr.growthPct}% MoM)</span>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* REPORT 2: BEAT PRODUCTIVITY */}
            <div className="bg-white border border-slate-200 rounded-xl p-6 shadow-sm space-y-4">
              <h3 className="font-bold text-slate-900 text-lg flex items-center space-x-2">
                <BarChart3 className="w-5 h-5 text-indigo-600" />
                <span>Report 2: Beat Productivity (Planned vs Visited vs Billed)</span>
              </h3>
              <p className="text-xs text-slate-500">
                Shows shops planned vs shops visited, and how many visits resulted in an order (Strike Rate).
              </p>

              <div className="overflow-x-auto">
                <table className="w-full text-left text-sm text-slate-700">
                  <thead className="bg-slate-100 text-slate-700 text-xs uppercase font-semibold border-b border-slate-200">
                    <tr>
                      <th className="px-4 py-3">Beat Route</th>
                      <th className="px-4 py-3">SR Name</th>
                      <th className="px-4 py-3">Shops Planned</th>
                      <th className="px-4 py-3">Shops Visited</th>
                      <th className="px-4 py-3">Orders Billed</th>
                      <th className="px-4 py-3">Strike Rate %</th>
                      <th className="px-4 py-3 text-right">Order Value</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                    {beatReport.map((b, idx) => (
                      <tr key={idx} className="hover:bg-slate-50 transition">
                        <td className="px-4 py-3 font-semibold text-slate-900">{b.beatName}</td>
                        <td className="px-4 py-3 text-xs text-blue-700 font-semibold">{b.assignedSR}</td>
                        <td className="px-4 py-3 font-bold">{b.totalPlannedShops}</td>
                        <td className="px-4 py-3 font-bold text-slate-800">{b.visitedShops}</td>
                        <td className="px-4 py-3 font-bold text-emerald-600">{b.billedOrders}</td>
                        <td className="px-4 py-3">
                          <span className="font-bold text-blue-700 bg-blue-50 px-2 py-0.5 rounded">
                            {b.strikeRatePct}%
                          </span>
                        </td>
                        <td className="px-4 py-3 text-right font-bold text-slate-900">
                          ₹{b.totalOrderValue.toLocaleString()}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>

            {/* REPORT 3: OUTLET COVERAGE */}
            <div className="bg-white border border-slate-200 rounded-xl p-6 shadow-sm space-y-4">
              <h3 className="font-bold text-slate-900 text-lg flex items-center space-x-2">
                <Store className="w-5 h-5 text-emerald-600" />
                <span>Report 3: Outlet Coverage (Active Buyers vs Attention Needed)</span>
              </h3>
              <p className="text-xs text-slate-500">
                Shows how many outlets in the area are active buyers ({coverageReport.activeBuyers} of {coverageReport.totalOutlets}) and highlights outlets needing immediate attention.
              </p>

              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <div className="p-4 bg-emerald-50 border border-emerald-200 rounded-xl text-center">
                  <span className="text-xs text-emerald-700 font-semibold">Active Buyers</span>
                  <div className="text-2xl font-bold text-emerald-900">{coverageReport.activeBuyers} Outlets</div>
                </div>
                <div className="p-4 bg-rose-50 border border-rose-200 rounded-xl text-center">
                  <span className="text-xs text-rose-700 font-semibold">Inactive / Attention</span>
                  <div className="text-2xl font-bold text-rose-900">{coverageReport.inactiveOutlets} Outlets</div>
                </div>
                <div className="p-4 bg-blue-50 border border-blue-200 rounded-xl text-center">
                  <span className="text-xs text-blue-700 font-semibold">Coverage Rate</span>
                  <div className="text-2xl font-bold text-blue-900">{coverageReport.coveragePct}%</div>
                </div>
              </div>

              <div>
                <h4 className="text-xs font-bold text-slate-700 uppercase tracking-wider mb-2">
                  Inactive Outlets Requiring Follow-Up:
                </h4>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                  {coverageReport.inactiveList.slice(0, 4).map((item, idx) => (
                    <div key={idx} className="p-3 bg-slate-50 border border-slate-200 rounded-lg flex justify-between items-center text-xs">
                      <div>
                        <div className="font-bold text-slate-800">{item.outletName}</div>
                        <span className="text-slate-500">{item.beatName} • SR: {item.assignedSR}</span>
                      </div>
                      <span className="text-rose-700 font-bold bg-rose-50 border border-rose-200 px-2 py-0.5 rounded">
                        No orders in {item.daysSinceLastOrder}d
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            </div>

            {/* REPORT 4: DISTRIBUTOR STOCK HEALTH */}
            <div className="bg-white border border-slate-200 rounded-xl p-6 shadow-sm space-y-4">
              <h3 className="font-bold text-slate-900 text-lg flex items-center space-x-2">
                <Package className="w-5 h-5 text-amber-600" />
                <span>Report 4: Distributor Stock (Slow-Moving & Expiry Risk)</span>
              </h3>
              <p className="text-xs text-slate-500">
                Monitors stock on hand, items that are slow-moving, and products close to expiry.
              </p>

              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                {stockHeld.map(item => (
                  <div key={item.id} className="p-4 bg-slate-50 border border-slate-200 rounded-xl space-y-2">
                    <div className="flex justify-between items-start">
                      <div className="font-bold text-slate-900 text-sm">{item.productName}</div>
                      <span
                        className={`text-[10px] px-2 py-0.5 rounded font-bold ${
                          item.velocity === 'Fast Moving'
                            ? 'bg-emerald-100 text-emerald-800'
                            : 'bg-amber-100 text-amber-800'
                        }`}
                      >
                        {item.velocity}
                      </span>
                    </div>
                    <div className="text-xs text-slate-600 flex justify-between">
                      <span>Available: <strong>{item.availableStock} Units</strong></span>
                      <span>Value: <strong>₹{(item.availableStock * item.unitPrice).toLocaleString()}</strong></span>
                    </div>
                    <div className={`text-xs ${item.daysToExpiry < 60 ? 'text-rose-600 font-bold' : 'text-slate-500'}`}>
                      Expires in: {item.daysToExpiry} days ({item.expiryDate})
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}
      </main>

      {/* ========================================================= */}
      {/* MODAL 1: ORDER LINE ITEMS INSPECTOR */}
      {/* ========================================================= */}
      {selectedOrderForModal && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-xl w-full p-6 shadow-2xl border border-slate-200 space-y-4">
            <div className="flex justify-between items-start border-b border-slate-100 pb-3">
              <div>
                <span className="text-xs font-mono text-slate-400">{selectedOrderForModal.orderNumber}</span>
                <h3 className="text-lg font-bold text-slate-900">{selectedOrderForModal.retailerName}</h3>
                <span className="text-xs text-slate-500">SR: {selectedOrderForModal.salesRepName} • {selectedOrderForModal.orderDate}</span>
              </div>
              <button
                onClick={() => setSelectedOrderForModal(null)}
                className="text-slate-400 hover:text-slate-700"
              >
                ✕
              </button>
            </div>

            <div className="space-y-2">
              <h4 className="text-xs font-bold text-slate-700 uppercase tracking-wider">Ordered Products:</h4>
              <div className="divide-y divide-slate-100 border border-slate-100 rounded-xl overflow-hidden">
                {selectedOrderForModal.items.map(item => (
                  <div key={item.id} className="p-3 flex justify-between items-center text-sm">
                    <div>
                      <div className="font-semibold text-slate-900">{item.productName}</div>
                      <span className="text-xs text-slate-500">Qty: {item.quantity} units @ ₹{item.unitPrice}</span>
                    </div>
                    <span className="font-bold text-slate-800">₹{item.lineTotal.toLocaleString()}</span>
                  </div>
                ))}
              </div>
            </div>

            <div className="pt-3 border-t border-slate-100 flex justify-between items-center">
              <div>
                <span className="text-xs text-slate-500 block">Total Order Amount:</span>
                <span className="text-xl font-bold text-slate-900">₹{selectedOrderForModal.totalAmount.toLocaleString()}</span>
              </div>

              <button
                onClick={() => setSelectedOrderForModal(null)}
                className="px-5 py-2 bg-slate-900 hover:bg-slate-800 text-white text-xs font-semibold rounded-xl"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ========================================================= */}
      {/* MODAL 2: GOODS RECEIVED NOTE (GRN) CREATION */}
      {/* ========================================================= */}
      {showGRNModal && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
          <form
            onSubmit={handleCreateGRN}
            className="bg-white rounded-2xl max-w-lg w-full p-6 shadow-2xl border border-slate-200 space-y-4"
          >
            <div className="flex justify-between items-center border-b border-slate-100 pb-3">
              <div>
                <h3 className="text-lg font-bold text-slate-900">Process 1: Stock In — Goods Received Note (GRN)</h3>
                <p className="text-xs text-slate-500">Receive company primary shipment and increase available stock.</p>
              </div>
              <button
                type="button"
                onClick={() => setShowGRNModal(false)}
                className="text-slate-400 hover:text-slate-700"
              >
                ✕
              </button>
            </div>

            <div className="space-y-3">
              <div>
                <label className="text-xs font-semibold text-slate-700 block mb-1">Select Product</label>
                <select
                  value={grnProduct}
                  onChange={e => setGrnProduct(e.target.value)}
                  className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-lg text-sm"
                >
                  {stockHeld.map(s => (
                    <option key={s.id} value={s.productName}>{s.productName}</option>
                  ))}
                </select>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-xs font-semibold text-slate-700 block mb-1">Received Quantity (Units)</label>
                  <input
                    type="number"
                    min="1"
                    value={grnQty}
                    onChange={e => setGrnQty(Number(e.target.value))}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-lg text-sm"
                    required
                  />
                </div>
                <div>
                  <label className="text-xs font-semibold text-slate-700 block mb-1">Batch Number</label>
                  <input
                    type="text"
                    value={grnBatch}
                    onChange={e => setGrnBatch(e.target.value)}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-lg text-sm"
                    required
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-xs font-semibold text-slate-700 block mb-1">Expiry Date</label>
                  <input
                    type="date"
                    value={grnExpiry}
                    onChange={e => setGrnExpiry(e.target.value)}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-lg text-sm"
                    required
                  />
                </div>
                <div>
                  <label className="text-xs font-semibold text-slate-700 block mb-1">Company PO Reference #</label>
                  <input
                    type="text"
                    value={grnPO}
                    onChange={e => setGrnPO(e.target.value)}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-lg text-sm"
                    required
                  />
                </div>
              </div>
            </div>

            <div className="pt-3 border-t border-slate-100 flex justify-end space-x-2">
              <button
                type="button"
                onClick={() => setShowGRNModal(false)}
                className="px-4 py-2 border border-slate-200 text-slate-700 text-xs font-semibold rounded-lg"
              >
                Cancel
              </button>
              <button
                type="submit"
                className="px-5 py-2 bg-blue-600 hover:bg-blue-700 text-white text-xs font-bold rounded-lg shadow-sm"
              >
                Receive Goods & Update Stock
              </button>
            </div>
          </form>
        </div>
      )}

      {/* ========================================================= */}
      {/* MODAL 3: RAISE SUPPORT TICKET */}
      {/* ========================================================= */}
      {showNewTicketModal && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
          <form
            onSubmit={handleCreateTicket}
            className="bg-white rounded-2xl max-w-lg w-full p-6 shadow-2xl border border-slate-200 space-y-4"
          >
            <div className="flex justify-between items-center border-b border-slate-100 pb-3">
              <div>
                <h3 className="text-lg font-bold text-slate-900">Raise Issue to Distributor Officer (DO)</h3>
                <p className="text-xs text-slate-500">Submit product, portal, or delivery concerns directly to admin.</p>
              </div>
              <button
                type="button"
                onClick={() => setShowNewTicketModal(false)}
                className="text-slate-400 hover:text-slate-700"
              >
                ✕
              </button>
            </div>

            <div className="space-y-3">
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-xs font-semibold text-slate-700 block mb-1">Category</label>
                  <select
                    value={ticketCategory}
                    onChange={e => setTicketCategory(e.target.value)}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-lg text-sm"
                  >
                    <option value="Product Issue">Product Issue (Damaged/Defect)</option>
                    <option value="Delivery Delay">Delivery Delay / Logistics</option>
                    <option value="Portal Issue">Portal Issue / Sync Glitch</option>
                    <option value="Billing Dispute">Billing Dispute / Credit Note</option>
                  </select>
                </div>

                <div>
                  <label className="text-xs font-semibold text-slate-700 block mb-1">Priority</label>
                  <select
                    value={ticketPriority}
                    onChange={e => setTicketPriority(e.target.value)}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-lg text-sm"
                  >
                    <option value="Critical">Critical</option>
                    <option value="High">High</option>
                    <option value="Medium">Medium</option>
                    <option value="Low">Low</option>
                  </select>
                </div>
              </div>

              <div>
                <label className="text-xs font-semibold text-slate-700 block mb-1">Subject</label>
                <input
                  type="text"
                  placeholder="e.g. 4 cartons of Parle-G crushed during truck unloading"
                  value={ticketSubject}
                  onChange={e => setTicketSubject(e.target.value)}
                  className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-lg text-sm"
                  required
                />
              </div>

              <div>
                <label className="text-xs font-semibold text-slate-700 block mb-1">Detailed Description</label>
                <textarea
                  rows={3}
                  placeholder="Provide batch number, quantity affected, or specific error observed..."
                  value={ticketDesc}
                  onChange={e => setTicketDesc(e.target.value)}
                  className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-lg text-sm"
                  required
                ></textarea>
              </div>
            </div>

            <div className="pt-3 border-t border-slate-100 flex justify-end space-x-2">
              <button
                type="button"
                onClick={() => setShowNewTicketModal(false)}
                className="px-4 py-2 border border-slate-200 text-slate-700 text-xs font-semibold rounded-lg"
              >
                Cancel
              </button>
              <button
                type="submit"
                className="px-5 py-2 bg-blue-600 hover:bg-blue-700 text-white text-xs font-bold rounded-lg shadow-sm"
              >
                Submit Ticket to DO Desk
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
}
