global class RefreshTrailheadLeaderboard implements Schedulable {
    
    global void execute(SchedulableContext ctx) {
        
        /*
         * Update information of all Trailhead Users in the leaderboard (copied straight from updateAllTrailheadUsers() method from controller)
         */
        List<Trailhead_User__c> tUsers = [SELECT Id__c, Name, Badges__c, Points__c FROM Trailhead_User__c];
    	Map<String, Trailhead_User__c> tUsersInfo = new Map<String, Trailhead_User__c>();
        Map<String, String> singleTUserInfo = new Map<String, String>();
        
        for (Trailhead_User__c tUser : tUsers) {
            tUsersInfo.put(tUser.Id__c, tUser);
        }
        
    	// Update all users' Trailhead information
    	for (Trailhead_User__c tUser : tUsers) {
            singleTUserInfo.clear();
            singleTUserInfo = getInfoFromPage(tUser.Id__c);
    		tUsersInfo.get(tUser.Id__c).Name = singleTUserInfo.get('Name');
            tUsersInfo.get(tUser.Id__c).Badges__c = Integer.valueOf(singleTUserInfo.get('Badges__c').replaceAll(',', ''));
            tUsersInfo.get(tUser.Id__c).Points__c = Integer.valueOf(singleTUserInfo.get('Points__c').replaceAll(',', ''));
    	}
        
        update tUsersInfo.values();
        
    }
    
    /**
     * Parses the page source of a Trailhead profile page given a Trailhead User ID,
     * and returns a map containing the User's ID, Name, Badge Count, and Points.
     * (Also copied this right off the controller. I should fix this.)
     */
    public static Map<String, String> getInfoFromPage(String userId) {
        
        String url = 'https://trailhead.salesforce.com/en/users/profiles/' + userId;
        
        // Set up a map to hold Trailhead user information parsed from their public profile
        Map<String, String> trailheadUserInfo = new Map<String, String>();
        List<String> trailheadUserFields = new List<String>();
        trailHeadUserFields.add('Id__c');
        trailHeadUserFields.add('Name');
        trailHeadUserFields.add('Badges__c');
        trailHeadUserFields.add('Points__c');
        
        for (String fieldName : trailheadUserFields) {
            trailheadUserInfo.put(fieldName, '');
        }
        
        // Retrieve public profile page source       
        PageReference trailheadProfile = new PageReference(url);
        Blob pageSourceBlob = trailheadProfile.getContent();
        String pageSourceStr = pageSourceBlob.toString();
        
        // Ensure inputted Trailhead User Id is valid, exit otherwise
        Matcher errorRegex = Pattern.compile('<title>404 | Salesforce Trailhead</title>').matcher(pageSourceStr);
        Matcher privateRegex = Pattern.compile('<title>Trailhead | Private profile</title>').matcher(pageSourceStr);
        if (errorRegex.find() || privateRegex.find()) {
            return null;
        }
        
        // Capture user information from page source, and save it to the user information map
        String urlStr = 'https://trailhead.salesforce.com/en/users/profiles/(\\S*)';
        String nameStr = '<span class=\'th-profile-fullname\'>\\n(\\S*\\s\\S*)\\n</span>';
        String badgesStr = 'Badges\\n</h3>\\n</div>\\n<div class=\'panel-body text-center\'>\\n<h4 class=\'th-profile-title th-profile-title--green leading-marg-m\'>\\n(\\S*)\\n</h4>';
        String pointsStr = 'Points\\n</h3>\\n</div>\\n<div class=\'panel-body text-center\'>\\n<h4 class=\'th-profile-title th-profile-title--green leading-marg-m\'>\\n(\\S*)\\n</h4>';
       
        Pattern urlPattern = Pattern.compile(urlStr);
        Pattern namePattern = Pattern.compile(nameStr);
        Pattern badgesPattern = Pattern.compile(badgesStr);
        Pattern pointsPattern = Pattern.compile(pointsStr);
        
        Matcher urlRegex = urlPattern.matcher(url);
        Matcher nameRegex = namePattern.matcher(pageSourceStr);
        Matcher badgesRegex = badgesPattern.matcher(pageSourceStr);
        Matcher pointsRegex = pointsPattern.matcher(pageSourceStr);
        
        if (urlRegex.find()) {
            trailheadUserInfo.put('Id__c', urlRegex.group(1));
        }
        if (nameRegex.find()) {
            trailheadUserInfo.put('Name', nameRegex.group(1));
        }
        if (badgesRegex.find()) {
            trailheadUserInfo.put('Badges__c', badgesRegex.group(1));
        }
        if (pointsRegex.find()) {
            trailheadUserInfo.put('Points__c', pointsRegex.group(1));
        }

        return trailheadUserInfo;
    }

}