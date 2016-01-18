/*******************************************************************
// (c) 2012 Appirio, Inc.
// 
// Trigger that *should be* invoked for all contexts that
// delegates control to OpportunityTriggerHandler. 
//
// Jan 23rd, 2012    Naresh Ojha (Appirio Off)    //jaseem test ant ///
********************************************************************/
trigger OpportunityTrigger on Opportunity (after insert, after update, before update, before insert) {
  //Handler class
  OpportunityTriggerHandler handler = new OpportunityTriggerHandler
                                           (Trigger.isExecuting, Trigger.size);
  
  if(Trigger.isInsert && Trigger.isBefore){     
    //Handler for Before insert
    handler.OnBeforeInsert(Trigger.new);     
  } else if(Trigger.isInsert && Trigger.isAfter ){     
    //Handler for After insert
    handler.OnAfterInsert(Trigger.new);     
  } else if(Trigger.isUpdate && Trigger.isAfter && handler_qlick.isOpportunityNotExecuted == true){   
    //Handler for after update trigger
    handler.OnAfterUpdate(Trigger.new, Trigger.oldMap);    
  } else if(Trigger.isUpdate && Trigger.isBefore){   
    //Handler for before update trigger
    handler.OnBeforeUpdate(Trigger.new, Trigger.oldMap);     
  }  
    
}