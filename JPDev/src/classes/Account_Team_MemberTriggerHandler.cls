/***************************************************************************
// (c) 2012 Appirio, Inc.
//
// Description    : Class that contains all of the functionality called by the 
//                  Account_Team_MemberTrigger. All contexts should be in this class.
//                  
// Dec 12th, 2012  :  Naresh Ojha
//***************************************************************************/
public with sharing class Account_Team_MemberTriggerHandler {
    
  private boolean m_isExecuting = false;  
  private integer BatchSize = 0;
  
  //Constructor
  public Account_Team_MemberTriggerHandler(boolean isExecuting, integer size){
    m_isExecuting = isExecuting;
    BatchSize = size;
  }
  
  //On before insert trigger method
  public void OnBeforeInsert(List<Account_Team_Member__c> newList) {   
    createAccountTeamMembers(newList);
  }  
  //On before insert trigger method
  public void OnAfterInsert(List<Account_Team_Member__c> newList) {   
    Set<String> accIdSet = new Set<String>();
    for (Account_Team_Member__c a_t_m : newList) {
      accIdSet.add(a_t_m.Account__c);
    }    
    CommonUtil.recallATM(accIdSet);
  } 
  // On before update trigger method
  public void OnBeforeUpdate (Map<Id, Account_Team_Member__c> oldMap, 
                              Map<Id, Account_Team_Member__c> newMap) {    
    updateAccountTeamMembers(oldMap, newMap);
  }
  // On before update trigger method
  public void OnAfterDelete (Map<Id, Account_Team_Member__c> oldMap) {

    Set<String> accIdSet = new Set<String>();
    for (Account_Team_Member__c ab : oldMap.values()) {
      accIdSet.add(ab.Account__c);
    }
    CommonUtil.recallATM(accIdSet);    
  }
  // On after update trigger method
  public void OnAfterUpdate (Map<Id, Account_Team_Member__c> oldMap, 
                              Map<Id, Account_Team_Member__c> newMap) {
    Set<String> accIdSet = new Set<String>();
    for (Account_Team_Member__c a_t_m : newMap.values()) {
      accIdSet.add(a_t_m.Account__c);
    }    
    CommonUtil.recallATM(accIdSet);
  }
  
  
  //==========================================================================//
  // Method that creates the Account Team Members
  //==========================================================================//
  private void createAccountTeamMembers(List<Account_Team_Member__c> newList) {
  	

  	AccountTeamMember atmObj;
    
    List<AccountTeamMember> atmList = new List<AccountTeamMember>();
    
    Set<Id> accIdSet = new Set<Id>();
    
    for(Account_Team_Member__c a_t_m : newList) {
      if(a_t_m.User__c <> null) {
        accIdSet.add(a_t_m.Account__c);
        atmObj = new AccountTeamMember();
        atmObj.UserId = a_t_m.User__c;
        atmObj.AccountId = a_t_m.Account__c;
        atmObj.TeamMemberRole = a_t_m.Role__c;
        atmList.add(atmObj);
      }        
    }

    if(!atmList.isEmpty()) {
      insert atmList;
    }
      
  } // End of createAccountTeamMembers()
  
  //==========================================================================//
  // Mehtod that updates the AccountTeamMember Records on before Update
  //==========================================================================//  
  private void updateAccountTeamMembers(Map<Id, Account_Team_Member__c> oldMap, 
                                        Map<Id, Account_Team_Member__c> newMap) {

    AccountTeamMember atmObj;
    
    List<AccountTeamMember> atmList = new List<AccountTeamMember>();
    Set<ID> atmSet_delete = new Set<ID>();
    
    Set<Id> accIdSet = new Set<Id>();
        
    for(Account_Team_Member__c a_t_m : newMap.values()) {
      if(oldmap.get(a_t_m.Id).User__c <> a_t_m.User__c) {
        //Primary 
        if(a_t_m.User__c <> null) {
            accIdSet.add(a_t_m.Account__c);
            atmObj = new AccountTeamMember();
            atmObj.UserId = a_t_m.User__c;
            atmObj.AccountId = a_t_m.Account__c;
            atmObj.TeamMemberRole = a_t_m.Role__c;
            atmList.add(atmObj);
        }        
      }        
    }    
     
    if(!atmList.isEmpty()) {
      insert atmList;
    }

  } // End of updateAccountTeamMembers()
}