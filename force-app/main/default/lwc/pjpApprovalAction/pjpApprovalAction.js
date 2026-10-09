import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getPJPApprovalDetails from '@salesforce/apex/PJPApprovalController.getPJPApprovalDetails';
import submitForApproval from '@salesforce/apex/PJPApprovalController.submitForApproval';
import processApproval from '@salesforce/apex/PJPApprovalController.processApproval';

export default class PjpApprovalAction extends LightningElement {
    @api recordId;
    @track pjpInfo;
    @track isLoading = false;
    @track showModal = false;
    @track modalAction = '';
    @track modalTitle = '';
    @track modalMessage = '';
    @track modalButtonLabel = '';
    @track modalButtonVariant = 'brand';
    @track comments = '';

    wiredPJPResult;

    @wire(getPJPApprovalDetails, { pjpId: '$recordId' })
    wiredDetails(result) {
        this.wiredPJPResult = result;
        const { data, error } = result;
        if (data) {
            this.pjpInfo = data;
        } else if (error) {
            console.error('Error loading PJP details:', error);
        }
    }

    get statusBadgeClass() {
        if (!this.pjpInfo) return '';
        const status = this.pjpInfo.status;
        if (status === 'Approved') return 'slds-theme_success';
        if (status === 'Submitted' || status === 'Pending Approval') return 'slds-theme_warning';
        if (status === 'Rejected') return 'slds-theme_error';
        return 'slds-theme_shade';
    }

    get isApproved() {
        return this.pjpInfo && this.pjpInfo.status === 'Approved';
    }

    get isSubmitted() {
        return this.pjpInfo && (this.pjpInfo.status === 'Submitted' || this.pjpInfo.status === 'Pending Approval');
    }

    get isRejected() {
        return this.pjpInfo && this.pjpInfo.status === 'Rejected';
    }

    get showApprovalButtons() {
        return this.pjpInfo && this.isSubmitted && this.pjpInfo.isManagerOrAdmin;
    }

    handleSubmitClick() {
        this.modalAction = 'SUBMIT';
        this.modalTitle = 'Submit PJP for Approval';
        this.modalMessage = `Are you sure you want to submit this monthly route journey plan for approval to Reporting Manager: ${this.pjpInfo.reportingManagerName || 'Assigned Manager'}?`;
        this.modalButtonLabel = 'Confirm & Submit';
        this.modalButtonVariant = 'brand';
        this.comments = '';
        this.showModal = true;
    }

    openApproveModal() {
        this.modalAction = 'APPROVE';
        this.modalTitle = 'Approve PJP Plan';
        this.modalMessage = `Confirm approval of monthly journey plan for ${this.pjpInfo.employeeName}? All route beats will be finalized.`;
        this.modalButtonLabel = 'Approve';
        this.modalButtonVariant = 'success';
        this.comments = '';
        this.showModal = true;
    }

    openRejectModal() {
        this.modalAction = 'REJECT';
        this.modalTitle = 'Reject PJP Plan';
        this.modalMessage = `Specify reasons for rejecting the journey plan for ${this.pjpInfo.employeeName}:`;
        this.modalButtonLabel = 'Reject';
        this.modalButtonVariant = 'destructive';
        this.comments = '';
        this.showModal = true;
    }

    closeModal() {
        this.showModal = false;
    }

    handleCommentsChange(event) {
        this.comments = event.target.value;
    }

    async handleConfirmAction() {
        this.isLoading = true;
        this.showModal = false;

        try {
            if (this.modalAction === 'SUBMIT') {
                const message = await submitForApproval({ pjpId: this.recordId, comments: this.comments });
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Submission Success',
                    message: message,
                    variant: 'success'
                }));
            } else if (this.modalAction === 'APPROVE') {
                const message = await processApproval({ pjpId: this.recordId, action: 'Approve', comments: this.comments });
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Plan Approved',
                    message: message,
                    variant: 'success'
                }));
            } else if (this.modalAction === 'REJECT') {
                const message = await processApproval({ pjpId: this.recordId, action: 'Reject', comments: this.comments });
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Plan Rejected',
                    message: message,
                    variant: 'warning'
                }));
            }

            await refreshApex(this.wiredPJPResult);
            // Also notify LDS
            setTimeout(() => {
                window.location.reload();
            }, 1200);
        } catch (error) {
            let msg = 'Unknown error';
            if (error && error.body && error.body.message) {
                msg = error.body.message;
            } else if (error && error.message) {
                msg = error.message;
            }
            this.dispatchEvent(new ShowToastEvent({
                title: 'Operation Failed',
                message: msg,
                variant: 'error'
            }));
        } finally {
            this.isLoading = false;
        }
    }
}
