import { useState, useEffect } from 'react';
import { Building2, Lock, ArrowRight, ShieldCheck, Clock, CheckCircle2, AlertCircle, Eye, EyeOff, RefreshCw } from 'lucide-react';
import { DMSDataService } from '../services/api';
import { formatIST } from '../utils/dateUtils';

export default function DistributorLogin({ onLoginSuccess }) {
  const [distributorCode, setDistributorCode] = useState('');
  const [pin, setPin] = useState('1234');
  const [showPin, setShowPin] = useState(false);
  const [loading, setLoading] = useState(false);
  const [isSyncingSF, setIsSyncingSF] = useState(false);
  const [error, setError] = useState(null);
  const [distributors, setDistributors] = useState([]);
  const [currentTimeIST, setCurrentTimeIST] = useState(formatIST(new Date()));

  // Live IST Clock
  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentTimeIST(formatIST(new Date()));
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  // Fetch registered distributors (both instant cache and live Salesforce sync)
  useEffect(() => {
    async function loadDistributors() {
      // 1. Immediately display cached distributors so UI has zero delay
      const cached = DMSDataService.getAllDistributors();
      if (cached && cached.length > 0) {
        setDistributors(cached);
        setDistributorCode(cached[0].code);
      }

      // 2. Concurrently fetch fresh live list directly from Salesforce Distributor__c
      setIsSyncingSF(true);
      try {
        const live = await DMSDataService.syncDistributorsFromSalesforce();
        if (live && live.length > 0) {
          setDistributors(live);
          if (!distributorCode) {
            setDistributorCode(live[0].code);
          }
        }
      } catch (err) {
        console.warn('Background Salesforce distributor sync error:', err);
      } finally {
        setIsSyncingSF(false);
      }
    }
    loadDistributors();
  }, []);

  const handleManualSync = async () => {
    setIsSyncingSF(true);
    setError(null);
    try {
      const live = await DMSDataService.syncDistributorsFromSalesforce();
      if (live && live.length > 0) {
        setDistributors(live);
      }
    } catch (err) {
      setError('Salesforce sync error: ' + (err?.message || err));
    } finally {
      setIsSyncingSF(false);
    }
  };

  const handleLogin = async (e) => {
    if (e) e.preventDefault();
    setError(null);
    setLoading(true);

    try {
      const result = await DMSDataService.login(distributorCode, pin);
      if (result.success) {
        onLoginSuccess(result.distributor);
      } else {
        setError(result.error || 'Authentication failed. Please verify credentials.');
      }
    } catch (err) {
      setError(err?.message || 'Login connection error. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleQuickSelect = (dist) => {
    setDistributorCode(dist.code);
    setPin('1234');
    setError(null);
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-blue-950 flex flex-col justify-between p-4 sm:p-6 text-slate-100 font-sans">
      {/* Top Banner with IST Timestamp */}
      <div className="max-w-6xl w-full mx-auto flex flex-wrap justify-between items-center py-3 border-b border-slate-700/60 text-xs text-slate-400 gap-3">
        <div className="flex items-center space-x-2">
          <span className="w-2.5 h-2.5 rounded-full bg-emerald-400 animate-pulse"></span>
          <span className="font-semibold text-slate-200">Parle DMS Enterprise Network</span>
          <span>•</span>
          <span>Salesforce SFA Connected</span>
        </div>
        <div className="flex items-center space-x-2 bg-slate-800/80 border border-slate-700 px-3 py-1.5 rounded-lg text-slate-300 font-mono">
          <Clock className="w-3.5 h-3.5 text-blue-400" />
          <span>India Time: {currentTimeIST}</span>
        </div>
      </div>

      {/* Main Login Card Container */}
      <div className="max-w-4xl w-full mx-auto my-8 grid grid-cols-1 md:grid-cols-12 gap-8 items-center">
        {/* Left Side: Brand & Distributor Credentials Overview */}
        <div className="md:col-span-5 space-y-5 text-left">
          <div className="inline-flex items-center space-x-3 bg-blue-600/20 border border-blue-500/40 px-3.5 py-1.5 rounded-full text-blue-300 text-xs font-semibold">
            <Building2 className="w-4 h-4 text-blue-400" />
            <span>Authorized Distributor Portal</span>
          </div>

          <h1 className="text-3xl sm:text-4xl font-extrabold tracking-tight text-white leading-tight">
            Distributor Management System
          </h1>

          <p className="text-slate-300 text-sm leading-relaxed">
            Secure, dedicated access for Parle authorized primary & backup distributors. Log in using your registered Distributor Code to access your secondary orders, warehouse inventory, GRN processing, and retailer settlements.
          </p>

          <div className="space-y-3 pt-2">
            <div className="flex items-start space-x-3 text-xs text-slate-300 bg-slate-800/40 border border-slate-700/50 p-3 rounded-xl">
              <ShieldCheck className="w-5 h-5 text-emerald-400 shrink-0 mt-0.5" />
              <div>
                <span className="font-semibold text-white block">Strict Data Isolation</span>
                Distributors only see orders, inventory, and retail accounts assigned to their specific Salesforce territory.
              </div>
            </div>
            <div className="flex items-start space-x-3 text-xs text-slate-300 bg-slate-800/40 border border-slate-700/50 p-3 rounded-xl">
              <Clock className="w-5 h-5 text-amber-400 shrink-0 mt-0.5" />
              <div>
                <span className="font-semibold text-white block">Indian Standard Time (IST)</span>
                All order bookings, warehouse movements, and ticket updates are recorded in Asia/Kolkata timezone.
              </div>
            </div>
          </div>
        </div>

        {/* Right Side: Secure Login Box */}
        <div className="md:col-span-7 bg-white text-slate-900 rounded-3xl p-6 sm:p-8 shadow-2xl border border-slate-100 space-y-6">
          <div className="border-b border-slate-100 pb-4">
            <h2 className="text-xl font-bold text-slate-900">Distributor Sign In</h2>
            <p className="text-xs text-slate-500 mt-1">
              Enter your assigned distributor code and 4-digit security PIN
            </p>
          </div>

          {error && (
            <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-xl text-xs flex items-start space-x-2.5">
              <AlertCircle className="w-4 h-4 text-red-600 shrink-0 mt-0.5" />
              <span>{error}</span>
            </div>
          )}

          <form onSubmit={handleLogin} className="space-y-4">
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-1.5">
                Distributor Code / ID
              </label>
              <div className="relative">
                <Building2 className="w-4 h-4 text-slate-400 absolute left-3.5 top-3" />
                <input
                  type="text"
                  required
                  value={distributorCode}
                  onChange={(e) => setDistributorCode(e.target.value)}
                  placeholder="e.g. DIST-PRI-001"
                  className="w-full pl-10 pr-4 py-2.5 bg-slate-50 border border-slate-300 rounded-xl text-sm font-semibold text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-blue-600 focus:bg-white uppercase tracking-wider"
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-1.5">
                Security PIN / Password
              </label>
              <div className="relative">
                <Lock className="w-4 h-4 text-slate-400 absolute left-3.5 top-3" />
                <input
                  type={showPin ? 'text' : 'password'}
                  required
                  value={pin}
                  onChange={(e) => setPin(e.target.value)}
                  placeholder="Enter 4-digit PIN"
                  className="w-full pl-10 pr-10 py-2.5 bg-slate-50 border border-slate-300 rounded-xl text-sm font-semibold text-slate-900 focus:outline-none focus:ring-2 focus:ring-blue-600 focus:bg-white"
                />
                <button
                  type="button"
                  onClick={() => setShowPin(!showPin)}
                  className="absolute right-3.5 top-3 text-slate-400 hover:text-slate-600"
                  tabIndex={-1}
                >
                  {showPin ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
              <span className="text-[11px] text-slate-400 mt-1 block">Default test PIN: 1234</span>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full bg-blue-600 hover:bg-blue-700 text-white font-bold py-3 px-4 rounded-xl shadow-lg hover:shadow-blue-500/30 transition flex items-center justify-center space-x-2 text-sm disabled:opacity-70 cursor-pointer"
            >
              {loading ? (
                <span>Authenticating with Salesforce...</span>
              ) : (
                <>
                  <span>Sign In to Distributor Portal</span>
                  <ArrowRight className="w-4 h-4" />
                </>
              )}
            </button>
          </form>

          {/* Quick Select Accordion of Real Salesforce Distributors */}
          <div className="pt-4 border-t border-slate-100">
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-bold text-slate-700 flex items-center space-x-1.5">
                <span>Registered Accounts (Salesforce Live)</span>
                <span className="bg-emerald-100 text-emerald-800 text-[10px] font-bold px-1.5 py-0.5 rounded-full">
                  {distributors.length} Synced
                </span>
              </span>
              <button
                type="button"
                onClick={handleManualSync}
                disabled={isSyncingSF}
                className="text-[11px] text-blue-600 hover:text-blue-800 font-semibold flex items-center space-x-1 cursor-pointer disabled:opacity-50"
                title="Fetch newly created distributors from Salesforce"
              >
                <RefreshCw className={`w-3 h-3 ${isSyncingSF ? 'animate-spin text-blue-600' : ''}`} />
                <span>{isSyncingSF ? 'Syncing...' : 'Sync Salesforce'}</span>
              </button>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
              {distributors.map((d) => (
                <button
                  key={d.id}
                  type="button"
                  onClick={() => handleQuickSelect(d)}
                  className={`text-left p-2.5 rounded-xl border text-xs transition cursor-pointer flex flex-col justify-between ${
                    distributorCode.toUpperCase() === d.code.toUpperCase()
                      ? 'border-blue-600 bg-blue-50/70 text-blue-900'
                      : 'border-slate-200 bg-slate-50/60 hover:bg-slate-100 text-slate-700'
                  }`}
                >
                  <div className="font-bold flex items-center justify-between">
                    <span className="truncate">{d.name}</span>
                    {distributorCode.toUpperCase() === d.code.toUpperCase() && (
                      <CheckCircle2 className="w-3.5 h-3.5 text-blue-600 shrink-0" />
                    )}
                  </div>
                  <div className="text-[11px] text-slate-500 font-mono mt-0.5">
                    Code: {d.code} • GST: {d.gstin?.substring(0, 5)}...
                  </div>
                </button>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Footer */}
      <footer className="max-w-6xl w-full mx-auto text-center text-xs text-slate-500 py-3 border-t border-slate-800">
        Parle Products Ltd. • Distributor Management System (DMS) • Secure SSL Encrypted Session (IST UTC+05:30)
      </footer>
    </div>
  );
}
