/*******************************************************************
// (c) 2012 Appirio, Inc.
// 
// Trigger that *should be* invoked for all contexts that
// delegates control to CampaignTriggerHandler. 
//
// Mar 01st, 2013    Naresh Ojha (Appirio Off)    
********************************************************************/
trigger CampaignTrigger on Campaign (before insert, before update) {
  //Handler class
  CampaignTriggerHandler handler = new CampaignTriggerHandler
                                          (Trigger.isExecuting, Trigger.size);
  
  if(Trigger.isInsert && Trigger.isBefore){   
    //Handler for before insert trigger 
    handler.OnBeforeInsert(Trigger.new);    
  } else if(Trigger.isUpdate && Trigger.isBefore){   
    //Handler for before update trigger
    handler.OnBeforeUpdate(Trigger.oldMap, Trigger.new);    
  } 
}