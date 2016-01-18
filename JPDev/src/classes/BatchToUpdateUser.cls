global class BatchToUpdateUser implements Database.Batchable<SObject>{
    
    global Database.QueryLocator start(Database.BatchableContext bi){
        return Database.getQueryLocator([select LastLoginDate from User where isActive = true]); 
                                      
    }
   
   /*
    *  execute the bach process 
    */
    global void execute(Database.BatchableContext bi, List<sObject> scope){
        
        List<User> userList = (List<sObject>)scope;
        List<User> userListToUpdate = new List<User>();
        
        for(User u :userList) {
            DateTime lastLogin = u.LastLoginDate;
            if(lastLogin != null) {
                u.Days_Since_Last_Login__c = Date.newInstance(lastLogin.year(), lastLogin.month(), lastLogin.day()).daysBetween(System.today());
                userListToUpdate.add(u);
            }
    
        } 
        try {
            if(userListToUpdate != null && userListToUpdate.size() > 0) {
                update userListToUpdate;
            } 
        } catch(Exception e) {
            System.debug('-- DEBUG --' + e.getMessage());
        }
    }//end of method
    
   /*
    *  Send information After execute the bach process 
    */
    global void finish(Database.BatchableContext bi){       
       
    }
}