/*******************************************************************
// (c) 2013 Appirio, Inc.
// 
// Trigger that *should be* invoked for all contexts that
// delegates control to CampaignMemberTriggerHandler. 
//
// Jan 24th, 2013    Naresh Ojha (Appirio Off)    
********************************************************************/
trigger CampaignMemberTrigger on CampaignMember (before insert,
                                          before update, after delete, 
                                          after insert, after update) {
  
  //Handler class
  CampaignMemberTriggerHandler handler = new CampaignMemberTriggerHandler
                                           (Trigger.isExecuting, Trigger.size);
  
  if(Trigger.isInsert && Trigger.isBefore){   
    //Handler for before insert trigger 
    handler.OnBeforeInsert(Trigger.new);    
  } else if(Trigger.isInsert && Trigger.isAfter){     
    //Handler for After insert
    handler.OnAfterInsert(Trigger.new);      
  } else if(Trigger.isUpdate && Trigger.isBefore){   
    //Handler for before update trigger
    //handler.OnBeforeUpdate(Trigger.new, Trigger.oldMap);    
  } else if(Trigger.isUpdate && Trigger.isAfter){   
    //Handler for before update trigger
    //handler.OnAfterUpdate(Trigger.oldMap, Trigger.newMap);    
  } else if(Trigger.isDelete && Trigger.isAfter) {
    //Handler for before update trigger
    //handler.OnAfterDelete(Trigger.oldMap);    
  }

}