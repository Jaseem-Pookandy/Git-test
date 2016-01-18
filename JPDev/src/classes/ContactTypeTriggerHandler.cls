public with sharing class ContactTypeTriggerHandler {
  private boolean m_isExecuting = false;  
  private integer BatchSize = 0;
  
  //Constructor
  public ContactTypeTriggerHandler(boolean isExecuting, integer size){
    m_isExecuting = isExecuting;
    BatchSize = size;
  }


  // On before update trigger method
  public void OnBeforeUpdate (Map<Id, Contact_Type__c> oldMap, Map<Id, Contact_Type__c> newMap) 
  {

  }
  
  //On after insert trigger method
  public void OnAfterInsert(Map<Id, Contact_Type__c> newMap) {   
  	
  	if (ContactTriggerHelper.isFirstRun)
  	{
  		ContactTriggerHelper.isFirstRun = false;
  		//KeepNoEmailInSync(oldMap, newMap);
  		
  		RecalcContactsAuthorizedRollup(newMap.values()); 
  	}	  	
  }    
  
  // On after update trigger method
  public void OnAfterUpdate (Map<Id, Contact_Type__c> oldMap, Map<Id, Contact_Type__c> newMap) {   
  	
  	if (ContactTriggerHelper.isFirstRun)
  	{
  		ContactTriggerHelper.isFirstRun = false;
  		KeepNoEmailInSync(oldMap, newMap);
  		
  		RecalcContactsAuthorizedRollup(newMap.values()); 
  	}	  	
  }  
  
  
  // On after update trigger method
  public void OnAfterDelete (Map<Id, Contact_Type__c> oldMap) {    
    RecalcContactsAuthorizedRollup(oldMap.values());
  }    
  
  private static void RecalcContactsAuthorizedRollup(List<Contact_Type__c> recordList) {
  	Set<Id> contactIDSet = new Set<Id>();
  	
  	for (Contact_Type__c ct : recordList) {
  		contactIDSet.add(ct.Contact__c);
  	}
  	
  	if (contactIDSet.size() > 0) CommonUtil.recalcContactAuthorized(contactIDSet);  	
  }
  
  
  private void KeepNoEmailInSync(Map<Id, Contact_Type__c> oldMap, Map<Id, Contact_Type__c> newMap)
  {
  	List<Contact> contactsToUpdate = new List<Contact>();  	
  	
  	Set<Id> contactIds = new Set<Id>();
  	Set<Id> contactTypeIds = newMap.keySet();
  	
  	for(Id contactTypeId : contactTypeIds)
  	{
  		contactIds.add(newMap.get(contactTypeId).Contact__c);
  	} 	
  	
  	Map<Id, Contact> cMap = new map<Id, Contact>([SELECT Id, No_Email__c FROM Contact WHERE Id IN :contactIds]);  	  	  	
  	Map<Id, List<Contact_Type__c>> iterableMap = new Map<Id, List<Contact_Type__c>>();	//ID will be ContactId
  	
  	List<Contact_Type__c> contactTypes_All = [SELECT Id, Never_Email__c, Contact__c FROM Contact_Type__c WHERE Contact__c IN :contactIds];
  	List<Contact_Type__c> contactTypes_NotEdited = new List<Contact_Type__c>();
  	
  	for (Contact_Type__c allCT : contactTypes_All)
  	{
  		if (!newMap.containsKey(allCT.Id)) contactTypes_NotEdited.add(allCT);
  	}
  	 
  	//For each contactType record that was changed....
  	for (Id ctId : contactTypeIds)
  	{
  		//get the ContactID now...
  		Id conId = newMap.get(ctId).Contact__c;
  		
  		//for each contactType id in keyset...
  		if (iterableMap.containsKey(conId))
  		{
  			//Then work the list...
  			List<Contact_Type__c> ctList = iterableMap.get(conId);
  			ctList.add(newMap.get(ctId));			
  			iterableMap.put(conId, ctList);
  		}
  		else
  		{
  			//Insert...
  			List<Contact_Type__c> ctList = new List<Contact_Type__c>();
  			ctList.add(newMap.get(ctId));			
  			iterableMap.put(conId, ctList);
  		}
  	}
  	//the map 'iterableMap' is now correct for all contactTypes that are edited in the newMap collection
  	
  	//Now, go through all that aren't edited...
  	
	//For each contactType record that was NOT changed....
  	for (Contact_Type__c ct : contactTypes_NotEdited)
  	{
  		//get the ContactID now...
  		Id conId = ct.Contact__c;
  		
  		//for each contactType id in keyset...
  		if (iterableMap.containsKey(conId))
  		{
  			//Then work the list...
  			List<Contact_Type__c> ctList = iterableMap.get(conId);
  			ctList.add(ct);			
  			iterableMap.put(conId, ctList);
  		}
  		else
  		{
  			//Insert...
  			List<Contact_Type__c> ctList = new List<Contact_Type__c>();
  			ctList.add(ct);			
  			iterableMap.put(conId, ctList);
  		}
  	}  	
	  	 
  	//Should be set...  
  	//Homework is done, now run through the test cases...
  	for (List<Contact_Type__c> listCTs : iterableMap.values())
  	{
  		//if there is at least one object in the list for this current account...
  		if (listCTs.size() > 0)
  		{
  			Id currentContactId = listCTs[0].Contact__c;
  			Contact currentContact = cMap.get(currentContactId);
  			Boolean bContactNoEmailShouldBeChecked = false;
  			Integer iCountofCTChecked = 0;
  			
  			for (Contact_Type__c ct : listCTs)
  			{
  				if (ct.Never_Email__c) iCountofCTChecked++;
  			}
  			
  			if (iCountofCTChecked == listCTs.size()) bContactNoEmailShouldBeChecked = true;
  			else bContactNoEmailShouldBeChecked = false;
  			
  			//Now compare the boolean field with the actual value at the contact level...
  			if (currentContact.No_Email__c != bContactNoEmailShouldBeChecked) 
  			{
  				currentContact.No_Email__c = bContactNoEmailShouldBeChecked;
  				contactsToUpdate.add(currentContact);
  			}
  		}  		
  	}
  	
  	if (contactsToUpdate.size() > 0) update contactsToUpdate;
  }
}