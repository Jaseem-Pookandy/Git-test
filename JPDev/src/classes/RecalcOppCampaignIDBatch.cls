/*******************************************************************
// (c) 2013 Doextra CRM Solutions
// 
// Description : Class to Calulate Opportunity's CampaignID to fix the historical err'ed data
// CC-XYZ
// September 26, 2013 : Tim Byrnes
/*******************************************************************/
//
// Execute this bad boy via the developer console, 'Execute Anonymous' like so:
// 
// RecalcOppCampaignIDBatch batchClass = new RecalcOppCampaignIDBatch();
// Id result = Database.executeBatch(batchClass, 100);
//
///////////////////////////
global class RecalcOppCampaignIDBatch implements Database.Batchable < sObject > {
	
	//Constructor...
	global RecalcOppCampaignIDBatch() {
		//nada...
	}



	//Start method...
	global Database.QueryLocator start(Database.BatchableContext BC) {
		//String query = 'SELECT CampaignId, IsClosed, Id, Brands__c, Contact__c, CloseDate, LastModifiedDate, CreatedDate FROM Opportunity WHERE CreatedDate >= 2013-08-03T00:00:00.000Z';
		String query = 'SELECT CampaignId, IsClosed, Id, Brands__c, Contact__c, CloseDate, LastModifiedDate, CreatedDate FROM Opportunity';
		return Database.getQueryLocator(query);
	}
	
	
	//Execute method...
	global void execute(Database.BatchableContext BC, List<Opportunity> batch) {
		
		List<Opportunity> oppsToUpdate = new List<Opportunity>();
		
		Set<String> contactIDs = new Set<String>();     
    	Map<String, List<CampaignMember>> ContactID_ListOfCampMemberMap = new Map<String, List<CampaignMember>>();
    	
    	for(Opportunity op : batch) {
        	contactIDs.add(op.Contact__c);
    	}
    	
    	if(contactIDs.size() > 0) {
        	for (CampaignMember cm : [SELECT Campaign.Brand__c, Campaign.Id, Campaign.Name, Campaign.StartDate, Campaign.EndDate, ContactId, ID, CreatedDate 
                                		FROM CampaignMember 
                                		WHERE ContactID IN :contactIDs  
                                		//AND Campaign.Influential_Campaign_Cutoff__c >= TODAY
                                		ORDER BY CreatedDate DESC]) {
                                			
          		if (!ContactID_ListOfCampMemberMap.containsKey(cm.ContactId)) {
            		ContactID_ListOfCampMemberMap.put(cm.ContactId, new List<CampaignMember>());
          		}
          	
          		ContactID_ListOfCampMemberMap.get(cm.ContactId).add(cm);
        	}
                
        	Set<String> brandSet = new Set<String>();
        
        	for (Opportunity oppty : batch) {
        		
        		Boolean bFound = false;
          		brandSet = new Set<String>();
          		
          		if (oppty.Brands__c != null) {
          			brandSet.addAll(String.valueOf(oppty.Brands__c).split(';'));          
                       
	                for (String optyBrand : brandSet) {
	            		if (ContactID_ListOfCampMemberMap.containsKey(oppty.Contact__c)) {
	                
	                		for (CampaignMember cm : ContactID_ListOfCampMemberMap.get(oppty.Contact__c)) {
	                			                  			
	                			//No more createddate comparison - now we're going off of closedate...
	                			//if ((String.valueOf(cm.Campaign.Brand__c).contains(optyBrand.trim())) && (bFound == false) && (cm.Campaign.StartDate <= oppty.CreatedDate)) {
	                			
	                			if (oppty.IsClosed) {
		                			if ((String.valueOf(cm.Campaign.Brand__c).contains(optyBrand.trim())) && 
		                						(bFound == false) && 
		                						(oppty.CloseDate >= cm.Campaign.StartDate) &&  
		                						(oppty.CloseDate <= cm.Campaign.EndDate)) {
		             
		                				//If we're here we've found the match.
		                				//Only update the opp though IF the campaign is truly different and needs updating.
		                				
		                				if (oppty.CampaignId != cm.CampaignId) {			
		                					oppty.CampaignId = cm.CampaignID;
		                					oppsToUpdate.add(oppty);
		                				}
		                				
		                				bFound = true;
		                				break;
		                			}	
	                			} else {
	                				if ((String.valueOf(cm.Campaign.Brand__c).contains(optyBrand.trim())) && (bFound == false) && (cm.Campaign.StartDate <= oppty.CreatedDate)) {
		             
		                				//If we're here we've found the match.
		                				//Only update the opp though IF the campaign is truly different and needs updating.
		                				
		                				if (oppty.CampaignId != cm.CampaignId) {			
		                					oppty.CampaignId = cm.CampaignID;
		                					oppsToUpdate.add(oppty);
		                				}
		                				
		                				bFound = true;
		                				break;
		                			}
	                			}
	              			}              			
	            		}         
	         		}
          		}
          		
         		//If we still haven't found the match after cycling through all the available campaignMembers AND the opp has a value, clear it.
         		//Otherwise do nothing...
         		if ((bFound == false) && (oppty.CampaignId != null)) {
              		oppty.CampaignId = null;
              		oppsToUpdate.add(oppty);			
              	}        
       		}
    	}   
    	
	   	if (oppsToUpdate.size() > 0) update oppsToUpdate;
	}
	
	
	//Finish method..
	global void finish(Database.BatchableContext BC) {
		//email myself....
		
		AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :BC.getJobId()];
    
    	List<String> ToAddresses = new List<String>();
    	ToAddresses.add('tim.byrnes@dice.com');
    
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();		
		mail.setToAddresses(ToAddresses);
		mail.setReplyTo('NoReply@dice.com');
		mail.setSenderDisplayName('Automated Notification - Opportunity.CampaignId');
		mail.setSubject('Batch process is completed');

		mail.setPlainTextBody('The batch \'RecalcOppCampaignIDBatch\' job just finished processing ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures.');		
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
	}
}