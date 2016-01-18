/***************************************************************************
// Description    : Class that contains all of the functionality called by the 
//                  DailyProductivityTrigger. All contexts should be in this class.
//                  
// 04/17/2014  :  Mike Bergman
// 04/25/2014  :  Byrnes - Ripped out Sales Rep per the business.
//***************************************************************************/
public with sharing class DailyProductivityTriggerHandler {

  private boolean m_isExecuting = false;  
  private integer BatchSize = 0;
  
  //Constructor
  public DailyProductivityTriggerHandler(boolean isExecuting, integer size){
    m_isExecuting = isExecuting;
    BatchSize = size;
  }

  //On Before Insert trigger method
  public void OnBeforeInsert(List<Daily_Productivity__c> newList) { 

  }  

  //On Before Update trigger method
   public void OnBeforeUpdate (Map<Id, Daily_Productivity__c> oldMap, Map<Id, Daily_Productivity__c> newMap) {  

  }          
}