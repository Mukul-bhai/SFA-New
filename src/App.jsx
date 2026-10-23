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
  X,
  Layers,
  Boxes,
  FileCheck,
  Check,
  Trash2
} from 'lucide-react';
import { DMSDataService, PARLE_PRODUCTS } from './services/api';
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
  const [primaryOrders, setPrimaryOrders] = useState(() => DMSDataService.getPrimaryOrders());
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
  const [primaryOrderSearch, setPrimaryOrderSearch] = useState('');
  const [primaryOrderStatusFilter, setPrimaryOrderStatusFilter] = useState('All');

  // Modals
  const [selectedOrderForModal, setSelectedOrderForModal] = useState(null);
  const [selectedPrimaryOrderForModal, setSelectedPrimaryOrderForModal] = useState(null);
  const [showNewPrimaryOrderModal, setShowNewPrimaryOrderModal] = useState(false);
  const [showGRNModal, setShowGRNModal] = useState(false);
  const [showNewTicketModal, setShowNewTicketModal] = useState(false);
  const [showProfileModal, setShowProfileModal] = useState(false);

  // Form State: New Primary Order to Depot
  const [primaryDepot, setPrimaryDepot] = useState('Parle Central Depot A');
  const [primaryRemarks, setPrimaryRemarks] = useState('');
  const [isSubmittingPrimaryOrder, setIsSubmittingPrimaryOrder] = useState(false);
  const [primaryOrderLines, setPrimaryOrderLines] = useState([
    {
      productId: PARLE_PRODUCTS[0].id,
      productName: PARLE_PRODUCTS[0].name,
      quantity: 50,
      unitPrice: Math.round(PARLE_PRODUCTS[0].rbp * PARLE_PRODUCTS[0].packCase)
    }
  ]);

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
    setPrimaryOrders(DMSDataService.getPrimaryOrders());
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

  const addPrimaryOrderLine = () => {
    const defaultProd = PARLE_PRODUCTS[0];
    setPrimaryOrderLines(prev => [
      ...prev,
      {
        productId: defaultProd.id,
        productName: defaultProd.name,
        quantity: 25,
        unitPrice: Math.round(defaultProd.rbp * defaultProd.packCase)
      }
    ]);
  };

  const removePrimaryOrderLine = (index) => {
    if (primaryOrderLines.length <= 1) return;
    setPrimaryOrderLines(prev => prev.filter((_, i) => i !== index));
  };

  const updatePrimaryOrderLine = (index, field, value) => {
    setPrimaryOrderLines(prev => {
      const updated = [...prev];
      if (field === 'productId') {
        const prod = PARLE_PRODUCTS.find(p => p.id === value) || PARLE_PRODUCTS[0];
        updated[index] = {
          ...updated[index],
          productId: prod.id,
          productName: prod.name,
          unitPrice: Math.round(prod.rbp * prod.packCase)
        };
      } else {
        updated[index] = {
          ...updated[index],
          [field]: field === 'quantity' || field === 'unitPrice' ? Number(value) : value
        };
      }
      return updated;
    });
  };

  const handleCreatePrimaryOrder = async (e) => {
    e.preventDefault();
    const validLines = (primaryOrderLines || []).filter(l => (Number(l.quantity) || 0) > 0);
    if (validLines.length === 0) {
      alert("Please specify at least one product SKU with quantity > 0 cases.");
      return;
    }
    try {
      setIsSubmittingPrimaryOrder(true);
      const created = await DMSDataService.createPrimaryOrder({
        items: validLines,
        plantName: primaryDepot,
        remarks: primaryRemarks
      });
      setShowNewPrimaryOrderModal(false);
      setPrimaryRemarks('');
      setPrimaryOrderLines([
        {
          productId: PARLE_PRODUCTS[0].id,
          productName: PARLE_PRODUCTS[0].name,
          quantity: 50,
          unitPrice: Math.round(PARLE_PRODUCTS[0].rbp * PARLE_PRODUCTS[0].packCase)
        }
      ]);
      reloadData();
      triggerToast(`Primary Order [${created.orderNumber}] created & synced to Salesforce!`);
    } catch (err) {
      triggerToast('Error placing primary order: ' + (err?.message || err));
    } finally {
      setIsSubmittingPrimaryOrder(false);
    }
  };

  const handleReceivePrimaryGRN = async (orderId) => {
    try {
      const res = await DMSDataService.receivePrimaryOrderGRN(orderId);
      if (res.success) {
        reloadData();
        triggerToast(`GRN Created! Order received into local warehouse stock at ${getCurrentISTTimestamp()}`);
      }
    } catch (err) {
      triggerToast('Error receiving GRN: ' + (err?.message || err));
    }
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

  // Filtered Primary Orders
  const filteredPrimaryOrders = (primaryOrders || []).filter(po => {
    if (!po) return false;
    const q = (primaryOrderSearch || '').toLowerCase();
    const matchesQuery = (
      (po.orderNumber || '').toLowerCase().includes(q) ||
      (po.depotName || '').toLowerCase().includes(q) ||
      (po.productNames || '').toLowerCase().includes(q)
    );
    if (!matchesQuery) return false;
    if (primaryOrderStatusFilter === 'All') return true;
    return po.status === primaryOrderStatusFilter;
  });

  // Quick Stats
  const totalStockUnits = (stockHeld || []).reduce((acc, s) => acc + (s.availableStock || 0), 0);
  const pendingOrdersCount = (orders || []).filter(
    o => o.status === 'Submitted' || o.status === 'Confirmed' || o.status === 'Pending Fulfillment'
  ).length;
  const pendingPrimaryOrdersCount = (primaryOrders || []).filter(
    po => po.status === 'Submitted' || po.status === 'Confirmed' || po.status === 'In Transit'
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
          onClick={() => setActiveTab('primary_orders')}
          className={`flex items-center space-x-2 px-4 py-2.5 rounded-lg text-sm font-semibold transition cursor-pointer relative ${
            activeTab === 'primary_orders'
              ? 'bg-blue-50 text-blue-700 shadow-sm'
              : 'text-slate-600 hover:bg-slate-100 hover:text-slate-900'
          }`}
        >
          <Truck className="w-4 h-4 text-emerald-600" />
          <span>Primary Orders (Procurement)</span>
          {pendingPrimaryOrdersCount > 0 && (
            <span className="bg-emerald-600 text-white text-xs px-2 py-0.5 rounded-full ml-1 font-bold">
              {pendingPrimaryOrdersCount}
            </span>
          )}
        </button>

        <button
          onClick={() => setActiveTab('orders')}
          className={`flex items-center space-x-2 px-4 py-2.5 rounded-lg text-sm font-semibold transition cursor-pointer relative ${
            activeTab === 'orders'
              ? 'bg-blue-50 text-blue-700 shadow-sm'
              : 'text-slate-600 hover:bg-slate-100 hover:text-slate-900'
          }`}
        >
          <ShoppingCart className="w-4 h-4" />
          <span>Secondary Orders (Retailers)</span>
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
        {/* MODULE 0: PRIMARY ORDERS (COMPANY / PLANT PROCUREMENT)    */}
        {/* ========================================================= */}
        {activeTab === 'primary_orders' && (
          <div className="space-y-6">
            {/* Top Banner with Stats & CTA */}
            <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm flex flex-wrap justify-between items-center gap-4">
              <div>
                <div className="inline-flex items-center space-x-2 bg-emerald-50 text-emerald-700 border border-emerald-200 px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider mb-1">
                  <Truck className="w-3.5 h-3.5 text-emerald-600" />
                  <span>Company to Distributor Procurement</span>
                </div>
                <h2 className="text-2xl font-bold text-slate-900 mt-1">Primary Purchase Orders (PO)</h2>
                <p className="text-sm text-slate-500">
                  Manage factory stock procurement for <span className="font-semibold text-slate-700">{distributor.name}</span>. Syncs with Salesforce SObject <code className="text-xs bg-slate-100 px-1 py-0.5 rounded text-blue-700">Order__c</code>.
                </p>
              </div>

              <div className="flex items-center space-x-3">
                <button
                  onClick={() => setShowNewPrimaryOrderModal(true)}
                  className="px-4 py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-bold shadow-md hover:shadow-blue-500/20 transition flex items-center space-x-2 cursor-pointer"
                >
                  <Plus className="w-4 h-4" />
                  <span>+ Place New Primary Order</span>
                </button>
              </div>
            </div>

            {/* 4 Summary Metric Cards */}
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
              <div className="bg-white border border-slate-200 p-4 rounded-xl shadow-sm">
                <span className="text-xs text-slate-500 font-medium">Total Procurement POs</span>
                <div className="text-2xl font-bold text-slate-900 mt-1">{primaryOrders.length}</div>
                <span className="text-[11px] text-slate-400">All registered factory orders</span>
              </div>
              <div className="bg-white border border-slate-200 p-4 rounded-xl shadow-sm">
                <span className="text-xs text-amber-600 font-medium">In Transit / Dispatched</span>
                <div className="text-2xl font-bold text-amber-700 mt-1">
                  {primaryOrders.filter(po => po.status === 'Dispatched' || po.status === 'Confirmed' || po.status === 'Submitted').length}
                </div>
                <span className="text-[11px] text-amber-600">Awaiting warehouse intake</span>
              </div>
              <div className="bg-white border border-slate-200 p-4 rounded-xl shadow-sm">
                <span className="text-xs text-emerald-600 font-medium">Received & GRN Logged</span>
                <div className="text-2xl font-bold text-emerald-700 mt-1">
                  {primaryOrders.filter(po => po.status === 'Delivered').length}
                </div>
                <span className="text-[11px] text-emerald-600">Stock updated into inventory</span>
              </div>
              <div className="bg-white border border-slate-200 p-4 rounded-xl shadow-sm">
                <span className="text-xs text-blue-600 font-medium">Total Procurement Value</span>
                <div className="text-2xl font-bold text-blue-700 mt-1">
                  ₹{primaryOrders.reduce((acc, po) => acc + (po.totalAmount || 0), 0).toLocaleString()}
                </div>
                <span className="text-[11px] text-slate-400">Net wholesale billing amount</span>
              </div>
            </div>

            {/* Search & Filter Bar */}
            <div className="bg-white border border-slate-200 p-4 rounded-2xl shadow-sm flex flex-wrap justify-between items-center gap-3">
              <div className="relative flex-1 min-w-[260px]">
                <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-3" />
                <input
                  type="text"
                  value={primaryOrderSearch}
                  onChange={e => setPrimaryOrderSearch(e.target.value)}
                  placeholder="Search PO number, plant depot, or product..."
                  className="w-full pl-10 pr-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:outline-none focus:ring-2 focus:ring-blue-600"
                />
              </div>

              <div className="flex items-center space-x-2">
                <span className="text-xs text-slate-500 font-medium">Status:</span>
                {['All', 'Submitted', 'Confirmed', 'Dispatched', 'Delivered'].map(status => (
                  <button
                    key={status}
                    onClick={() => setPrimaryOrderStatusFilter(status)}
                    className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition cursor-pointer ${
                      primaryOrderStatusFilter === status
                        ? 'bg-blue-600 text-white'
                        : 'bg-slate-100 hover:bg-slate-200 text-slate-700'
                    }`}
                  >
                    {status}
                  </button>
                ))}
              </div>
            </div>

            {/* Primary Orders Table */}
            <div className="bg-white border border-slate-200 rounded-2xl shadow-sm overflow-hidden">
              <div className="p-4 border-b border-slate-200 flex justify-between items-center">
                <h3 className="font-bold text-slate-900 flex items-center space-x-2 text-sm">
                  <Truck className="w-4 h-4 text-blue-600" />
                  <span>Primary Procurement Orders ({filteredPrimaryOrders.length})</span>
                </h3>
                <span className="text-xs text-slate-500 font-mono">Company Depot: {distributor.defaultWarehouseName || 'Central Hub'}</span>
              </div>

              {filteredPrimaryOrders.length === 0 ? (
                <div className="p-12 text-center bg-white">
                  <Truck className="w-12 h-12 text-slate-300 mx-auto mb-3" />
                  <h4 className="text-base font-bold text-slate-800">No Primary Purchase Orders</h4>
                  <p className="text-xs text-slate-500 max-w-sm mx-auto mt-1 mb-4">
                    No primary orders found for {distributor.name}. You can place a replenishment purchase order directly to the Parle manufacturing depot.
                  </p>
                  <button
                    onClick={() => setShowNewPrimaryOrderModal(true)}
                    className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-bold inline-flex items-center space-x-1.5 cursor-pointer shadow-sm"
                  >
                    <Plus className="w-3.5 h-3.5" />
                    <span>Place New Primary Order</span>
                  </button>
                </div>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full text-left text-sm text-slate-700">
                    <thead className="bg-slate-100 text-slate-700 text-xs uppercase font-semibold border-b border-slate-200">
                      <tr>
                        <th className="px-4 py-3">PO Number & Date (IST)</th>
                        <th className="px-4 py-3">Fulfilling Depot / Plant</th>
                        <th className="px-4 py-3">Procurement Products</th>
                        <th className="px-4 py-3">Total Value</th>
                        <th className="px-4 py-3">Status</th>
                        <th className="px-4 py-3 text-right">Warehouse Intake</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100">
                      {filteredPrimaryOrders.map(po => {
                        const getStatusBadge = () => {
                          switch (po.status) {
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
                          <tr key={po.id} className="hover:bg-slate-50 transition">
                            <td className="px-4 py-3">
                              <button
                                onClick={() => setSelectedPrimaryOrderForModal(po)}
                                className="font-bold text-blue-600 hover:text-blue-800 font-mono text-left cursor-pointer hover:underline flex items-center space-x-1"
                              >
                                <span>{po.orderNumber}</span>
                                <Eye className="w-3 h-3 text-slate-400" />
                              </button>
                              <div className="text-xs text-slate-500 flex items-center space-x-1 mt-0.5">
                                <Calendar className="w-3 h-3 text-slate-400" />
                                <span>{po.orderDate}</span>
                              </div>
                            </td>
                            <td className="px-4 py-3">
                              <div className="font-semibold text-slate-900">{po.depotName || 'Parle Central Depot'}</div>
                              <span className="text-xs text-slate-500">{po.paymentStatus || 'Company Credit'}</span>
                            </td>
                            <td className="px-4 py-3">
                              <div className="font-medium text-slate-900 line-clamp-1 max-w-xs text-xs">
                                {po.productNames || 'Mixed Parle SKUs'}
                              </div>
                              <div className="text-[11px] text-slate-500 font-mono mt-0.5">
                                Total Qty: {po.totalQuantity} cases
                              </div>
                            </td>
                            <td className="px-4 py-3">
                              <div className="font-bold text-slate-900">₹{(po.totalAmount || 0).toLocaleString()}</div>
                              <span className="text-[11px] text-emerald-600">Wholesale RBP</span>
                            </td>
                            <td className="px-4 py-3">
                              <span className={`text-xs px-2.5 py-1 rounded-full font-bold border ${getStatusBadge()}`}>
                                {po.status}
                              </span>
                            </td>
                            <td className="px-4 py-3 text-right">
                              {po.status === 'Delivered' ? (
                                <span className="inline-flex items-center space-x-1 text-emerald-700 bg-emerald-50 border border-emerald-200 text-xs font-semibold px-2.5 py-1 rounded-lg">
                                  <Check className="w-3.5 h-3.5" />
                                  <span>GRN Received</span>
                                </span>
                              ) : (
                                <button
                                  onClick={() => handleReceivePrimaryGRN(po.id)}
                                  className="px-3 py-1 text-xs bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg font-bold shadow-sm inline-flex items-center space-x-1.5 transition cursor-pointer"
                                  title="Receive goods into local warehouse stock"
                                >
                                  <Package className="w-3.5 h-3.5" />
                                  <span>Receive GRN</span>
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
      {/* MODAL 1B: PRIMARY ORDER DETAILS */}
      {/* ========================================================= */}
      {selectedPrimaryOrderForModal && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-xl w-full p-6 shadow-2xl border border-slate-200 space-y-4">
            <div className="flex justify-between items-start border-b border-slate-100 pb-3">
              <div>
                <span className="text-[11px] font-mono text-blue-600 uppercase font-bold tracking-wider">
                  Primary Purchase Order
                </span>
                <h3 className="text-xl font-bold text-slate-900 mt-0.5">{selectedPrimaryOrderForModal.orderNumber}</h3>
                <p className="text-xs text-slate-500 mt-0.5">
                  Fulfilling Depot: <span className="font-semibold text-slate-700">{selectedPrimaryOrderForModal.depotName || 'Parle Central Depot'}</span> • Placed: {selectedPrimaryOrderForModal.orderDate}
                </p>
              </div>
              <button
                onClick={() => setSelectedPrimaryOrderForModal(null)}
                className="text-slate-400 hover:text-slate-700 cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="grid grid-cols-3 gap-3 text-center">
              <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
                <span className="text-[11px] text-slate-500 block">Status</span>
                <span className="text-xs font-bold text-blue-700 uppercase">{selectedPrimaryOrderForModal.status}</span>
              </div>
              <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
                <span className="text-[11px] text-slate-500 block">Total Quantity</span>
                <span className="text-sm font-bold text-slate-900">{selectedPrimaryOrderForModal.totalQuantity} Cases</span>
              </div>
              <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
                <span className="text-[11px] text-slate-500 block">Total Invoice Value</span>
                <span className="text-sm font-bold text-emerald-700">₹{(selectedPrimaryOrderForModal.totalAmount || 0).toLocaleString()}</span>
              </div>
            </div>

            <div className="space-y-2">
              <h4 className="text-xs font-bold text-slate-700 uppercase tracking-wider">Ordered SKUs & Cases:</h4>
              <div className="divide-y divide-slate-100 border border-slate-100 rounded-xl overflow-hidden max-h-56 overflow-y-auto">
                {selectedPrimaryOrderForModal.items && selectedPrimaryOrderForModal.items.length > 0 ? (
                  selectedPrimaryOrderForModal.items.map((item, idx) => (
                    <div key={idx} className="p-3 flex justify-between items-center text-sm bg-white">
                      <div>
                        <div className="font-semibold text-slate-900 text-xs">{item.productName}</div>
                        <span className="text-[11px] text-slate-500">Qty: {item.quantity} cases @ ₹{(item.unitPrice || 0).toLocaleString()}/case</span>
                      </div>
                      <span className="font-bold text-slate-800 text-xs">₹{((item.quantity || 0) * (item.unitPrice || 0)).toLocaleString()}</span>
                    </div>
                  ))
                ) : (
                  <div className="p-3 text-xs text-slate-600">
                    <span className="font-medium text-slate-800">{selectedPrimaryOrderForModal.productNames || 'Parle Assorted SKUs'}</span>
                  </div>
                )}
              </div>
            </div>

            {selectedPrimaryOrderForModal.remarks && (
              <div className="p-2.5 bg-amber-50 border border-amber-100 rounded-lg text-xs text-amber-900">
                <span className="font-bold">Instructions: </span> {selectedPrimaryOrderForModal.remarks}
              </div>
            )}

            <div className="pt-3 border-t border-slate-100 flex justify-between items-center">
              <div>
                <span className="text-[11px] text-slate-500 block">Salesforce SObject:</span>
                <span className="text-xs font-mono font-medium text-slate-700">{selectedPrimaryOrderForModal.id}</span>
              </div>
              <div className="flex space-x-2">
                {selectedPrimaryOrderForModal.status !== 'Delivered' && (
                  <button
                    onClick={() => {
                      handleReceivePrimaryGRN(selectedPrimaryOrderForModal.id);
                      setSelectedPrimaryOrderForModal(null);
                    }}
                    className="px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold rounded-xl cursor-pointer shadow-sm flex items-center space-x-1.5"
                  >
                    <Package className="w-3.5 h-3.5" />
                    <span>Receive GRN into Warehouse</span>
                  </button>
                )}
                <button
                  onClick={() => setSelectedPrimaryOrderForModal(null)}
                  className="px-5 py-2 bg-slate-900 hover:bg-slate-800 text-white text-xs font-semibold rounded-xl cursor-pointer"
                >
                  Close
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ========================================================= */}
      {/* MODAL 1C: PLACE NEW PRIMARY ORDER */}
      {/* ========================================================= */}
      {showNewPrimaryOrderModal && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
          <form
            onSubmit={handleCreatePrimaryOrder}
            className="bg-white rounded-3xl max-w-2xl w-full p-6 sm:p-7 shadow-2xl border border-slate-200 space-y-4 max-h-[90vh] flex flex-col"
          >
            {/* Modal Header */}
            <div className="flex justify-between items-start border-b border-slate-100 pb-3">
              <div>
                <div className="flex items-center space-x-2">
                  <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-blue-100 text-blue-700 uppercase tracking-wide">
                    Direct Procurement
                  </span>
                  <span className="text-xs text-slate-400">• Timezone: IST (UTC+05:30)</span>
                </div>
                <h3 className="text-xl font-bold text-slate-900 mt-1">Place Primary Purchase Order</h3>
                <p className="text-xs text-slate-500">
                  Procure stock from Parle Central Manufacturing & Depot to <span className="font-semibold text-slate-700">{distributor.name}</span> ({distributor.code})
                </p>
              </div>
              <button
                type="button"
                onClick={() => setShowNewPrimaryOrderModal(false)}
                className="text-slate-400 hover:text-slate-700 cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Modal Body - Scrollable */}
            <div className="space-y-4 overflow-y-auto pr-1 flex-1">
              {/* Depot and Credit info banner */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="text-xs font-semibold text-slate-700 block mb-1">
                    Fulfilling Central Depot / Factory Plant
                  </label>
                  <select
                    value={primaryDepot}
                    onChange={e => setPrimaryDepot(e.target.value)}
                    className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold text-slate-900 focus:outline-none focus:ring-2 focus:ring-blue-600"
                  >
                    <option value={distributor.defaultWarehouseName || 'Parle Central Depot A'}>
                      {distributor.defaultWarehouseName || 'Parle Central Depot A'} (Assigned Hub)
                    </option>
                    <option value="Parle Manufacturing Plant - Neemrana Hub">Parle Manufacturing Plant - Neemrana Hub</option>
                    <option value="Parle North Depot - Bahadurgarh Hub">Parle North Depot - Bahadurgarh Hub</option>
                    <option value="Parle West Central Hub - Bhiwandi Depot">Parle West Central Hub - Bhiwandi Depot</option>
                  </select>
                </div>

                <div className="bg-blue-50/70 border border-blue-100 rounded-xl p-3 flex flex-col justify-between">
                  <div className="flex justify-between items-center text-xs">
                    <span className="text-blue-800 font-medium">Distributor Credit Available:</span>
                    <span className="font-bold text-blue-900 font-mono">
                      ₹{Math.max(0, distributor.creditLimit - distributor.currentOutstanding).toLocaleString()}
                    </span>
                  </div>
                  <div className="text-[11px] text-blue-600 mt-1">
                    Sanctioned: ₹{distributor.creditLimit.toLocaleString()} • Outstanding: ₹{distributor.currentOutstanding.toLocaleString()}
                  </div>
                </div>
              </div>

              {/* Order Items Table */}
              <div>
                <div className="flex justify-between items-center mb-2">
                  <label className="text-xs font-bold text-slate-800 uppercase tracking-wider flex items-center space-x-1.5">
                    <Boxes className="w-4 h-4 text-blue-600" />
                    <span>Purchase Line Items ({primaryOrderLines.length})</span>
                  </label>
                  <button
                    type="button"
                    onClick={addPrimaryOrderLine}
                    className="text-xs text-blue-600 hover:text-blue-800 font-bold flex items-center space-x-1 cursor-pointer"
                  >
                    <Plus className="w-3.5 h-3.5" />
                    <span>+ Add SKU Line</span>
                  </button>
                </div>

                <div className="border border-slate-200 rounded-2xl overflow-hidden divide-y divide-slate-100">
                  {primaryOrderLines.map((line, idx) => {
                    const lineTotal = (Number(line.quantity) || 0) * (Number(line.unitPrice) || 0);
                    return (
                      <div key={idx} className="p-3 bg-white hover:bg-slate-50 transition flex flex-col sm:flex-row sm:items-center gap-2">
                        {/* SKU Selector */}
                        <div className="flex-1 min-w-[200px]">
                          <label className="text-[10px] uppercase font-bold text-slate-400 block mb-0.5">Product SKU</label>
                          <select
                            value={line.productId}
                            onChange={e => updatePrimaryOrderLine(idx, 'productId', e.target.value)}
                            className="w-full p-2 bg-slate-50 border border-slate-200 rounded-lg text-xs font-medium text-slate-900"
                          >
                            {PARLE_PRODUCTS.map(p => (
                              <option key={p.id} value={p.id}>
                                {p.name} — {p.category} ({p.sku})
                              </option>
                            ))}
                          </select>
                        </div>

                        {/* Wholesale Price / Case */}
                        <div className="w-28">
                          <label className="text-[10px] uppercase font-bold text-slate-400 block mb-0.5">Price/Case (₹)</label>
                          <input
                            type="number"
                            min="1"
                            value={line.unitPrice}
                            onChange={e => updatePrimaryOrderLine(idx, 'unitPrice', e.target.value)}
                            className="w-full p-2 bg-slate-50 border border-slate-200 rounded-lg text-xs font-mono font-bold text-slate-800"
                          />
                        </div>

                        {/* Quantity (Cases) */}
                        <div className="w-24">
                          <label className="text-[10px] uppercase font-bold text-slate-400 block mb-0.5">Cases</label>
                          <input
                            type="number"
                            min="1"
                            value={line.quantity}
                            onChange={e => updatePrimaryOrderLine(idx, 'quantity', e.target.value)}
                            className="w-full p-2 bg-slate-50 border border-slate-200 rounded-lg text-xs font-mono font-bold text-slate-900"
                            required
                          />
                        </div>

                        {/* Line Total */}
                        <div className="w-32 text-right">
                          <label className="text-[10px] uppercase font-bold text-slate-400 block mb-0.5">Subtotal</label>
                          <div className="text-xs font-bold text-slate-900 font-mono py-2">
                            ₹{lineTotal.toLocaleString()}
                          </div>
                        </div>

                        {/* Remove Row Button */}
                        <div className="sm:self-end pb-1">
                          <button
                            type="button"
                            onClick={() => removePrimaryOrderLine(idx)}
                            disabled={primaryOrderLines.length <= 1}
                            className={`p-2 rounded-lg cursor-pointer ${
                              primaryOrderLines.length <= 1
                                ? 'text-slate-300 cursor-not-allowed'
                                : 'text-rose-500 hover:text-rose-700 hover:bg-rose-50'
                            }`}
                            title="Remove SKU line"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>

              {/* Order Summary Cards */}
              <div className="bg-slate-50 border border-slate-200 rounded-2xl p-4 grid grid-cols-2 sm:grid-cols-4 gap-3 text-center">
                <div>
                  <span className="text-[10px] uppercase font-bold text-slate-400 block">Total SKUs</span>
                  <span className="text-sm font-bold text-slate-800">{primaryOrderLines.length} Products</span>
                </div>
                <div>
                  <span className="text-[10px] uppercase font-bold text-slate-400 block">Total Quantity</span>
                  <span className="text-sm font-bold text-blue-700">
                    {primaryOrderLines.reduce((acc, l) => acc + (Number(l.quantity) || 0), 0)} Cases
                  </span>
                </div>
                <div>
                  <span className="text-[10px] uppercase font-bold text-slate-400 block">Distributor Margin (5%)</span>
                  <span className="text-sm font-bold text-emerald-600">
                    ₹{Math.round(primaryOrderLines.reduce((acc, l) => acc + (Number(l.quantity) || 0) * (Number(l.unitPrice) || 0), 0) * 0.05).toLocaleString()}
                  </span>
                </div>
                <div>
                  <span className="text-[10px] uppercase font-bold text-slate-400 block">Gross Order Value</span>
                  <span className="text-base font-bold text-slate-900 font-mono">
                    ₹{primaryOrderLines.reduce((acc, l) => acc + (Number(l.quantity) || 0) * (Number(l.unitPrice) || 0), 0).toLocaleString()}
                  </span>
                </div>
              </div>

              {/* Remarks */}
              <div>
                <label className="text-xs font-semibold text-slate-700 block mb-1">
                  Logistics & Delivery Instructions (Optional)
                </label>
                <input
                  type="text"
                  placeholder="e.g. Schedule delivery before 11:00 AM; priority replenishment for festive stock"
                  value={primaryRemarks}
                  onChange={e => setPrimaryRemarks(e.target.value)}
                  className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:outline-none focus:ring-2 focus:ring-blue-600"
                />
              </div>
            </div>

            {/* Modal Footer */}
            <div className="pt-3 border-t border-slate-100 flex justify-end space-x-2">
              <button
                type="button"
                onClick={() => setShowNewPrimaryOrderModal(false)}
                className="px-4 py-2 border border-slate-200 text-slate-700 text-xs font-semibold rounded-xl hover:bg-slate-50 cursor-pointer"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={isSubmittingPrimaryOrder}
                className="px-5 py-2.5 bg-blue-600 hover:bg-blue-700 disabled:opacity-50 text-white text-xs font-bold rounded-xl shadow-md hover:shadow-blue-500/20 transition flex items-center space-x-2 cursor-pointer"
              >
                <Truck className="w-4 h-4" />
                <span>{isSubmittingPrimaryOrder ? 'Submitting to Salesforce...' : 'Confirm & Submit PO to Salesforce'}</span>
              </button>
            </div>
          </form>
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

            <div className="pt-3 border-t border-slate-100 flex space-x-2">
              <button
                onClick={() => {
                  setShowProfileModal(false);
                  handleLogout();
                }}
                className="flex-1 py-2.5 bg-rose-50 hover:bg-rose-100 text-rose-700 border border-rose-200 text-xs font-bold rounded-xl cursor-pointer transition flex items-center justify-center space-x-1.5"
              >
                <LogOut className="w-3.5 h-3.5" />
                <span>Switch Distributor</span>
              </button>
              <button
                onClick={() => setShowProfileModal(false)}
                className="flex-1 py-2.5 bg-slate-900 hover:bg-slate-800 text-white text-xs font-bold rounded-xl cursor-pointer"
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
