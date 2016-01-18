global class ScheduleDailyPreMarketoBatch implements Database.Batchable < sObject > {
  global String soqlQuery;
  global List<SObject> gllstScopeRecords;
  global integer lookbackdays;

  // Class Constructor - set query string
  global ScheduleDailyPreMarketoBatch() {
  
    Decimal DecimalVal = [SELECT Lookback_Days__c FROM Marketo_Batchable_Settings__c WHERE Name = 'Days' LIMIT 1].Lookback_Days__c;
    lookbackdays = decimalVal.intValue();

    soqlQuery = 'Select usr.TriggerSync__c From User usr where TriggerSync__c = true AND SystemModstamp = LAST_N_DAYS:'+lookbackdays+ ' LIMIT 1';

  }
  
  // "Start" runs when the class in instanciated
  global Database.QueryLocator start(Database.BatchableContext bcMain) {
    System.debug('$$$$$$$$$$ : soqlQuery = ' + lookbackdays );
    System.debug('$$$$$$$$$$ : soqlQuery = ' + soqlQuery );
    return Database.getQueryLocator(soqlQuery);
  }
  
  // "Execute" is what is being run as a separate process per batch
  global void execute(Database.BatchableContext bcMain, List<SObject> scope) {
    List<Account_Brand__c> ABUpdate = new List<Account_Brand__c>();
    List<Contact_Type__c> CTUpdate = new List<Contact_Type__c>();
    List<User> UserUpdate = new list<User>();
    Set<String> usrIdSet = new Set<String>();
    Set<String> abIdSet = new Set<String>();
    
    User oUser;
    for(SObject o : scope) {
      oUser = (User)o;
      usrIdSet.add(oUser.Id);
      
      oUser.TriggerSync__c = false;
      UserUpdate.add(oUser);
    }
    System.debug('$$$$$$$$$$ : usrIdSet= ' + usrIdSet); 
    Account_Brand__c oAB;
       
    for(Account_Brand__c ACB : [SELECT Id, Primary_Owner__c, CS__c FROM Account_Brand__c WHERE (Primary_Owner__c IN : usrIdSet) OR (CS__c IN : usrIdSet)]){
      oAB = (Account_Brand__c)ACB;
      abIdSet.add(oAB.id);
      //ABUpdate.add(ACB);
    }
    System.debug('$$$$$$$$$$ : abIdSet= ' + abIdSet);
    for(Contact_Type__c CT : [SELECT Id, Account_Brand__c FROM Contact_Type__c WHERE Account_Brand__c IN : abIdSet]){
      CTUpdate.add(CT);
    }
    
    //simply save the record to force the SystemModStamp to be update and trigger Marketo sync of record
    if (CTUpdate.size() > 0) update CTUpdate;
    
    //Now reset the trigger flag on the User
    if (UserUpdate.size() > 0) update UserUpdate;
  }  
  
  //'Finish'
  global void finish(Database.BatchableContext bcMain) {
    //nothing here... yet... possibly email admin upon failure?
  }  
}