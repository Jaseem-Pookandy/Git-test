/***************************************************************************
// (c) 2013 Appirio, Inc.
//
// Description    : Class that contains all of the functionality called by the 
//                  CampaignMemberTrigger. All contexts should be in this class.
//                  
// Jan 24th, 2013  :  Naresh Ojha (Appirio Offshore)
//***************************************************************************/
public with sharing class CampaignMemberTriggerHandler {
  private boolean m_isExecuting = false;  
  private integer BatchSize = 0;
    
  //Constructor
  public CampaignMemberTriggerHandler(boolean isExecuting, integer size){
    m_isExecuting = isExecuting;
    BatchSize = size;
  }

  //On before insert trigger method
  public void OnBeforeInsert(List<CampaignMember> newList) { 

  }  

  //On After insert trigger method
  public void OnAfterInsert(List<CampaignMember> newList) {
    //setPrimaryCampaignOnOpportunities(newList); 
    updateCmapaignMemberForAccountBrand (newList);
  }  

  //Task T-120610: CMmember to update the AB__c field on the Campaign Member 
  private void updateCmapaignMemberForAccountBrand (List<CampaignMember> newList) {
    Set<String> accIDset = new Set<String>();
    Map<String, Map<String, Account_Brand__c>> acID_Brand_AcountBrand_Map = 
                              new Map<String, Map<String, Account_Brand__c>>();
    List<CampaignMember> campaignMemberList = new List<CampaignMember>();
    List<CampaignMember> campaignMemberListLEAD = new List<CampaignMember>();
    List<CampaignMember> campaignMemberListToUpdate = new List<CampaignMember>();
    
    //Getting campaignMember details                                   
    for (CampaignMember cm : [SELECT Contact.AccountId, ContactId, Lead.Account_Brand__c, Lead.Account_Brand__r.Primary_Owner__c, Lead.OwnerId,
                                      Campaign.Brand__c, CampaignId , ID,
                                      Campaign.isCall_List__c  
                                  FROM CampaignMember 
                                  WHERE ID IN : newList]) {
        
        if (cm.Contact.AccountID <> null && cm.Campaign.isCall_List__c == true) {
            accIDset.add(cm.Contact.AccountID);
            campaignMemberList.add(cm);
        }else{
        
            //Handle Leads
            if (cm.LeadId <> null && cm.Campaign.isCall_List__c == true) {
                campaignMemberListLEAD.add(cm);
            }          
        
        }
        
      
    }
    
    //Populating account and account brand map.
    for (Account a : [SELECT Id, 
                          (SELECT Id, Brand__c, Brand_Name__c, Primary_Owner__c FROM Account_Brands__r) 
                          FROM Account WHERE ID IN :accIDset]) {
      if (a.Account_Brands__r.size () > 0) {
        for (Account_Brand__c ab : a.Account_Brands__r) {
          if (!acID_Brand_AcountBrand_Map.containsKey(a.ID)) {
            acID_Brand_AcountBrand_Map.put(a.ID, new Map<String, Account_Brand__c>());
          }
          acID_Brand_AcountBrand_Map.get(a.ID).put(ab.Brand_Name__c, ab);
        }
      }
    }
    
    //Assigning account brand.
    for (CampaignMember cm : campaignMemberList) {
        if (cm.Campaign.Brand__c <> null && 
               acID_Brand_AcountBrand_Map.containsKey(cm.Contact.AccountID) &&
               acID_Brand_AcountBrand_Map.get(cm.Contact.AccountID).containsKey(cm.Campaign.Brand__c)) { 
            //Here campaign brand__c is assumed to be a single brand name, not a multi select picklist values.
            cm.Account_Brand__c = acID_Brand_AcountBrand_Map.get(cm.Contact.AccountID).get(cm.Campaign.Brand__c).ID;
            cm.Owner_Assigned__c = acID_Brand_AcountBrand_Map.get(cm.Contact.AccountID).get(cm.Campaign.Brand__c).Primary_Owner__c;
            campaignMemberListToUpdate.add(cm);
        }
    }


    //Assigning account brand for Leads
    for (CampaignMember cm : campaignMemberListLEAD) {
        if (cm.Lead.Account_Brand__c <> null) { 
            cm.Account_Brand__c = cm.Lead.Account_Brand__c;
            cm.Owner_Assigned__c = cm.Lead.Account_Brand__r.Primary_Owner__c;
            campaignMemberListToUpdate.add(cm);
        }else{
        
            if(Lead.OwnerId != null && String.valueOf(cm.Lead.OwnerId).startsWith('005')){
                cm.Owner_Assigned__c = cm.Lead.OwnerId;
                campaignMemberListToUpdate.add(cm);
            
            }
        
        }
    }


    
    if (!campaignMemberListToUpdate.isEmpty()) {
          update campaignMemberListToUpdate;
    }
    
  }
  
  //---------------------------------------------------------------------------
  // Sets the Primary campaign Source on Opportunity
  //---------------------------------------------------------------------------  
  private void setPrimaryCampaignOnOpportunities(List<CampaignMember> newList) {
    Map<String, String> contactID_CampaignID_Map = new Map<String, String>();
    Map<String, String> oppID_ContactID_Map = new Map<String, String>();
    
    for(CampaignMember cm : newList) {
      if(cm.CampaignId <> null && cm.ContactId <> null) {
        if(!contactID_CampaignID_Map.containsKey(cm.ContactId)) {
            contactID_CampaignID_Map.put(cm.ContactId, cm.CampaignId);
        }               
      }
    }
    for(OpportunityContactRole opConRole : [Select OpportunityId, ContactId From OpportunityContactRole Where ContactId IN : contactID_CampaignID_Map.keySet()]) {
        if(!oppID_ContactID_Map.containsKey(opConRole.OpportunityId)) {
            oppID_ContactID_Map.put(opConRole.OpportunityID, opConRole.ContactId);
        }       
    }
    
    if(oppID_ContactID_Map <> null && oppID_ContactID_Map.size() > 0) {
        List<Opportunity> oppList = new List<Opportunity>();
        for(Opportunity opp : [SELECT ID, CampaignId FROM Opportunity Where ID IN :oppID_ContactID_Map.keySet() ORDER BY CreatedDate DESC]) {
                //if(opp.CampaignId == null) opp.CampaignId = contactID_CampaignID_Map.get(oppID_ContactID_Map.get(opp.ID)); Only for Convert?
                
                //Valdation rule override added for JIRA ticket CC-174
                opp.Validation_Rule_Override__c = system.now();
                oppList.add(opp);

        }
        if(oppList <> null && oppList.size() > 0) {
            update oppList;
        }
    }
    
  }  
}