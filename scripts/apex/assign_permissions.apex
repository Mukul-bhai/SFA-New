// Find SFA DMS permission set
PermissionSet ps = [SELECT Id, Name FROM PermissionSet WHERE Name = 'SFA_DMS_Admin' LIMIT 1];

// Find Nayan Patel and Neeraj Rajput
List<User> users = [SELECT Id, Name FROM User WHERE Name LIKE '%Nayan%' OR Name LIKE '%Neeraj%'];

List<PermissionSetAssignment> assignmentsToInsert = new List<PermissionSetAssignment>();

for (User u : users) {
    List<PermissionSetAssignment> existing = [
        SELECT Id FROM PermissionSetAssignment 
        WHERE AssigneeId = :u.Id AND PermissionSetId = :ps.Id
    ];
    if (existing.isEmpty()) {
        assignmentsToInsert.add(new PermissionSetAssignment(
            AssigneeId = u.Id,
            PermissionSetId = ps.Id
        ));
    }
}

if (!assignmentsToInsert.isEmpty()) {
    insert assignmentsToInsert;
    System.debug('Successfully assigned SFA DMS permission set to ' + assignmentsToInsert.size() + ' users!');
} else {
    System.debug('Users already have the permission set assigned.');
}
