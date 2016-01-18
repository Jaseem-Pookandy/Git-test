global class ScheduleDailyMarketoBatch implements Database.Batchable < sObject > {
  global String soqlQuery;
  global List<SObject> gllstScopeRecords;
  global integer lookbackdays;

  // Class Constructor - set query string
  global ScheduleDailyMarketoBatch() {
    Decimal DecimalVal = [SELECT Lookback_Days__c FROM Marketo_Batchable_Settings__c WHERE Name = 'Days' LIMIT 1].Lookback_Days__c;
    lookbackdays = decimalVal.intValue();

    soqlQuery = 'Select ab.LastModifiedDate, ab.Id, ab.SystemModstamp'; 
    soqlQuery += ' From Account_Brand__c ab where SystemModstamp = TODAY OR SystemModstamp = LAST_N_DAYS:'+lookbackdays;

  }
  
  // "Start" runs when the class in instanciated
  global Database.QueryLocator start(Database.BatchableContext bcMain) {
    System.debug('$$$$$$$$$$ : soqlQuery = ' + lookbackdays );
    System.debug('$$$$$$$$$$ : soqlQuery = ' + soqlQuery );
    return Database.getQueryLocator(soqlQuery);
  }
  
  // "Execute" is what is being run as a separate process per batch
  global void execute(Database.BatchableContext bcMain, List<SObject> scope) {
    List<Contact_Type__c> CTUpdate = new List<Contact_Type__c>();
    Set<String> abIdSet = new Set<String>();
    Account_Brand__c AcctBrand;
    for(SObject o : scope) {
      AcctBrand = (Account_Brand__c)o;
      abIdSet.add(AcctBrand.Id);
    }
    
    for(Contact_Type__c CT : [SELECT Id, Account_Brand__c FROM Contact_Type__c WHERE Account_Brand__c IN : abIdSet]){
      CTUpdate.add(CT);
    }
    
    //simply save the record to force the SystemModStamp to be update and trigger Marketo sync of record
    if (CTUpdate.size() > 0) update CTUpdate;
  }  
  
  //'Finish'
  global void finish(Database.BatchableContext bcMain) {
    //nothing here... yet... possibly email admin upon failure?
  }  
}