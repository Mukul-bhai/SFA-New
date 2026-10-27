public with sharing class PJPApprovalController {

    public class PJPApprovalInfo {
        @AuraEnabled public String idii; 
        @AuraEnabled public String name;
        @AuraEnabled public String status;
        @AuraEnabled public String employeeName;
        @AuraEnabled public String employeeHierarchy;
        @AuraEnabled public String reportingManagerName;
        @AuraEnabled public String reportingManagerId;
        @AuraEnabled public Integer totalBeats;
        @AuraEnabled public Integer totalOutlets;
        @AuraEnabled public String month;
        @AuraEnabled public String year;
        @AuraEnabled public Boolean isManagerOrAdmin;
        @AuraEnabled public Boolean canSubmit;
    }

    @AuraEnabled(cacheable=true)
    public static PJPApprovalInfo getPJPApprovalDetails(Id pjpId) {
        if (pjpId == null) {
            throw new AuraHandledException('Invalid PJP Record ID');
        }

        List<PJP__c> pjps = [
            SELECT Id, Name, Status__c, Month__c, Year__c, Total_Beats__c, Total_Outlets__c,
                   Employee__c, Employee__r.Name, Employee__r.Hierarchy_Level__c,
                   Employee__r.Reporting_Manager__c, Employee__r.Reporting_Manager__r.Name,
                   Reporting_Manager__c, Reporting_Manager__r.Name, User__c
            FROM PJP__c
            WHERE Id = :pjpId
            LIMIT 1
        ];

        if (pjps.isEmpty()) {
            throw new AuraHandledException('PJP Record not found');
        }

        PJP__c pjp = pjps[0];
        PJPApprovalInfo info = new PJPApprovalInfo();
        info.id = pjp.Id;
        info.name = pjp.Name;
        info.status = String.isNotBlank(pjp.Status__c) ? pjp.Status__c : 'Draft';
        info.month = pjp.Month__c;
        info.year = pjp.Year__c;
        info.totalBeats = pjp.Total_Beats__c != null ? Integer.valueOf(pjp.Total_Beats__c) : 0;
        info.totalOutlets = pjp.Total_Outlets__c != null ? Integer.valueOf(pjp.Total_Outlets__c) : 0;

        if (pjp.Employee__c != null) {
            info.employeeName = pjp.Employee__r.Name;
            info.employeeHierarchy = pjp.Employee__r.Hierarchy_Level__c;
            if (pjp.Reporting_Manager__c != null) {
                info.reportingManagerId = pjp.Reporting_Manager__c;
                info.reportingManagerName = pjp.Reporting_Manager__r.Name;
            } else if (pjp.Employee__r.Reporting_Manager__c != null) {
                info.reportingManagerId = pjp.Employee__r.Reporting_Manager__c;
                info.reportingManagerName = pjp.Employee__r.Reporting_Manager__r.Name;
            }
        }

        Id currentUserId = UserInfo.getUserId();
        Boolean isAdmin = [SELECT Profile.PermissionsModifyAllData FROM User WHERE Id = :currentUserId].Profile.PermissionsModifyAllData;
        Boolean isManager = (info.reportingManagerId != null && currentUserId == info.reportingManagerId);

        info.isManagerOrAdmin = isAdmin || isManager;
        info.canSubmit = (info.status == 'Draft' || info.status == 'Rejected');

        return info;
    }

    @AuraEnabled
    public static String submitForApproval(Id pjpId, String comments) {
        if (pjpId == null) {
            throw new AuraHandledException('Invalid PJP Record ID');
        }

        PJP__c pjp = [
            SELECT Id, Name, Status__c, Employee__c, Employee__r.Reporting_Manager__c, Reporting_Manager__c
            FROM PJP__c
            WHERE Id = :pjpId
            LIMIT 1
        ];

        // Ensure Reporting Manager is assigned from Employee if not set
        Id approverId = pjp.Reporting_Manager__c;
        if (approverId == null && pjp.Employee__c != null && pjp.Employee__r.Reporting_Manager__c != null) {
            approverId = pjp.Employee__r.Reporting_Manager__c;
            pjp.Reporting_Manager__c = approverId;
        }

        // Update status to Submitted
        pjp.Status__c = 'Submitted';
        if (String.isNotBlank(comments)) {
            pjp.Remarks__c = comments;
        }
        update pjp;

        // Try standard Salesforce approval process if active
        try {
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setComments(String.isNotBlank(comments) ? comments : 'PJP submitted for reporting manager approval.');
            req.setObjectId(pjpId);
            if (approverId != null) {
                req.setNextApproverIds(new Id[] { approverId });
            }
            Approval.ProcessResult res = Approval.process(req);
        } catch (Exception ex) {
            // If approval process is pending activation or not configured, status update to Submitted suffices
            System.debug('Standard approval submission notice: ' + ex.getMessage());
        }

        return 'PJP submitted successfully to reporting manager for approval.';
    }

    @AuraEnabled
    public static String processApproval(Id pjpId, String action, String comments) {
        if (pjpId == null || String.isBlank(action)) {
            throw new AuraHandledException('Invalid parameters for approval decision');
        }

        PJP__c pjp = [
            SELECT Id, Name, Status__c, Approval_Comments__c, Approved_Date__c
            FROM PJP__c
            WHERE Id = :pjpId
            LIMIT 1
        ];

        Boolean isApprove = (action.equalsIgnoreCase('Approve'));
        pjp.Status__c = isApprove ? 'Approved' : 'Rejected';
        pjp.Approval_Comments__c = comments;
        if (isApprove) {
            pjp.Approved_Date__c = System.now();
        }
        update pjp;

        // Process standard approval work item if exists
        try {
            List<ProcessInstanceWorkitem> workItems = [
                SELECT Id FROM ProcessInstanceWorkitem
                WHERE ProcessInstance.TargetObjectId = :pjpId
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            if (!workItems.isEmpty()) {
                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                req.setWorkitemId(workItems[0].Id);
                req.setAction(isApprove ? 'Approve' : 'Reject');
                req.setComments(comments);
                Approval.process(req);
            }
        } catch (Exception ex) {
            System.debug('WorkItem processing notice: ' + ex.getMessage());
        }

        return isApprove ? 'PJP has been successfully APPROVED!' : 'PJP has been REJECTED.';
    }
}
