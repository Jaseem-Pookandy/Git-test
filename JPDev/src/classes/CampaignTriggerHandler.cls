/***************************************************************************
// (c) 2012 Appirio, Inc.
//
// Description    : Class that contains all of the functionality called by the 
//                  CampaignTrigger. All contexts should be in this class.
//                  
// Mar 01st, 2013  :  Naresh Ojha (Appirio Offshore)
//***************************************************************************/
public with sharing class CampaignTriggerHandler {
  private boolean m_isExecuting = false;  
  private integer BatchSize = 0;
    
    //Constructor
  public CampaignTriggerHandler(boolean isExecuting, integer size){
    m_isExecuting = isExecuting;
    BatchSize = size;
  }
  
  //On Before Insert trigger method
  public void OnBeforeInsert(List<Campaign> newList) { 
    preventMultiBrandsWhenCallList (newList);
  }  

  //On Before Update trigger method
  public void OnBeforeUpdate(Map<ID, Campaign> oldMap, List<Campaign> newList) { 
    preventMultiBrandsWhenCallList (newList);
  }  

  //T-120612: prevent multiple brands from being selected when isCall_List__c = true
  private void preventMultiBrandsWhenCallList ( List<Campaign> newList) {
    for (Campaign campaign : newList) {
      if (campaign.isCall_List__c == true && ( campaign.Brand__c == null || String.valueOf(campaign.Brand__c).contains(';')  )      ) {
        campaign.addError('Call List Campaigns require (1) and only (1) Brand to be selected.');
      }
    }   
  }
}