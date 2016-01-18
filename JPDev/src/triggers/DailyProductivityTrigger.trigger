trigger DailyProductivityTrigger on Daily_Productivity__c (before insert, before update) {
  //Handler class
  DailyProductivityTriggerHandler handler = new DailyProductivityTriggerHandler
                                          (Trigger.isExecuting, Trigger.size);
                                          
                                            
  if(Trigger.isInsert && Trigger.isBefore){   
    //Handler for before insert trigger 
    handler.OnBeforeInsert(Trigger.new);    
  } else if(Trigger.isUpdate && Trigger.isBefore){   
    //Handler for before update trigger
    handler.OnBeforeUpdate(Trigger.oldMap, Trigger.newMap);    
  } 
}