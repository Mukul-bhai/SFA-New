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
  Truck,
  LogOut,
  Clock,
  Info,
  CreditCard,
  MapPin,
  X
} from 'lucide-react';
import { DMSDataService } from './services/api';
import DistributorLogin from './components/DistributorLogin';
import { formatIST, getCurrentISTTimestamp } from './utils/dateUtils';

export default function App() {
  // Authentication State
  const [authenticatedDistributor, setAuthenticatedDistributor] = useState(() =>
    DMSDataService.getAuthenticatedDistributor()
  );

  // Navigation Tabs: 6 Core Modules
  const [activeTab, setActiveTab] = useState('orders');

  // Sub-tabs
  const [invSubTab, setInvSubTab] = useState('stock_held');
  const [returnAssetSubTab, setReturnAssetSubTab] = useState('returns');

  // Data Collections (Scoped strictly to authenticated distributor)
  const [distributor, setDistributor] = useState(() => DMSDataService.getDistributor());
  const [employees, setEmployees] = useState(() => DMSDataService.getEmployees());
  const [outlets, setOutlets] = useState(() => DMSDataService.getRetailerOutlets());
  const [orders, setOrders] = useState(() => DMSDataService.getOrders());
  const [stockHeld, setStockHeld] = useState(() => DMSDataService.getStockHeld());
  const [stockMovements, setStockMovements] = useState(() => DMSDataService.getStockMovements());
  const [tickets, setTickets] = useState(() => DMSDataService.getTickets());
  const [returns, setReturns] = useState(() => DMSDataService.getReturns());
  const [assets, setAssets] = useState(() => DMSDataService.getAssets());

  // Reports
  const [salesReport, setSalesReport] = useState(() => DMSDataService.getSalesVsTarget());
  const [beatReport, setBeatReport] = useState(() => DMSDataService.getBeatProductivity());
  const [coverageReport, setCoverageReport] = useState(() => DMSDataService.getOutletCoverage());

  // Search & Filter State
  const [outletSearch, setOutletSearch] = useState('');
  const [selectedTicketFilter, setSelectedTicketFilter] = useState('All');

  // Modals
  const [selectedOrderForModal, setSelectedOrderForModal] = useState(null);
  const [showGRNModal, setShowGRNModal] = useState(false);
  const [showNewTicketModal, setShowNewTicketModal] = useState(false);
  const [showProfileModal, setShowProfileModal] = useState(false);

  // Form State: GRN
  const [grnProduct, setGrnProduct] = useState('Herbal Shampoo 200ml');
  const [grnQty, setGrnQty] = useState(100);
  const [grnBatch, setGrnBatch] = useState('B2610-GRN1');
  const [grnExpiry, setGrnExpiry] = useState('2027-04-30');
  const [grnPO, setGrnPO] = useState('PO-2026-9021');

  // Form State: Ticket (Strictly aligned with Salesforce Ticket__c picklists)
  const [ticketCategory, setTicketCategory] = useState('Damaged Stock');
  const [ticketPriority, setTicketPriority] = useState('High');
  const [ticketSubject, setTicketSubject] = useState('');
  const [ticketDesc, setTicketDesc] = useState('');

  // Toast / Notification
  const [notification, setNotification] = useState(null);

  // Live IST Clock
  const [currentISTTime, setCurrentISTTime] = useState(getCurrentISTTimestamp());

  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentISTTime(getCurrentISTTimestamp());
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  const triggerToast = (msg) => {
    setNotification(msg);
    setTimeout(() => setNotification(null), 3500);
  };

  const reloadData = (dist) => {
    const currentDist = dist || DMSDataService.getDistributor();
    setDistributor(currentDist);
    setEmployees(DMSDataService.getEmployees());
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

  const handleFullSync = async () => {
    await DMSDataService.syncDistributorsFromSalesforce();
    await DMSDataService.syncEmployeesFromSalesforce();
    await DMSDataService.syncRetailersFromSalesforce();
    await DMSDataService.syncOrdersFromSalesforce();
    await DMSDataService.syncInventoryFromSalesforce();
    await DMSDataService.syncReturnsFromSalesforce();
    await DMSDataService.syncAssetsFromSalesforce();
    await DMSDataService.syncTicketsFromSalesforce();
    reloadData();
  };

  useEffect(() => {
    if (authenticatedDistributor) {
      handleFullSync();
    }
  }, [authenticatedDistributor?.id]);

  const handleLoginSuccess = (dist) => {
    setAuthenticatedDistributor(dist);
    reloadData(dist);
    triggerToast(`Welcome back, ${dist.name}! Signed into Distributor Portal.`);
  };

  const handleLogout = () => {
    DMSDataService.logout();
    setAuthenticatedDistributor(null);
    triggerToast('Logged out successfully.');
  };

  // Handlers
  const handleOrderStatusUpdate = async (orderId, status) => {
    await DMSDataService.updateOrderStatus(orderId, status);
    reloadData();
    triggerToast(`Order status updated to "${status}" at ${getCurrentISTTimestamp()}`);
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
    triggerToast(`GRN created! Received ${grnQty} cases into warehouse stock at ${getCurrentISTTimestamp()}.`);
  };

  const handleCreateTicket = async (e) => {
    e.preventDefault();
    if (!ticketSubject.trim()) return;
    await DMSDataService.createTicket({
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
    triggerToast('Support ticket raised and synced directly to Salesforce Ticket__c!');
  };

  const handleUpdateTicketStatus = (ticketId, status, notes, reason) => {
    DMSDataService.updateTicketStatus(ticketId, status, notes, reason);
    reloadData();
    triggerToast(`Ticket updated to ${status}`);
  };

  const handleApproveReturn = (returnId) => {
    DMSDataService.updateReturnStatus(returnId, 'Approved & Restocked');
    reloadData();
    triggerToast('Return approved and credit note logged in IST.');
  };

  const handleAssetServiceUpdate = (assetId, status, remarks) => {
    DMSDataService.updateAssetStatus(assetId, status, remarks);
    reloadData();
    triggerToast(`Asset status updated to ${status}`);
  };

  // If user is not authenticated, render login view
  if (!authenticatedDistributor) {
    return <DistributorLogin onLoginSuccess={handleLoginSuccess} />;
  }

  // Filtered Outlets
  const filteredOutlets = (outlets || []).filter(o => {
    if (!o) return false;
    const q = (outletSearch || '').toLowerCase();
    return (
      (o.name || '').toLowerCase().includes(q) ||
      (o.shopName || '').toLowerCase().includes(q) ||
      (o.code || '').toLowerCase().includes(q)
    );
  });

  // Filtered Tickets
  const filteredTickets = (tickets || []).filter(t => {
    if (!t) return false;
    if (selectedTicketFilter === 'All') return true;
    return t.status === selectedTicketFilter;
  });

  // Quick Stats
  const totalStockUnits = (stockHeld || []).reduce((acc, s) => acc + (s.availableStock || 0), 0);
  const pendingOrdersCount = (orders || []).filter(
    o => o.status === 'Submitted' || o.status === 'Confirmed' || o.status === 'Pending Fulfillment'
  ).length;
  const openTicketsCount = (tickets || []).filter(t => t.status === 'Open' || t.status === 'In Progress').length;

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 flex flex-col font-sans">
      {/* Toast Notification */}
      {notification && (
        <div className="fixed top-5 right-5 z-50 bg-slate-900 text-white px-5 py-3 rounded-xl shadow-2xl border border-slate-700 flex items-center space-x-3 transition-all animate-bounce">
          <CheckCircle2 className="w-5 h-5 text-emerald-400" />
          <span className="text-sm font-medium">{notification}</span>
        </div>
      )}

      {/* Top Header Navbar */}
      <header className="bg-slate-900 text-white border-b border-slate-800 px-6 py-4 flex flex-wrap justify-between items-center shadow-lg sticky top-0 z-40 gap-4">
        {/* Left: Authenticated Distributor Brand */}
        <div className="flex items-center space-x-3.5">
          <div className="bg-blue-600 p-2.5 rounded-xl shadow-md shrink-0">
            <Building2 className="w-6 h-6 text-white" />
          </div>
          <div>
            <div className="flex items-center space-x-2">
              <h1 className="text-lg sm:text-xl font-bold tracking-tight text-white">{distributor.name}</h1>
              <span className="text-xs bg-blue-500/20 text-blue-300 border border-blue-500/40 px-2 py-0.5 rounded-full font-mono">
                {distributor.code}
              </span>
            </div>
            <p className="text-xs text-slate-400 flex items-center space-x-2 mt-0.5">
              <span>{distributor.area}</span>
              <span>•</span>
              <span className="text-slate-300 font-mono">GSTIN: {distributor.gstin}</span>
              <span>•</span>
              <span className="text-blue-300">Depot: {distributor.defaultWarehouseName}</span>
            </p>
          </div>
        </div>

        {/* Right: IST Live Clock, Sync, Profile, Logout */}
        <div className="flex items-center space-x-3 flex-wrap gap-2">
          {/* Indian Standard Time (IST) Clock */}
          <div className="flex items-center space-x-2 bg-slate-800 border border-slate-700/80 px-3 py-1.5 rounded-lg text-xs font-mono text-slate-300">
            <Clock className="w-3.5 h-3.5 text-blue-400" />
            <span>{currentISTTime}</span>
          </div>

          {/* Salesforce Live Synced Indicator */}
          <div className="flex items-center space-x-2 bg-emerald-950/60 border border-emerald-500/40 px-3 py-1.5 rounded-full text-xs font-medium text-emerald-400">
            <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
            <span>Salesforce Live</span>
          </div>

          {/* Refresh Button */}
          <button
            onClick={async () => {
              await handleFullSync();
              triggerToast('Refreshed latest data directly from Salesforce!');
            }}
            className="p-2 bg-slate-800 hover:bg-slate-700 border border-slate-700 rounded-lg text-slate-300 hover:text-white transition cursor-pointer"
            title="Refresh DMS Data from Salesforce"
          >
            <RefreshCw className="w-4 h-4" />
          </button>

          {/* Distributor Profile Modal Button */}
          <button
            onClick={() => setShowProfileModal(true)}
            className="px-3 py-1.5 bg-slate-800 hover:bg-slate-700 border border-slate-700 rounded-lg text-xs text-slate-200 font-semibold transition cursor-pointer flex items-center space-x-1.5"
            title="View Distributor Profile & Credit Limit"
          >
            <Info className="w-3.5 h-3.5 text-blue-400" />
            <span>Profile</span>
          </button>

          {/* Log Out Button */}
          <button
            onClick={handleLogout}
            className="px-3 py-1.5 bg-rose-600/20 hover:bg-rose-600 text-rose-300 hover:text-white border border-rose-500/30 rounded-lg text-xs font-bold transition flex items-center space-x-1.5 cursor-pointer shadow-sm"
            title="Log out of distributor portal"
          >
            <LogOut className="w-3.5 h-3.5" />
            <span>Sign Out</span>
          </button>
        </div>
      </header>

      {/* Primary DMS Module Navigation Tabs */}
      <nav className="bg-white border-b border-slate-200 px-6 py-2 flex space-x-1 overflow-x-auto shadow-sm">
        <button
          onClick={() => setActiveTab('orders')}
          className={`flex items-center space-x-2 px-4 py-2.5 rounded-lg text-sm font-semibold transition cursor-pointer relative ${
            activeTab === 'orders'
              ? 'bg-blue-50 text-blue-700 shadow-sm'
              : 'text-slate-600 hover:bg-slate-100 hover:text-slate-900'
          }`}
        >
          <ShoppingCart className="w-4 h-4" />
          <span>Secondary Orders</span>
          {pendingOrdersCount > 0 && (
            <span className="bg-amber-500 text-white text-xs px-2 py-0.5 rounded-full ml-1">
              {pendingOrdersCount}
            </span>
          )}
        </button>

        <button
          onClick={() => setActiveTab('distributor_outlets')}
          className={`flex items-center space-x-2 px-4 py-2.5 rounded-lg text-sm font-semibold transition cursor-pointer ${
            activeTab === 'distributor_outlets'
              ? 'bg-blue-50 text-blue-700 shadow-sm'
              : 'text-slate-600 hover:bg-slate-100 hover:text-slate-900'
          }`}
        >
          <Store className="w-4 h-4" />
          <span>Retail Outlets & SR ({outlets.length})</span>
        </button>

        <button
          onClick={() => setActiveTab('inventory')}
          className={`flex items-center space-x-2 px-4 py-2.5 rounded-lg text-sm font-semibold transition cursor-pointer ${
            activeTab === 'inventory'
              ? 'bg-blue-50 text-blue-700 shadow-sm'
              : 'text-slate-600 hover:bg-slate-100 hover:text-slate-900'
          }`}
        >
          <Package className="w-4 h-4" />
          <span>Warehouse Stock & GRN</span>
        </button>

        <button
          onClick={() => setActiveTab('tickets')}
          className={`flex items-center space-x-2 px-4 py-2.5 rounded-lg text-sm font-semibold transition cursor-pointer relative ${
            activeTab === 'tickets'
              ? 'bg-blue-50 text-blue-700 shadow-sm'
              : 'text-slate-600 hover:bg-slate-100 hover:text-slate-900'
          }`}
        >
          <LifeBuoy className="w-4 h-4" />
          <span>Support Tickets</span>
          {openTicketsCount > 0 && (
            <span className="bg-blue-600 text-white text-xs px-2 py-0.5 rounded-full ml-1">
              {openTicketsCount}
            </span>
          )}
        </button>

        <button
          onClick={() => setActiveTab('returns_assets')}
          className={`flex items-center space-x-2 px-4 py-2.5 rounded-lg text-sm font-semibold transition cursor-pointer ${
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
          className={`flex items-center space-x-2 px-4 py-2.5 rounded-lg text-sm font-semibold transition cursor-pointer ${
            activeTab === 'reports'
              ? 'bg-blue-50 text-blue-700 shadow-sm'
              : 'text-slate-600 hover:bg-slate-100 hover:text-slate-900'
          }`}
        >
          <BarChart3 className="w-4 h-4" />
          <span>Performance & Coverage</span>
        </button>
      </nav>

      {/* Main Content Area */}
      <main className="flex-1 p-6 max-w-7xl w-full mx-auto space-y-6">
        {/* ========================================================= */}
        {/* MODULE 1: SECONDARY ORDERS & MOBILE SFA INTEGRATION */}
        {/* ========================================================= */}
        {activeTab === 'orders' && (
          <div className="space-y-6">
            <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm flex flex-wrap justify-between items-center gap-4">
              <div>
                <span className="text-xs font-bold text-blue-600 uppercase tracking-wider">
                  Mobile SFA Integration • Indian Standard Time
                </span>
                <h2 className="text-2xl font-bold text-slate-900 mt-1">Secondary Orders Queue</h2>
                <p className="text-sm text-slate-500">
                  Orders booked by field sales executives via SFA mobile application arrive here dynamically.
                </p>
              </div>

              <div className="flex items-center space-x-3">
                <div className="px-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-center">
                  <span className="text-xs text-slate-500 font-medium">Distributor Orders</span>
                  <div className="text-xl font-bold text-slate-800">{orders.length}</div>
                </div>
                <div className="px-4 py-2 bg-blue-50 border border-blue-200 rounded-xl text-center">
                  <span className="text-xs text-blue-600 font-medium">Billed Value</span>
                  <div className="text-xl font-bold text-blue-700">
                    ₹{orders.reduce((acc, o) => acc + (o.totalAmount || 0), 0).toLocaleString()}
                  </div>
                </div>
              </div>
            </div>

            {/* Orders Table */}
            <div className="bg-white border border-slate-200 rounded-2xl shadow-sm overflow-hidden">
              <div className="p-4 border-b border-slate-200 flex justify-between items-center">
                <h3 className="font-bold text-slate-900 flex items-center space-x-2">
                  <ShoppingCart className="w-5 h-5 text-blue-600" />
                  <span>Incoming Retail Bookings ({orders.length})</span>
                </h3>
                <span className="text-xs text-slate-500 font-mono">Territory: {distributor.area}</span>
              </div>

              {orders.length === 0 ? (
                <div className="p-12 text-center bg-white">
                  <ShoppingCart className="w-12 h-12 text-slate-300 mx-auto mb-3" />
                  <h4 className="text-base font-bold text-slate-800">No Orders for {distributor.name}</h4>
                  <p className="text-xs text-slate-500 max-w-sm mx-auto mt-1">
                    There are currently no secondary orders booked for this distributor. When field sales representatives book orders on SFA mobile, they will arrive here automatically in Indian Standard Time (IST).
                  </p>
                </div>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full text-left text-sm text-slate-700">
                    <thead className="bg-slate-100 text-slate-700 text-xs uppercase font-semibold border-b border-slate-200">
                      <tr>
                        <th className="px-4 py-3">Order Number & Booking Date (IST)</th>
                        <th className="px-4 py-3">Retail Outlet</th>
                        <th className="px-4 py-3">Sales Executive</th>
                        <th className="px-4 py-3">Order Total</th>
                        <th className="px-4 py-3">Fulfillment Status</th>
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
                              <div className="text-xs text-slate-500 flex items-center space-x-1 mt-0.5">
                                <Calendar className="w-3 h-3 text-slate-400" />
                                <span>{order.orderDate}</span>
                              </div>
                            </td>
                            <td className="px-4 py-3">
                              <div className="font-semibold text-slate-900">{order.retailerName}</div>
                              <span className="text-xs text-slate-500">{order.retailerShopName}</span>
                            </td>
                            <td className="px-4 py-3 text-xs font-semibold text-blue-700">
                              {order.salesExecutiveName}
                            </td>
                            <td className="px-4 py-3">
                              <div className="font-bold text-slate-900">₹{(order.totalAmount || 0).toLocaleString()}</div>
                              <div className="text-xs text-slate-500">{order.items?.length || 0} line items</div>
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
                              {order.items && order.items.length > 0 && (
                                <button
                                  onClick={() => setSelectedOrderForModal(order)}
                                  className="px-2.5 py-1 text-xs bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-lg font-medium inline-flex items-center space-x-1 cursor-pointer"
                                >
                                  <Eye className="w-3.5 h-3.5" />
                                  <span>Items</span>
                                </button>
                              )}

                              {order.status === 'Submitted' && (
                                <button
                                  onClick={() => handleOrderStatusUpdate(order.id, 'Confirmed')}
                                  className="px-2.5 py-1 text-xs bg-amber-600 hover:bg-amber-700 text-white rounded-lg font-medium cursor-pointer"
                                >
                                  Confirm
                                </button>
                              )}

                              {order.status === 'Confirmed' && (
                                <button
                                  onClick={() => handleOrderStatusUpdate(order.id, 'Dispatched')}
                                  className="px-2.5 py-1 text-xs bg-purple-600 hover:bg-purple-700 text-white rounded-lg font-medium inline-flex items-center space-x-1 cursor-pointer"
                                >
                                  <Truck className="w-3.5 h-3.5" />
                                  <span>Dispatch (Stock Out)</span>
                                </button>
                              )}

                              {order.status === 'Dispatched' && (
                                <button
                                  onClick={() => handleOrderStatusUpdate(order.id, 'Delivered')}
                                  className="px-2.5 py-1 text-xs bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg font-medium cursor-pointer"
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
              )}
            </div>
          </div>
        )}

        {/* ========================================================= */}
        {/* MODULE 2: RETAIL OUTLETS & SALES REPRESENTATIVES */}
        {/* ========================================================= */}
        {activeTab === 'distributor_outlets' && (
          <div className="space-y-6">
            <div className="bg-gradient-to-r from-blue-900 via-indigo-900 to-slate-900 text-white rounded-2xl p-6 shadow-md flex flex-wrap justify-between items-center gap-4">
              <div>
                <span className="text-blue-300 text-xs font-semibold uppercase tracking-wider">
                  Territory Operations
                </span>
                <h2 className="text-2xl font-bold mt-1">{distributor.name} — Retail Network</h2>
                <p className="text-sm text-blue-100 max-w-2xl mt-1">
                  Verified retail counters mapped to {distributor.name} in Salesforce.
                </p>
              </div>

              <div className="flex space-x-4">
                <div className="bg-white/10 backdrop-blur-md px-4 py-2 rounded-xl text-center border border-white/10">
                  <span className="text-xs text-blue-200">Mapped Outlets</span>
                  <div className="text-2xl font-bold">{outlets.length}</div>
                </div>
                <div className="bg-white/10 backdrop-blur-md px-4 py-2 rounded-xl text-center border border-white/10">
                  <span className="text-xs text-blue-200">Active Buyers</span>
                  <div className="text-2xl font-bold">
                    {outlets.filter(o => o.status === 'Active Buyer').length}
                  </div>
                </div>
              </div>
            </div>

            {/* Real Salesforce Sales Representatives */}
            <div>
              <h3 className="text-md font-bold text-slate-800 flex items-center space-x-2 mb-3">
                <Users className="w-5 h-5 text-blue-600" />
                <span>Sales Executives (Salesforce Live)</span>
              </h3>

              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                {employees.map(emp => (
                  <div key={emp.id} className="bg-white border border-slate-200 rounded-xl p-4 shadow-sm space-y-2">
                    <div className="flex items-center space-x-3">
                      <div className="w-10 h-10 bg-blue-100 text-blue-700 font-bold rounded-full flex items-center justify-center text-sm">
                        {emp.name.split(' ').map(n => n[0]).join('')}
                      </div>
                      <div>
                        <h4 className="font-bold text-slate-900 text-sm">{emp.name}</h4>
                        <span className="text-xs text-slate-500 font-mono">{emp.code} • {emp.designation}</span>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Retail Outlets Table */}
            <div className="bg-white border border-slate-200 rounded-2xl shadow-sm overflow-hidden">
              <div className="p-4 border-b border-slate-200 flex flex-wrap justify-between items-center gap-3">
                <div>
                  <h3 className="font-bold text-slate-900 flex items-center space-x-2">
                    <Store className="w-5 h-5 text-blue-600" />
                    <span>Retail Outlets Network ({filteredOutlets.length})</span>
                  </h3>
                  <p className="text-xs text-slate-500">Retail counters supplied by {distributor.name}</p>
                </div>

                <div className="relative w-full sm:w-64">
                  <Search className="w-4 h-4 text-slate-400 absolute left-3 top-2.5" />
                  <input
                    type="text"
                    placeholder="Search outlet or code..."
                    value={outletSearch}
                    onChange={e => setOutletSearch(e.target.value)}
                    className="w-full pl-9 pr-3 py-1.5 text-sm bg-slate-50 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>

              {filteredOutlets.length === 0 ? (
                <div className="p-12 text-center bg-white">
                  <Store className="w-12 h-12 text-slate-300 mx-auto mb-3" />
                  <h4 className="text-base font-bold text-slate-800">No Retail Outlets Mapped</h4>
                  <p className="text-xs text-slate-500 max-w-sm mx-auto mt-1">
                    No retail outlets are assigned to {distributor.name} in Salesforce. When retailers are linked to this distributor, they will appear here.
                  </p>
                </div>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full text-left text-sm text-slate-700">
                    <thead className="bg-slate-100 text-slate-700 text-xs uppercase font-semibold border-b border-slate-200">
                      <tr>
                        <th className="px-4 py-3">Outlet Code & Name</th>
                        <th className="px-4 py-3">Shop & Contact</th>
                        <th className="px-4 py-3">Credit Limit / Balance</th>
                        <th className="px-4 py-3">Verification</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100">
                      {filteredOutlets.map(outlet => (
                        <tr key={outlet.id} className="hover:bg-slate-50 transition">
                          <td className="px-4 py-3">
                            <div className="font-bold text-slate-900">{outlet.name}</div>
                            <span className="text-xs font-mono text-slate-500">{outlet.code}</span>
                          </td>
                          <td className="px-4 py-3">
                            <div className="text-slate-800">{outlet.shopName}</div>
                            <div className="text-xs text-slate-500 flex items-center space-x-1">
                              <Phone className="w-3 h-3 text-slate-400" />
                              <span>{outlet.ownerPhone}</span>
                            </div>
                          </td>
                          <td className="px-4 py-3 text-xs">
                            <div>Limit: ₹{outlet.creditLimit.toLocaleString()}</div>
                            <div className={outlet.creditHold ? 'text-red-600 font-bold' : 'text-slate-600'}>
                              Due: ₹{outlet.outstandingBalance.toLocaleString()}
                            </div>
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
              )}
            </div>
          </div>
        )}

        {/* ========================================================= */}
        {/* MODULE 3: WAREHOUSE STOCK & GRN (4 PROCESSES) */}
        {/* ========================================================= */}
        {activeTab === 'inventory' && (
          <div className="space-y-6">
            <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm flex flex-wrap justify-between items-center gap-4">
              <div>
                <span className="text-xs font-bold text-blue-600 uppercase tracking-wider">
                  Depot Warehouse Operations
                </span>
                <h2 className="text-2xl font-bold text-slate-900 mt-1">Warehouse Stock & GRN</h2>
                <p className="text-sm text-slate-500">
                  Depot: <strong>{distributor.defaultWarehouseName}</strong> • Managed in Indian Standard Time (IST).
                </p>
              </div>

              <button
                onClick={() => setShowGRNModal(true)}
                className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white text-sm font-semibold rounded-xl shadow-sm flex items-center space-x-2 transition cursor-pointer"
              >
                <ArrowDownToLine className="w-4 h-4" />
                <span>Receive Primary Stock (GRN)</span>
              </button>
            </div>

            {/* Inventory 4 Processes Switcher */}
            <div className="flex border-b border-slate-200 bg-white rounded-t-xl px-4 pt-3 space-x-2">
              <button
                onClick={() => setInvSubTab('stock_held')}
                className={`px-4 py-2.5 text-sm font-semibold border-b-2 transition cursor-pointer flex items-center space-x-2 ${
                  invSubTab === 'stock_held'
                    ? 'border-blue-600 text-blue-600'
                    : 'border-transparent text-slate-500 hover:text-slate-800'
                }`}
              >
                <Package className="w-4 h-4" />
                <span>Live Warehouse Stock ({stockHeld.length})</span>
              </button>

              <button
                onClick={() => setInvSubTab('ledger')}
                className={`px-4 py-2.5 text-sm font-semibold border-b-2 transition cursor-pointer flex items-center space-x-2 ${
                  invSubTab === 'ledger'
                    ? 'border-blue-600 text-blue-600'
                    : 'border-transparent text-slate-500 hover:text-slate-800'
                }`}
              >
                <FileText className="w-4 h-4" />
                <span>Movement Ledger & GRN Logs</span>
              </button>
            </div>

            {/* Live Stock Held */}
            {invSubTab === 'stock_held' && (
              <div className="bg-white border border-slate-200 rounded-b-xl shadow-sm overflow-hidden p-4 space-y-4">
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                  <div className="p-4 bg-blue-50 border border-blue-100 rounded-xl">
                    <span className="text-xs text-blue-600 font-semibold">Available Stock</span>
                    <div className="text-2xl font-bold text-blue-900">{totalStockUnits.toLocaleString()} Cases</div>
                  </div>
                  <div className="p-4 bg-amber-50 border border-amber-100 rounded-xl">
                    <span className="text-xs text-amber-600 font-semibold">Reserved for Orders</span>
                    <div className="text-2xl font-bold text-amber-900">
                      {stockHeld.reduce((a, s) => a + (s.reservedStock || 0), 0)} Cases
                    </div>
                  </div>
                  <div className="p-4 bg-emerald-50 border border-emerald-100 rounded-xl">
                    <span className="text-xs text-emerald-600 font-semibold">Physical On-Hand</span>
                    <div className="text-2xl font-bold text-emerald-900">
                      {stockHeld.reduce((a, s) => a + (s.physicalStock || 0), 0)} Cases
                    </div>
                  </div>
                </div>

                {stockHeld.length === 0 ? (
                  <div className="p-12 text-center bg-white">
                    <Package className="w-12 h-12 text-slate-300 mx-auto mb-3" />
                    <h4 className="text-base font-bold text-slate-800">Warehouse Stock Empty</h4>
                    <p className="text-xs text-slate-500 max-w-sm mx-auto mt-1">
                      No stock records found for {distributor.name}'s warehouse in Salesforce. Click "Receive Primary Stock (GRN)" to log arriving shipments.
                    </p>
                  </div>
                ) : (
                  <div className="overflow-x-auto">
                    <table className="w-full text-left text-sm text-slate-700">
                      <thead className="bg-slate-100 text-slate-700 text-xs uppercase font-semibold border-b border-slate-200">
                        <tr>
                          <th className="px-4 py-3">Product Name & SKU</th>
                          <th className="px-4 py-3">Warehouse Depot</th>
                          <th className="px-4 py-3">Physical Stock</th>
                          <th className="px-4 py-3">Reserved</th>
                          <th className="px-4 py-3">Available Stock</th>
                          <th className="px-4 py-3">Status</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-slate-100">
                        {stockHeld.map(item => (
                          <tr key={item.id} className="hover:bg-slate-50 transition">
                            <td className="px-4 py-3 font-semibold text-slate-900">
                              <div>{item.productName}</div>
                              <span className="text-xs text-slate-400 font-mono">{item.productCode}</span>
                            </td>
                            <td className="px-4 py-3 text-xs text-slate-600">{item.warehouseName}</td>
                            <td className="px-4 py-3 font-bold text-slate-800">{item.physicalStock}</td>
                            <td className="px-4 py-3 text-amber-600 font-semibold">{item.reservedStock}</td>
                            <td className="px-4 py-3 font-bold text-emerald-600 text-base">
                              {item.availableStock}
                            </td>
                            <td className="px-4 py-3">
                              <span
                                className={`text-xs px-2.5 py-0.5 rounded-full font-semibold ${
                                  item.status === 'In Stock'
                                    ? 'bg-emerald-100 text-emerald-800'
                                    : 'bg-amber-100 text-amber-800'
                                }`}
                              >
                                {item.status}
                              </span>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
              </div>
            )}

            {/* Movement Ledger */}
            {invSubTab === 'ledger' && (
              <div className="bg-white border border-slate-200 rounded-b-xl shadow-sm p-6 space-y-4">
                <h3 className="font-bold text-slate-900">Stock Movement Audit Ledger (Indian Standard Time)</h3>
                {stockMovements.length === 0 ? (
                  <div className="p-8 text-center text-slate-500 text-xs">
                    No movement records yet. Creating GRN or dispatching orders will generate timestamped audit entries.
                  </div>
                ) : (
                  <div className="overflow-x-auto">
                    <table className="w-full text-left text-sm text-slate-700">
                      <thead className="bg-slate-100 text-slate-700 text-xs uppercase font-semibold border-b border-slate-200">
                        <tr>
                          <th className="px-4 py-3">Date & Time (IST)</th>
                          <th className="px-4 py-3">Type</th>
                          <th className="px-4 py-3">Reference #</th>
                          <th className="px-4 py-3">Product Name</th>
                          <th className="px-4 py-3">Quantity Delta</th>
                          <th className="px-4 py-3">Resulting Stock</th>
                          <th className="px-4 py-3">Notes</th>
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
                                    : 'bg-purple-100 text-purple-800'
                                }`}
                              >
                                {m.type}
                              </span>
                            </td>
                            <td className="px-4 py-3 font-mono text-xs font-semibold">{m.referenceNumber}</td>
                            <td className="px-4 py-3 font-medium text-slate-900">{m.productName}</td>
                            <td className="px-4 py-3 font-bold text-emerald-600">+{m.quantityDelta}</td>
                            <td className="px-4 py-3 font-bold text-slate-800">{m.resultingStock}</td>
                            <td className="px-4 py-3 text-xs text-slate-500">{m.notes}</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
              </div>
            )}
          </div>
        )}

        {/* ========================================================= */}
        {/* MODULE 4: SUPPORT TICKETS (Connected to Salesforce Ticket__c) */}
        {/* ========================================================= */}
        {activeTab === 'tickets' && (
          <div className="space-y-6">
            <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm flex flex-wrap justify-between items-center gap-4">
              <div>
                <span className="text-xs font-bold text-blue-600 uppercase tracking-wider">
                  Connected with Salesforce Ticket__c
                </span>
                <h2 className="text-2xl font-bold text-slate-900 mt-1">Distributor Support Tickets</h2>
                <p className="text-sm text-slate-500">
                  Raise damage, delivery delay, and billing issues directly into Salesforce.
                </p>
              </div>

              <button
                onClick={() => setShowNewTicketModal(true)}
                className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white text-sm font-semibold rounded-xl shadow-sm flex items-center space-x-2 cursor-pointer"
              >
                <Plus className="w-4 h-4" />
                <span>Raise New Ticket</span>
              </button>
            </div>

            {/* Filter Tabs */}
            <div className="flex border-b border-slate-200 space-x-2">
              {['All', 'Open', 'In Progress', 'Closed'].map(status => (
                <button
                  key={status}
                  onClick={() => setSelectedTicketFilter(status)}
                  className={`px-4 py-2 text-sm font-semibold border-b-2 transition cursor-pointer ${
                    selectedTicketFilter === status
                      ? 'border-blue-600 text-blue-600'
                      : 'border-transparent text-slate-500 hover:text-slate-800'
                  }`}
                >
                  {status}
                </button>
              ))}
            </div>

            {filteredTickets.length === 0 ? (
              <div className="p-12 text-center bg-white rounded-2xl border border-slate-200">
                <LifeBuoy className="w-12 h-12 text-slate-300 mx-auto mb-3" />
                <h4 className="text-base font-bold text-slate-800">No Tickets Found</h4>
                <p className="text-xs text-slate-500 max-w-sm mx-auto mt-1">
                  No support tickets match the selected status. Click "Raise New Ticket" to report any stock damage or dispatch delay directly to Salesforce.
                </p>
              </div>
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {filteredTickets.map(ticket => (
                  <div key={ticket.id} className="bg-white border border-slate-200 rounded-xl p-5 shadow-sm space-y-3">
                    <div className="flex justify-between items-start">
                      <div>
                        <span className="text-xs font-mono text-slate-400">{ticket.ticketNumber}</span>
                        <h4 className="font-bold text-slate-900 mt-0.5">{ticket.subject}</h4>
                      </div>
                      <span className="text-xs px-2.5 py-0.5 rounded-full font-bold border bg-blue-100 text-blue-800 border-blue-200">
                        {ticket.status}
                      </span>
                    </div>

                    <p className="text-xs text-slate-600">{ticket.description}</p>

                    <div className="text-xs text-slate-500 flex flex-wrap gap-2 pt-2 border-t border-slate-100">
                      <span className="bg-slate-100 px-2 py-0.5 rounded font-medium">Category: {ticket.category}</span>
                      <span className="bg-slate-100 px-2 py-0.5 rounded font-medium">Priority: {ticket.priority}</span>
                      <span className="bg-slate-100 px-2 py-0.5 rounded font-medium">Date (IST): {ticket.raisedDate}</span>
                    </div>

                    <div className="text-xs text-blue-700 font-medium">
                      Assigned: {ticket.assignedOfficer}
                    </div>

                    <div className="pt-2 flex justify-end space-x-2">
                      {ticket.status === 'Open' && (
                        <button
                          onClick={() => handleUpdateTicketStatus(ticket.id, 'In Progress')}
                          className="px-2.5 py-1 text-xs bg-amber-600 text-white rounded font-medium cursor-pointer"
                        >
                          Mark In Progress
                        </button>
                      )}
                      {ticket.status === 'In Progress' && (
                        <button
                          onClick={() => handleUpdateTicketStatus(ticket.id, 'Closed', 'Issue resolved by DO Desk.')}
                          className="px-2.5 py-1 text-xs bg-emerald-600 text-white rounded font-medium cursor-pointer"
                        >
                          Resolve & Close
                        </button>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* ========================================================= */}
        {/* MODULE 5: RETURNS & ASSETS */}
        {/* ========================================================= */}
        {activeTab === 'returns_assets' && (
          <div className="space-y-6">
            <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm flex flex-wrap justify-between items-center gap-4">
              <div>
                <span className="text-xs font-bold text-blue-600 uppercase tracking-wider">
                  Field Assets & Reverse Logistics
                </span>
                <h2 className="text-2xl font-bold text-slate-900 mt-1">Returns and Asset Tracking</h2>
                <p className="text-sm text-slate-500">
                  Track retail counter returns and company display fixtures recorded in Salesforce.
                </p>
              </div>

              <div className="flex border border-slate-200 bg-slate-50 p-1 rounded-xl">
                <button
                  onClick={() => setReturnAssetSubTab('returns')}
                  className={`px-4 py-1.5 rounded-lg text-xs font-bold transition cursor-pointer ${
                    returnAssetSubTab === 'returns'
                      ? 'bg-white text-blue-700 shadow-sm'
                      : 'text-slate-600 hover:text-slate-900'
                  }`}
                >
                  Product Returns ({returns.length})
                </button>
                <button
                  onClick={() => setReturnAssetSubTab('assets')}
                  className={`px-4 py-1.5 rounded-lg text-xs font-bold transition cursor-pointer ${
                    returnAssetSubTab === 'assets'
                      ? 'bg-white text-blue-700 shadow-sm'
                      : 'text-slate-600 hover:text-slate-900'
                  }`}
                >
                  Company Assets ({assets.length})
                </button>
              </div>
            </div>

            {returnAssetSubTab === 'returns' && (
              <div className="bg-white border border-slate-200 rounded-2xl shadow-sm overflow-hidden p-4 space-y-4">
                <h3 className="font-bold text-slate-900 flex items-center space-x-2">
                  <RotateCcw className="w-5 h-5 text-blue-600" />
                  <span>Product Returns Log ({returns.length})</span>
                </h3>

                {returns.length === 0 ? (
                  <div className="p-8 text-center text-slate-500 text-xs">
                    No product returns logged for this distributor territory in Salesforce.
                  </div>
                ) : (
                  <div className="overflow-x-auto">
                    <table className="w-full text-left text-sm text-slate-700">
                      <thead className="bg-slate-100 text-slate-700 text-xs uppercase font-semibold border-b border-slate-200">
                        <tr>
                          <th className="px-4 py-3">Return # & Date (IST)</th>
                          <th className="px-4 py-3">Retail Outlet</th>
                          <th className="px-4 py-3">Product Name</th>
                          <th className="px-4 py-3">Quantity</th>
                          <th className="px-4 py-3">Reason</th>
                          <th className="px-4 py-3">Status</th>
                          <th className="px-4 py-3 text-right">Actions</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-slate-100">
                        {returns.map(ret => (
                          <tr key={ret.id} className="hover:bg-slate-50 transition">
                            <td className="px-4 py-3 font-mono text-xs font-bold">{ret.returnNumber}</td>
                            <td className="px-4 py-3 font-semibold text-slate-900">{ret.outletName}</td>
                            <td className="px-4 py-3">{ret.productName}</td>
                            <td className="px-4 py-3 font-bold text-slate-800">{ret.quantity} Units</td>
                            <td className="px-4 py-3 text-xs text-rose-700 font-medium">{ret.returnReason}</td>
                            <td className="px-4 py-3">
                              <span className="text-xs px-2 py-0.5 rounded-full font-bold bg-amber-100 text-amber-800">
                                {ret.status}
                              </span>
                            </td>
                            <td className="px-4 py-3 text-right">
                              {ret.status === 'Requested' && (
                                <button
                                  onClick={() => handleApproveReturn(ret.id)}
                                  className="px-2.5 py-1 text-xs bg-emerald-600 hover:bg-emerald-700 text-white rounded font-medium cursor-pointer"
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
                )}
              </div>
            )}

            {returnAssetSubTab === 'assets' && (
              <div className="bg-white border border-slate-200 rounded-2xl shadow-sm overflow-hidden p-4 space-y-4">
                <h3 className="font-bold text-slate-900 flex items-center space-x-2">
                  <ShieldCheck className="w-5 h-5 text-blue-600" />
                  <span>Company Assigned Assets Tracking ({assets.length})</span>
                </h3>

                {assets.length === 0 ? (
                  <div className="p-8 text-center text-slate-500 text-xs">
                    No company assets currently recorded for this territory.
                  </div>
                ) : (
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    {assets.map(asset => (
                      <div key={asset.id} className="bg-slate-50 border border-slate-200 rounded-xl p-4 space-y-2">
                        <div className="flex justify-between items-start">
                          <div>
                            <span className="text-xs font-mono text-slate-400">{asset.assetNumber}</span>
                            <h4 className="font-bold text-slate-900">{asset.assetName}</h4>
                            <span className="text-xs text-slate-500">Placed at: {asset.placedOutletName}</span>
                          </div>
                          <span className="text-xs px-2.5 py-0.5 rounded-full font-bold bg-emerald-100 text-emerald-800">
                            {asset.status}
                          </span>
                        </div>
                        <div className="text-xs text-slate-500 pt-2 border-t border-slate-200 flex justify-between">
                          <span>Verified: {asset.lastServiceDate}</span>
                          <span>Category: {asset.category}</span>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            )}
          </div>
        )}

        {/* ========================================================= */}
        {/* MODULE 6: PERFORMANCE & COVERAGE REPORTS */}
        {/* ========================================================= */}
        {activeTab === 'reports' && (
          <div className="space-y-6">
            <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm flex flex-wrap justify-between items-center gap-4">
              <div>
                <span className="text-xs font-bold text-blue-600 uppercase tracking-wider">
                  Manager Analytics • Indian Standard Time
                </span>
                <h2 className="text-2xl font-bold text-slate-900 mt-1">Distributor Performance & Target</h2>
                <p className="text-sm text-slate-500">
                  Real-time sales achievements and outlet coverage for <strong>{distributor.name}</strong>.
                </p>
              </div>
              <span className="text-xs bg-slate-100 text-slate-600 px-3 py-1.5 rounded-lg font-mono">
                {salesReport.period}
              </span>
            </div>

            {/* Sales vs Target */}
            <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4">
              <h3 className="font-bold text-slate-900 text-lg flex items-center space-x-2">
                <TrendingUp className="w-5 h-5 text-blue-600" />
                <span>Sales Representative Achievement</span>
              </h3>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {salesReport.srMetrics.map((sr, idx) => (
                  <div key={idx} className="bg-slate-50 border border-slate-200 rounded-xl p-4 space-y-3">
                    <div className="flex justify-between items-start">
                      <div>
                        <h4 className="font-bold text-slate-900">{sr.srName}</h4>
                        <span className="text-xs text-slate-500">Designation: {sr.designation || 'Sales Executive'}</span>
                      </div>
                      <span className="text-sm font-bold text-emerald-600 bg-emerald-50 border border-emerald-200 px-2.5 py-1 rounded-lg">
                        ₹{(sr.actual || 0).toLocaleString()} Billed
                      </span>
                    </div>

                    <div className="w-full bg-slate-200 rounded-full h-3 overflow-hidden">
                      <div
                        className="bg-blue-600 h-3 rounded-full transition-all"
                        style={{ width: `${Math.min(sr.achievementPct || 75, 100)}%` }}
                      ></div>
                    </div>

                    <div className="flex justify-between text-xs text-slate-600 pt-1">
                      <span>Target: ₹{sr.target.toLocaleString()}</span>
                      <span>Progress: <strong>{sr.achievementPct}%</strong></span>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Outlet Coverage Overview */}
            <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm space-y-4">
              <h3 className="font-bold text-slate-900 text-lg flex items-center space-x-2">
                <Store className="w-5 h-5 text-emerald-600" />
                <span>Outlet Coverage Status</span>
              </h3>

              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <div className="p-4 bg-emerald-50 border border-emerald-200 rounded-xl text-center">
                  <span className="text-xs text-emerald-700 font-semibold">Active Buyers</span>
                  <div className="text-2xl font-bold text-emerald-900">{coverageReport.activeBuyers} Outlets</div>
                </div>
                <div className="p-4 bg-rose-50 border border-rose-200 rounded-xl text-center">
                  <span className="text-xs text-rose-700 font-semibold">Credit Hold / Attention</span>
                  <div className="text-2xl font-bold text-rose-900">{coverageReport.inactiveOutlets} Outlets</div>
                </div>
                <div className="p-4 bg-blue-50 border border-blue-200 rounded-xl text-center">
                  <span className="text-xs text-blue-700 font-semibold">Coverage Rate</span>
                  <div className="text-2xl font-bold text-blue-900">{coverageReport.coveragePct}%</div>
                </div>
              </div>
            </div>
          </div>
        )}
      </main>

      {/* ========================================================= */}
      {/* MODAL 1: ORDER LINE ITEMS */}
      {/* ========================================================= */}
      {selectedOrderForModal && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-xl w-full p-6 shadow-2xl border border-slate-200 space-y-4">
            <div className="flex justify-between items-start border-b border-slate-100 pb-3">
              <div>
                <span className="text-xs font-mono text-slate-400">{selectedOrderForModal.orderNumber}</span>
                <h3 className="text-lg font-bold text-slate-900">{selectedOrderForModal.retailerName}</h3>
                <span className="text-xs text-slate-500">Booking Date: {selectedOrderForModal.orderDate}</span>
              </div>
              <button
                onClick={() => setSelectedOrderForModal(null)}
                className="text-slate-400 hover:text-slate-700 cursor-pointer"
              >
                ✕
              </button>
            </div>

            <div className="space-y-2">
              <h4 className="text-xs font-bold text-slate-700 uppercase tracking-wider">Order Items:</h4>
              <div className="divide-y divide-slate-100 border border-slate-100 rounded-xl overflow-hidden">
                {selectedOrderForModal.items.map(item => (
                  <div key={item.id} className="p-3 flex justify-between items-center text-sm">
                    <div>
                      <div className="font-semibold text-slate-900">{item.productName}</div>
                      <span className="text-xs text-slate-500">Qty: {item.quantity} cases @ ₹{item.unitPrice}</span>
                    </div>
                    <span className="font-bold text-slate-800">₹{(item.lineTotal || 0).toLocaleString()}</span>
                  </div>
                ))}
              </div>
            </div>

            <div className="pt-3 border-t border-slate-100 flex justify-between items-center">
              <div>
                <span className="text-xs text-slate-500 block">Total Billed:</span>
                <span className="text-xl font-bold text-slate-900">₹{(selectedOrderForModal.totalAmount || 0).toLocaleString()}</span>
              </div>
              <button
                onClick={() => setSelectedOrderForModal(null)}
                className="px-5 py-2 bg-slate-900 hover:bg-slate-800 text-white text-xs font-semibold rounded-xl cursor-pointer"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ========================================================= */}
      {/* MODAL 2: GRN CREATION */}
      {/* ========================================================= */}
      {showGRNModal && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
          <form
            onSubmit={handleCreateGRN}
            className="bg-white rounded-2xl max-w-lg w-full p-6 shadow-2xl border border-slate-200 space-y-4"
          >
            <div className="flex justify-between items-center border-b border-slate-100 pb-3">
              <div>
                <h3 className="text-lg font-bold text-slate-900">Receive Stock — Goods Received Note (GRN)</h3>
                <p className="text-xs text-slate-500">Depot: {distributor.defaultWarehouseName} • Timezone: IST</p>
              </div>
              <button
                type="button"
                onClick={() => setShowGRNModal(false)}
                className="text-slate-400 hover:text-slate-700 cursor-pointer"
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
                  <option value="Herbal Shampoo 200ml">Herbal Shampoo 200ml</option>
                  <option value="Organic Green Tea 100g">Organic Green Tea 100g</option>
                  <option value="Royal Almond Shampoo 250ml">Royal Almond Shampoo 250ml</option>
                  <option value="Parle-G Original Glucose Biscuit">Parle-G Original Glucose Biscuit</option>
                  <option value="Monaco Classic Salted Crackers">Monaco Classic Salted Crackers</option>
                </select>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-xs font-semibold text-slate-700 block mb-1">Received Quantity (Cases)</label>
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
                  <label className="text-xs font-semibold text-slate-700 block mb-1">Factory PO Reference #</label>
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
                className="px-4 py-2 border border-slate-200 text-slate-700 text-xs font-semibold rounded-lg cursor-pointer"
              >
                Cancel
              </button>
              <button
                type="submit"
                className="px-5 py-2 bg-blue-600 hover:bg-blue-700 text-white text-xs font-bold rounded-lg shadow-sm cursor-pointer"
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
                <h3 className="text-lg font-bold text-slate-900">Raise Issue to Salesforce DO Desk</h3>
                <p className="text-xs text-slate-500">Syncs directly to Salesforce custom object Ticket__c</p>
              </div>
              <button
                type="button"
                onClick={() => setShowNewTicketModal(false)}
                className="text-slate-400 hover:text-slate-700 cursor-pointer"
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
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-lg text-sm font-medium"
                  >
                    <option value="Damaged Stock">Damaged Stock</option>
                    <option value="Product Quality">Product Quality</option>
                    <option value="Delayed Delivery">Delayed Delivery</option>
                    <option value="Billing Issue">Billing Issue</option>
                    <option value="Scheme Dispute">Scheme Dispute</option>
                    <option value="Display Asset">Display Asset</option>
                    <option value="Other">Other</option>
                  </select>
                </div>

                <div>
                  <label className="text-xs font-semibold text-slate-700 block mb-1">Priority</label>
                  <select
                    value={ticketPriority}
                    onChange={e => setTicketPriority(e.target.value)}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-lg text-sm font-medium"
                  >
                    <option value="Urgent">Urgent</option>
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
                  placeholder="e.g. 5 cartons of biscuits crushed during transit"
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
                  placeholder="Provide batch details, affected carton count, vehicle number..."
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
                className="px-4 py-2 border border-slate-200 text-slate-700 text-xs font-semibold rounded-lg cursor-pointer"
              >
                Cancel
              </button>
              <button
                type="submit"
                className="px-5 py-2 bg-blue-600 hover:bg-blue-700 text-white text-xs font-bold rounded-lg shadow-sm cursor-pointer"
              >
                Submit Live to Salesforce
              </button>
            </div>
          </form>
        </div>
      )}

      {/* ========================================================= */}
      {/* MODAL 4: DISTRIBUTOR PROFILE & CREDIT LIMIT */}
      {/* ========================================================= */}
      {showProfileModal && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-md w-full p-6 sm:p-8 shadow-2xl border border-slate-200 space-y-5">
            <div className="flex justify-between items-start border-b border-slate-100 pb-3">
              <div>
                <span className="text-xs font-mono text-blue-600 uppercase font-bold tracking-wider">
                  Distributor Profile
                </span>
                <h3 className="text-xl font-bold text-slate-900 mt-0.5">{distributor.name}</h3>
              </div>
              <button
                onClick={() => setShowProfileModal(false)}
                className="text-slate-400 hover:text-slate-700 cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-3 text-sm">
              <div className="flex items-center justify-between p-3 bg-slate-50 rounded-xl">
                <span className="text-slate-500 text-xs">Distributor Code</span>
                <span className="font-mono font-bold text-slate-900">{distributor.code}</span>
              </div>

              <div className="flex items-center justify-between p-3 bg-slate-50 rounded-xl">
                <span className="text-slate-500 text-xs">GSTIN Number</span>
                <span className="font-mono font-bold text-slate-900">{distributor.gstin}</span>
              </div>

              <div className="flex items-center justify-between p-3 bg-emerald-50 rounded-xl">
                <span className="text-emerald-700 text-xs font-medium">Sanctioned Credit Limit</span>
                <span className="font-bold text-emerald-900">₹{distributor.creditLimit.toLocaleString()}</span>
              </div>

              <div className="flex items-center justify-between p-3 bg-blue-50 rounded-xl">
                <span className="text-blue-700 text-xs font-medium">Current Outstanding</span>
                <span className="font-bold text-blue-900">₹{distributor.currentOutstanding.toLocaleString()}</span>
              </div>

              <div className="flex items-start justify-between p-3 bg-slate-50 rounded-xl">
                <span className="text-slate-500 text-xs">Primary Depot</span>
                <span className="font-semibold text-slate-900 text-right text-xs">
                  {distributor.defaultWarehouseName}
                </span>
              </div>

              <div className="flex items-start justify-between p-3 bg-slate-50 rounded-xl">
                <span className="text-slate-500 text-xs">Territory Area</span>
                <span className="font-semibold text-slate-900 text-right text-xs">
                  {distributor.area}
                </span>
              </div>
            </div>

            <div className="pt-3 border-t border-slate-100 flex justify-end">
              <button
                onClick={() => setShowProfileModal(false)}
                className="w-full py-2.5 bg-slate-900 hover:bg-slate-800 text-white text-xs font-bold rounded-xl cursor-pointer"
              >
                Close Profile
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
