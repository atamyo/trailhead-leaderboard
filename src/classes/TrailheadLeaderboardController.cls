public class TrailheadLeaderboardController {
    
    public String sortField = 'Name';
    public String sortIn = 'ASC';
    public String prevSortField = sortField;
    
    public String inputUserId {get; set;}

    public List<Trailhead_User__c> getTrailheadUsers() {
        
        List<Trailhead_User__c> results = Database.query(
            'SELECT Id__c, Name, Badges__c, Points__c ' +
            'FROM Trailhead_User__c ' +
            'ORDER BY ' + sortField + ' ' + sortIn
        );
        
        return results;
    }
    
    public TrailheadLeaderboardController() {
        this.inputUserId = '';        
    }
    
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
    
    public void addToLeaderboard() {
        
        if (isNewUser(this.inputUserId)) {
            Map<String, String> userInfo = getInfoFromPage(this.inputUserId);
            
            if (userInfo != null) {
                insertTrailheadUser(userInfo);
            }
            else {
                ApexPages.Message invalidUserId = new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter a valid Trailhead ID.');
                ApexPages.addMessage(invalidUserId);
            }         
        }
    }

    
    public static void insertTrailheadUser(Map<String, String> trailheadUserInfo) {
        	
        Trailhead_User__c tuser = new Trailhead_User__c();
        
        tuser.Id__c = trailheadUserInfo.get('Id__c');
        tuser.Name = trailheadUserInfo.get('Name');
        tuser.Badges__c = Integer.valueOf(trailheadUserInfo.get('Badges__c'));
        tuser.Points__c = Integer.valueOf(trailheadUserInfo.get('Points__c').replaceAll(',', ''));
        
        insert tuser;  
        
    }
    
    public static Boolean isNewUser(String userId) {
        
        List<Trailhead_User__c> tUsers = [SELECT Id__c FROM Trailhead_User__c WHERE Id__c =: userId LIMIT 1]; // empty if user with specified Id is not in the leaderboard
        return tUsers.size() == 0;
        
    }
    
    public static void updateAllTrailheadUsers() {
    	
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
    
    public PageReference refreshLeaderboard() {
        
        updateAllTrailheadUsers();
     
        String url = 'http://angelinetamayo-developer-edition.na50.force.com/TrailheadLeaderboard';       
        PageReference refreshPage = new PageReference(url);
        refreshPage.setRedirect(true);
        return refreshPage;       
    }
    
    /*
     * Sorting methods for records
     */
    
    public void sortByName() {
        sortHandler('Name');
    }
    
    public void sortByBadges() {
        sortHandler('Badges__c');
    }
    
    public void sortByPoints() {
        sortHandler('Points__c');
    }
    
    public void sortHandler(String field) {
        this.prevSortField = this.sortField;
        this.sortField = field;
        
        if (this.prevSortField == this.sortField) {
            toggleSortIn();
        }
        else {
            sortInAsc();
        }
    }
    
    public void toggleSortIn() {
        if (this.sortIn == 'ASC') {
            sortInDesc();
        }
        else {
            sortInAsc();
        }
    }
    
    public void sortInAsc() {
        this.sortIn = 'ASC';
    }
    
    public void sortInDesc() {
        this.sortIn = 'DESC';
    }
}