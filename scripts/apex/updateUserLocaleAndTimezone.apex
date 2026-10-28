List<User> usersToUpdate = [
    SELECT Id, Username, Profile.Name, TimeZoneSidKey, LocaleSidKey 
    FROM User 
    WHERE UserType = 'Standard' 
      AND (Profile.Name = 'System Administrator' OR Profile.Name = 'Standard User')
];

for (User u : usersToUpdate) {
    u.TimeZoneSidKey = 'Asia/Kolkata';
    u.LocaleSidKey = 'en_IN';
    try {
        update u;
        System.debug('Updated ' + u.Username + ' to Asia/Kolkata and en_IN');
    } catch (Exception ex) {
        System.debug('Failed to update ' + u.Username + ': ' + ex.getMessage());
    }
}
