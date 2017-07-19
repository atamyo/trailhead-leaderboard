public class TrailheadLeaderboardController {
    public List<Trailhead_User__c> trailheadUsers {get;set;}
    
    public TrailheadLeaderboardController() {
		trailheadUsers = [SELECT Id, Name, Badges__c, Points__c
                     FROM Trailhead_User__c];
        
    }
    
    public static void upsertUserTest(String profileUrl) {
        // Try getting html from my public trailhead page
		//String profileUrl = 'https://trailhead.salesforce.com/en/users/profiles/00550000006wMoaAAE';
        Map<String, String> tuInfo = getInfoFromPage(profileUrl);
        upsertTrailheadUser(tuInfo);
    }
    
    public static Map<String, String> getInfoFromPage(String url) {
        
        Map<String, String> trailheadUserInfo = new Map<String, String>();
        List<String> trailheadUserFields = new List<String>();
        trailHeadUserFields.add('Id__c');
        trailHeadUserFields.add('Name');
        trailHeadUserFields.add('Badges__c');
        trailHeadUserFields.add('Points__c');
        
        for (String fieldName : trailheadUserFields) {
            trailheadUserInfo.put(fieldName, '');
        }
               
        PageReference trailheadProfile = new PageReference(url);
        Blob pageSourceBlob = trailheadProfile.getContent();
        String pageSourceStr = pageSourceBlob.toString();
        
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
        
        // Get Id
        if (urlRegex.find()) {
            System.debug(urlRegex.group(1));
            trailheadUserInfo.put('Id__c', urlRegex.group(1));
        }
        // Get Name
        if (nameRegex.find()) {
            System.debug(nameRegex.group(1));
            trailheadUserInfo.put('Name', nameRegex.group(1));
        }
        // Get Badges
        if (badgesRegex.find()) {
            System.debug(badgesRegex.group(1));
            trailheadUserInfo.put('Badges__c', badgesRegex.group(1));
        }
        // Get Points
        if (pointsRegex.find()) {
            System.debug(pointsRegex.group(1));
            trailheadUserInfo.put('Points__c', pointsRegex.group(1));
        }

        return trailheadUserInfo;
    }
    
    public static void upsertTrailheadUser(Map<String, String> trailheadUserInfo) {
        
        /*
        // Attempting to dynamically create records
        sObject obj = Schema.getGlobalDescribe().get('Trailhead_User__c').newSObject();
        
        for (String fieldName : trailheadUserInfo.keySet()) {
            obj.put(fieldName, trailheadUserInfo.get(fieldName));
        }
        
        Trailhead_User__c tuser = (Trailhead_User__c) obj;
        insert tuser;
*/
        // Fake upsert for now
        
        String userId = trailheadUserInfo.get('Id__c');
                 
        // Insert new Trailhead User
        if (isNewUser(userId)) {
            Trailhead_User__c tuser = new Trailhead_User__c();
        	tuser.Id__c = trailheadUserInfo.get('Id__c');
        	tuser.Name = trailheadUserInfo.get('Name');
        	tuser.Badges__c = Integer.valueOf(trailheadUserInfo.get('Badges__c'));
        	tuser.Points__c = Integer.valueOf(trailheadUserInfo.get('Points__c').replaceAll(',', ''));
        
        	insert tuser;           
        }
        // Update existing Trailhead User
        else {
            Trailhead_User__c tuser = [SELECT Id__c FROM Trailhead_User__c WHERE Id__c =: userId LIMIT 1];
        	tuser.Name = trailheadUserInfo.get('Name');
        	tuser.Badges__c = Integer.valueOf(trailheadUserInfo.get('Badges__c'));
        	tuser.Points__c = Integer.valueOf(trailheadUserInfo.get('Points__c').replaceAll(',', ''));
        
        	update tuser;
        }
        	
        
    }
    
    public static Boolean isNewUser(String userId) {
        
        List<Trailhead_User__c> tUsers = [SELECT Id__c FROM Trailhead_User__c WHERE Id__c =: userId LIMIT 1];        
        return tUsers.size() == 0;
    }

}