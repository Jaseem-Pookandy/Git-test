/*******************************************************************
// (c) 2013 Appirio, Inc.
// 
// Description : Class to Calulate Active and inactive user allocations on Contact.
// calling style 3 
// T-151014
// June 14, 2013 : Karun Gangwani(Appirio Off)
/*******************************************************************/
global class RecalcContact4PUBatch implements Database.Batchable < sObject > {
	
	
	//---------------------------------------------------------------------------
	// Constructor
	//---------------------------------------------------------------------------
	global RecalcContact4PUBatch(){
    
  }
  
  //---------------------------------------------------------------------------
  // The Start Method
  //---------------------------------------------------------------------------
  global Database.QueryLocator start(Database.BatchableContext BC) {
  	String query = 'SELECT ID From Contact Order by LastModifiedDate limit 100 ';
    return Database.getQueryLocator(query);
  }
  
  //---------------------------------------------------------------------------
  // The execute Method
  //---------------------------------------------------------------------------
  global void execute(Database.BatchableContext BC, List <sObject> batch) {
    Set<ID> contactIdSet = new Set<ID>();
    for(sObject s : batch) {
    	contactIdSet.add(s.Id);
    }
    String csvIn = null;
    for(Contact c : [Select Id, (Select Id From Website_Users__r limit 1) 
                     From Contact Where ID IN :contactIdSet]) {
    	if(c.Website_Users__r.size() == 1) {
    		if(csvIn == null) {
    			csvIn = c.Id;
    		} else {
    			csvIn += ',' + c.Id;
    		}
    	}
    	if(csvIn <> null) {
    	  CommonUtil.recalcContact4PUSimple(csvIn);
    	}
    }
    
  } // end of execute()
  
  //---------------------------------------------------------------------------
  // The Finish Method
  // Does all Finishing work.
  //---------------------------------------------------------------------------
  global void finish(Database.BatchableContext BC) {
  	
  }           

}