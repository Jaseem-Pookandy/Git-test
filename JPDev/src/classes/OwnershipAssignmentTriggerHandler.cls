/***************************************************************************
//
// Description    : Class that contains all of the functionality called by the 
//                  OwnershipAssignmentTrigger. All contexts should be in this class.
//                  
// Oct 15th, 2015  :  Byrnes - Created
//***************************************************************************/
public with sharing class OwnershipAssignmentTriggerHandler {
    private boolean m_isExecuting = false;  
    private integer BatchSize = 0;

    //Constructor
	public OwnershipAssignmentTriggerHandler(boolean isExecuting, Integer size){
		m_isExecuting = isExecuting;
	    BatchSize = size;
	}

	//On Before insert trigger method
  	public void OnBeforeInsert(List<Ownership_Assignment__c> newList) {   
    	SetUniqueKey(newList);
  	}
 
  	// On Before update trigger method
  	public void OnBeforeUpdate (Map<Id, Ownership_Assignment__c> oldMap, Map<Id, Ownership_Assignment__c> newMap) {    
	    SetUniqueKey(newMap.values());
  	}
 
  	//On after insert trigger method
  	public void OnAfterInsert(Map<Id, Ownership_Assignment__c> newMap) {   
	    //nothing yet...
  	}  
 
  	// On after update trigger method
  	public void OnAfterUpdate (Map<Id, Ownership_Assignment__c> oldMap, Map<Id, Ownership_Assignment__c> newMap) {    
	    //nothing yet...
  	}

  	// On after update trigger method
  	public void OnBeforeDelete (Map<Id, Ownership_Assignment__c> oldMap) {    
	    //nothing yet...
  	}  
 
  	// On after update trigger method
  	public void OnAfterDelete (Map<Id, Ownership_Assignment__c> oldMap) {    
	    //nothing yet...
  	}  
 
  	private void SetUniqueKey(List<Ownership_Assignment__c> newList) {
 
    	//Here we populate the unique key by concatenating Brand, '~', Country, '~', Region, '~', Product
    	//Note that REgion & Product have no use for the immediate eFC functionality, but that will have no negative side-effects so we're including it here
    	//for future scalability.

    	for (Ownership_Assignment__c oa : newList) {

    		String result = null;

    		if (oa.Brand__c == null || oa.Country__c == null) oa.addError('Missing required fields.  Both Brand & Country must be populated.');

    		//build the first part, always populated:
    		else {
    			result = oa.Brand__c + '~' + oa.Country_Name__c;

	    		//now the optional parts:
	    		if (oa.Region_State__c != null && oa.Region_State__c != '') result += '~' + oa.Region_State__c;
                else result += '~' + '';

	    		if (oa.Product__c != null && oa.Product__c != '') result += '~' + oa.Product__c;
                else result += '~' + '';

	    		oa.Unique_Key__c = result;
    		}
    	}
  	}
} // End of OwnershipAssignmentTriggerHandler class