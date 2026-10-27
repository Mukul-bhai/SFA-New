import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPortalInitData from '@salesforce/apex/DmsPortalController.getPortalInitData';
import createBulkPrimaryOrder from '@salesforce/apex/DmsPortalController.createBulkPrimaryOrder';
import updateOrderStatus from '@salesforce/apex/DmsPortalController.updateOrderStatus';

export default class DmsPortal extends LightningElement {
    @track isLoading = true;
    @track activeTab = 'orders'; // 'home', 'products', 'orders', 'invoices', 'grn', 'ledger', 'inventory'
    @track activeOrderSubtab = 'primary'; // 'primary', 'secondary'

    // Distributor data
    @track selectedDistributorId;
    @track activeDistributor = {};
    @track distributors = [];

    // Products & Orders
    @track allProducts = [];
    @track filteredProducts = [];
    @track allPrimaryOrders = [];
    @track filteredPrimaryOrders = [];
    @track allSecondaryOrders = [];
    @track filteredSecondaryOrders = [];

    // Financial KPIs
    @track kpis = {};

    // Search terms
    primarySearchTerm = '';
    secondarySearchTerm = '';
    productSearchTerm = '';
    bulkModalSearchTerm = '';

    // Bulk Order Modal State ("single time multiple order for primary order")
    @track showBulkOrderModal = false;
    @track isSubmittingOrder = false;
    @track bulkModalProducts = [];
    @track poNumber = '';
    @track orderRemarks = '';

    // Detail Modal State
    @track showDetailModal = false;
    @track selectedOrder = {};

    connectedCallback() {
        this.loadPortalData();
    }

    async loadPortalData() {
        this.isLoading = true;
        try {
            const data = await getPortalInitData({ selectedDistributorId: this.selectedDistributorId });
            
            // 1. Process Distributors
            if (data.allDistributors && data.allDistributors.length > 0) {
                this.distributors = data.allDistributors.map(d => ({
                    ...d,
                    isSelected: data.activeDistributor && d.Id === data.activeDistributor.Id
                }));
                this.activeDistributor = data.activeDistributor || data.allDistributors[0];
                this.selectedDistributorId = this.activeDistributor.Id;
            }

            // 2. Process KPIs
            this.kpis = data.kpis || {};

            // 3. Process Products
            this.allProducts = (data.products || []).map(p => ({
                ...p,
                selectedQty: 0,
                lineTotal: 0,
                lineTotalFormatted: '0.00'
            }));
            this.filteredProducts = [...this.allProducts];

            // 4. Process Primary Orders
            this.allPrimaryOrders = (data.primaryOrders || []).map(o => ({
                ...o,
                statusClass: this.computeStatusClass(o.status)
            }));
            this.filterPrimaryOrders();

            // 5. Process Secondary Orders
            this.allSecondaryOrders = (data.secondaryOrders || []).map(o => ({
                ...o,
                statusClass: this.computeStatusClass(o.status),
                canApprove: o.status === 'Draft' || o.status === 'Submitted'
            }));
            this.filterSecondaryOrders();

        } catch (error) {
            this.showToast('Error Loading DMS Data', error.body ? error.body.message : error.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    computeStatusClass(status) {
        const s = (status || '').toLowerCase();
        if (s.includes('submit')) return 'status-pill status-submitted';
        if (s.includes('approv')) return 'status-pill status-approved';
        if (s.includes('dispatch')) return 'status-pill status-dispatched';
        if (s.includes('deliver')) return 'status-pill status-delivered';
        return 'status-pill status-draft';
    }

    // --- NAVIGATION TAB GETTERS & HANDLERS ---
    get isHomeTab() { return this.activeTab === 'home'; }
    get isProductsTab() { return this.activeTab === 'products'; }
    get isOrdersTab() { return this.activeTab === 'orders'; }
    get isOtherTab() { 
        return ['invoices', 'grn', 'ledger', 'inventory'].includes(this.activeTab); 
    }
    get activeTabName() {
        return this.activeTab.toUpperCase();
    }

    get navHomeClass() { return `nav-item ${this.activeTab === 'home' ? 'active' : ''}`; }
    get navProductsClass() { return `nav-item ${this.activeTab === 'products' ? 'active' : ''}`; }
    get navOrdersClass() { return `nav-item ${this.activeTab === 'orders' ? 'active' : ''}`; }
    get navInvoicesClass() { return `nav-item ${this.activeTab === 'invoices' ? 'active' : ''}`; }
    get navGrnClass() { return `nav-item ${this.activeTab === 'grn' ? 'active' : ''}`; }
    get navLedgerClass() { return `nav-item ${this.activeTab === 'ledger' ? 'active' : ''}`; }
    get navInventoryClass() { return `nav-item ${this.activeTab === 'inventory' ? 'active' : ''}`; }

    handleNavClick(event) {
        this.activeTab = event.currentTarget.dataset.tab;
    }

    // --- ORDERS SUBTABS (PRIMARY VS SECONDARY) ---
    get isPrimaryOrders() { return this.activeOrderSubtab === 'primary'; }
    get isSecondaryOrders() { return this.activeOrderSubtab === 'secondary'; }

    get primarySubtabClass() { return `tab-btn ${this.isPrimaryOrders ? 'active' : ''}`; }
    get secondarySubtabClass() { return `tab-btn ${this.isSecondaryOrders ? 'active' : ''}`; }

    handleOrderSubtabClick(event) {
        this.activeOrderSubtab = event.currentTarget.dataset.subtab;
    }

    get primaryOrdersCount() { return this.allPrimaryOrders.length; }
    get secondaryOrdersCount() { return this.allSecondaryOrders.length; }
    get isPrimaryEmpty() { return this.filteredPrimaryOrders.length === 0; }
    get isSecondaryEmpty() { return this.filteredSecondaryOrders.length === 0; }

    // --- FORMATTED KPI VALUES ---
    get activeDistributorName() { return this.activeDistributor.Name || 'Distributor'; }
    get activeDistributorCode() { return this.activeDistributor.Distributor_Code__c || 'DIST-001'; }

    get formattedCreditLimit() {
        return Number(this.kpis.creditLimit || 0).toLocaleString('en-IN', { maximumFractionDigits: 0 });
    }
    get formattedOutstanding() {
        return Number(this.kpis.currentOutstanding || 0).toLocaleString('en-IN', { maximumFractionDigits: 0 });
    }
    get formattedAvailableCredit() {
        return Number(this.kpis.availableCredit || 0).toLocaleString('en-IN', { maximumFractionDigits: 0 });
    }
    get formattedPrimaryTotal() {
        return Number(this.kpis.primaryTotal || 0).toLocaleString('en-IN', { maximumFractionDigits: 0 });
    }
    get formattedSecondaryTotal() {
        return Number(this.kpis.secondaryTotal || 0).toLocaleString('en-IN', { maximumFractionDigits: 0 });
    }
    get pendingPrimaryCount() { return this.kpis.pendingPrimary || 0; }
    get pendingSecondaryCount() { return this.kpis.pendingSecondary || 0; }

    get recentPrimaryOrders() {
        return this.allPrimaryOrders.slice(0, 5);
    }

    // --- DISTRIBUTOR SWITCHER ---
    handleDistributorChange(event) {
        this.selectedDistributorId = event.target.value;
        this.loadPortalData();
    }

    // --- SEARCH FILTERS ---
    handlePrimarySearch(event) {
        this.primarySearchTerm = (event.target.value || '').toLowerCase();
        this.filterPrimaryOrders();
    }

    filterPrimaryOrders() {
        if (!this.primarySearchTerm) {
            this.filteredPrimaryOrders = [...this.allPrimaryOrders];
        } else {
            this.filteredPrimaryOrders = this.allPrimaryOrders.filter(o => 
                (o.name && o.name.toLowerCase().includes(this.primarySearchTerm)) ||
                (o.status && o.status.toLowerCase().includes(this.primarySearchTerm)) ||
                (o.poNumber && o.poNumber.toLowerCase().includes(this.primarySearchTerm))
            );
        }
    }

    handleSecondarySearch(event) {
        this.secondarySearchTerm = (event.target.value || '').toLowerCase();
        this.filterSecondaryOrders();
    }

    filterSecondaryOrders() {
        if (!this.secondarySearchTerm) {
            this.filteredSecondaryOrders = [...this.allSecondaryOrders];
        } else {
            this.filteredSecondaryOrders = this.allSecondaryOrders.filter(o => 
                (o.name && o.name.toLowerCase().includes(this.secondarySearchTerm)) ||
                (o.customerName && o.customerName.toLowerCase().includes(this.secondarySearchTerm)) ||
                (o.beatName && o.beatName.toLowerCase().includes(this.secondarySearchTerm)) ||
                (o.status && o.status.toLowerCase().includes(this.secondarySearchTerm))
            );
        }
    }

    handleProductSearch(event) {
        this.productSearchTerm = (event.target.value || '').toLowerCase();
        if (!this.productSearchTerm) {
            this.filteredProducts = [...this.allProducts];
        } else {
            this.filteredProducts = this.allProducts.filter(p => 
                (p.name && p.name.toLowerCase().includes(this.productSearchTerm)) ||
                (p.code && p.code.toLowerCase().includes(this.productSearchTerm)) ||
                (p.brand && p.brand.toLowerCase().includes(this.productSearchTerm))
            );
        }
    }

    refreshData() {
        this.loadPortalData();
        this.showToast('Refreshed', 'DMS Portal data synchronized with Salesforce.', 'info');
    }

    // =========================================================
    // BULK MULTI-PRODUCT PRIMARY ORDER MATRIX ("SINGLE TIME MULTIPLE")
    // =========================================================
    openBulkOrderModal() {
        this.poNumber = 'PO-' + new Date().getFullYear() + '-' + String(Math.floor(1000 + Math.random() * 9000));
        this.orderRemarks = 'Standard Dispatch from Factory Depot';
        this.bulkModalSearchTerm = '';
        
        // Reset quantities
        this.bulkModalProducts = this.allProducts.map(p => ({
            ...p,
            selectedQty: 0,
            lineTotal: 0,
            lineTotalFormatted: '0.00'
        }));

        this.showBulkOrderModal = true;
    }

    closeBulkOrderModal() {
        this.showBulkOrderModal = false;
    }

    handlePoNumberChange(event) {
        this.poNumber = event.target.value;
    }

    handleRemarksChange(event) {
        this.orderRemarks = event.target.value;
    }

    handleBulkModalSearch(event) {
        this.bulkModalSearchTerm = (event.target.value || '').toLowerCase();
        this.applyBulkModalFilter();
    }

    applyBulkModalFilter() {
        if (!this.bulkModalSearchTerm) {
            // Keep current quantities intact
            return;
        }
    }

    handleQtyIncrement(event) {
        const prodId = event.currentTarget.dataset.id;
        this.updateProductQty(prodId, 1);
    }

    handleQtyDecrement(event) {
        const prodId = event.currentTarget.dataset.id;
        this.updateProductQty(prodId, -1);
    }

    handleQtyInputChange(event) {
        const prodId = event.target.dataset.id;
        const newQty = parseInt(event.target.value, 10) || 0;
        this.setProductQty(prodId, Math.max(0, newQty));
    }

    updateProductQty(prodId, delta) {
        this.bulkModalProducts = this.bulkModalProducts.map(p => {
            if (p.id === prodId) {
                const updatedQty = Math.max(0, (p.selectedQty || 0) + delta);
                const lineTotal = updatedQty * (p.unitPrice || 0);
                return {
                    ...p,
                    selectedQty: updatedQty,
                    lineTotal: lineTotal,
                    lineTotalFormatted: lineTotal.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
                };
            }
            return p;
        });
    }

    setProductQty(prodId, qty) {
        this.bulkModalProducts = this.bulkModalProducts.map(p => {
            if (p.id === prodId) {
                const lineTotal = qty * (p.unitPrice || 0);
                return {
                    ...p,
                    selectedQty: qty,
                    lineTotal: lineTotal,
                    lineTotalFormatted: lineTotal.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
                };
            }
            return p;
        });
    }

    // Computed Summary for Bulk Primary Order
    get bulkSelectedSkusCount() {
        return this.bulkModalProducts.filter(p => p.selectedQty > 0).length;
    }

    get bulkTotalUnits() {
        return this.bulkModalProducts.reduce((sum, p) => sum + (p.selectedQty || 0), 0);
    }

    get bulkSubtotal() {
        return this.bulkModalProducts.reduce((sum, p) => sum + (p.lineTotal || 0), 0);
    }

    get bulkTaxAmount() {
        return this.bulkSubtotal * 0.18; // 18% GST
    }

    get bulkGrandTotal() {
        return this.bulkSubtotal + this.bulkTaxAmount;
    }

    get bulkSubtotalFormatted() {
        return this.bulkSubtotal.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    }

    get bulkTaxFormatted() {
        return this.bulkTaxAmount.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    }

    get bulkGrandTotalFormatted() {
        return this.bulkGrandTotal.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    }

    get isSubmitOrderDisabled() {
        return this.isSubmittingOrder || this.bulkTotalUnits === 0;
    }

    // Submit Bulk Primary Order to Salesforce
    async submitBulkPrimaryOrder() {
        if (this.bulkTotalUnits === 0) {
            this.showToast('Select Products', 'Please enter order quantities for at least one product.', 'warning');
            return;
        }

        this.isSubmittingOrder = true;
        try {
            const validItems = this.bulkModalProducts
                .filter(p => p.selectedQty > 0)
                .map(p => ({
                    productId: p.id,
                    productName: p.name,
                    productCode: p.code,
                    quantity: p.selectedQty,
                    unitPrice: p.unitPrice,
                    mrp: p.mrp
                }));

            const itemsJson = JSON.stringify(validItems);

            const response = await createBulkPrimaryOrder({
                distributorId: this.selectedDistributorId,
                poNumber: this.poNumber,
                remarks: this.orderRemarks,
                itemsJson: itemsJson
            });

            if (response.success) {
                this.showToast('Order Created Successfully!', response.message, 'success');
                this.showBulkOrderModal = false;
                await this.loadPortalData();
                this.activeTab = 'orders';
                this.activeOrderSubtab = 'primary';
            } else {
                this.showToast('Error Placing Order', response.message, 'error');
            }

        } catch (error) {
            this.showToast('Error', error.body ? error.body.message : error.message, 'error');
        } finally {
            this.isSubmittingOrder = false;
        }
    }

    // --- ORDER DETAIL MODAL ---
    viewOrderDetails(event) {
        const orderId = event.currentTarget.dataset.id;
        const all = [...this.allPrimaryOrders, ...this.allSecondaryOrders];
        const match = all.find(o => o.id === orderId);
        if (match) {
            this.selectedOrder = match;
            this.showDetailModal = true;
        }
    }

    closeDetailModal() {
        this.showDetailModal = false;
    }

    // --- APPROVE SECONDARY ORDER ---
    async handleApproveOrder(event) {
        const orderId = event.currentTarget.dataset.id;
        this.isLoading = true;
        try {
            const res = await updateOrderStatus({ orderId: orderId, newStatus: 'Approved' });
            if (res.success) {
                this.showToast('Order Approved', res.message, 'success');
                await this.loadPortalData();
            } else {
                this.showToast('Error', res.message, 'error');
            }
        } catch (error) {
            this.showToast('Error Approving Order', error.body ? error.body.message : error.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
