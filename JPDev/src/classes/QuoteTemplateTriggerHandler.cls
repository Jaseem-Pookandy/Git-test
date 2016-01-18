//Byrnes
//2014.10.02

//All the logic for Quote Template trigger handler


public with sharing class QuoteTemplateTriggerHandler {

	private Boolean m_isExecuting = false;
	private integer BatchSize = 0;

    public QuoteTemplateTriggerHandler(Boolean isExecuting, Integer size) {
    	m_isExecuting = isExecuting;
    	BatchSize = size;
    }

    //On Before Insert method
    public void OnBeforeInsert(List<zqu__Quote_Template__c> newList) {
		PopulateCustomFields(newList);
    }

	// On Before update trigger method
	public void OnBeforeUpdate (Map<Id, zqu__Quote_Template__c> oldMap, Map<Id, zqu__Quote_Template__c> newMap) {    
		PopulateCustomFields(newMap.values());
	}

	//On after insert trigger method
	public void OnAfterInsert(Map<Id, zqu__Quote_Template__c> newMap) {   
		//Nothing yet...
	}  

	// On after update trigger method
	public void OnAfterUpdate (Map<Id, zqu__Quote_Template__c> oldMap, Map<Id, zqu__Quote_Template__c> newMap) {    
		//Nothing yet...
	}

	// On after update trigger method
	public void OnBeforeDelete (Map<Id, zqu__Quote_Template__c> oldMap) {    
		//Nothing yet...
	}  

	// On after update trigger method
	public void OnAfterDelete (Map<Id, zqu__Quote_Template__c> oldMap) {    
		//Nothing yet...
	}

	private void PopulateCustomFields(List<zqu__Quote_Template__c> newList) {
		//Here we populate the BrandTag & Language fields
		//The format of the name we are expecting is this:
			//BrandTag Language Rest of the name goes here
			//ex:  eFC-EMEA French Agency Quote
			//ex:  Dice English Bundle Quote

		for (zqu__Quote_Template__c qt : newList) {
			List<String> parts = qt.Name.trim().split(' ', 5);

			if (parts.size() < 4) {
				qt.BrandTag__c 	   = 'Invalid Format';
				qt.Language__c 	   = 'Invalid Format';
				qt.Sold_By__c 	   = 'Invalid Format';
				qt.Detail_Level__c = 'Invalid Format';
			}
			else {
				qt.BrandTag__c 		= parts[0];
				qt.Language__c 		= parts[1];

				if (parts[2] != null && parts[2].startsWith('A')) qt.Sold_By__c = 'Agency Sale';
				else if (parts[2] != null && parts[2].startsWith('D')) qt.Sold_By__c = 'Direct Sale';
				else qt.Sold_By__c = 'Unexpected Value';

				if (parts[3] != null && parts[3] == 'B') qt.Detail_Level__c = 'Bundled';
				else if (parts[3] != null && parts[3] == 'D') qt.Detail_Level__c = 'Detailed';
				else qt.Detail_Level__c = 'Unexpected Value';

				qt.Display_Name__c = qt.BrandTag__c + ' ' + parts[4];
			}
		}
	}
}