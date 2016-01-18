global class ScheduleDailyMarketoUserBatch implements Database.Batchable < sObject > {
  global String soqlQuery;
  global List<SObject> gllstScopeRecords;
  global List<User> UserUpdate;
  global Set<String> usrIdSet;
  // Class Constructor - set query string
  
  global ScheduleDailyMarketoUserBatch() {
    

  }
  
  // "Start" runs when the class in instanciated
  global Database.QueryLocator start(Database.BatchableContext bcMain) {

    User oUser;
    List<User> UserUpdate = new List<User>();
    Set<String> usrIdSet = new Set<String>();
    
    for(User usr : [Select Id, TriggerSync__c From User WHERE TriggerSync__c = true]){
      oUser = (User)usr;
      oUser.TriggerSync__c = false;
      System.debug('$$$$$$$$$$ : oUser.Id = ' + oUser.Id);
      UserUpdate.add(oUser);
      
      usrIdSet.add(oUser.Id);
    }
    System.debug('$$$$$$$$$$ : usrIdSet= ' + usrIdSet);
    //Now reset the trigger flag on the User
    if (UserUpdate.size() > 0) update UserUpdate;
    soqlQuery = 'SELECT Id FROM Contact_Type__c WHERE (Account_Brand__r.Primary_Owner__c IN : usrIdSet) OR (Account_Brand__r.CS__c IN : usrIdSet)';


    System.debug('$$$$$$$$$$ : soqlQuery = ' + soqlQuery );
    return Database.getQueryLocator(soqlQuery);
  }
  
  // "Execute" is what is being run as a separate process per batch
  global void execute(Database.BatchableContext bcMain, List<SObject> scope) {
    List<Contact_Type__c> CTUpdate = new List<Contact_Type__c>();
      
    Contact_Type__c CT;
    
    for(SObject o : scope) {
        CT = (Contact_Type__c)o;
        CTUpdate.add(CT);
    }
        
    
    //simply save the record to force the SystemModStamp to be update and trigger Marketo sync of record
    if (CTUpdate.size() > 0) update CTUpdate;
    
    //Now reset the trigger flag on the User
    //if (UserUpdate.size() > 0) update UserUpdate;
  }  
  
  //'Finish'
  global void finish(Database.BatchableContext bcMain) {
    //nothing here... yet... possibly email admin upon failure?
  }  
}