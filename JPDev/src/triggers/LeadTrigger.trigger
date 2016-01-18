/*******************************************************************
// (c) 2013 Appirio, Inc.
// 
// Trigger that *should be* invoked for all contexts that
// delegates control to LeadTriggerHandler. 
//
// Jan 09, 2013    Naresh Ojha (Appirio Off)    
********************************************************************/
trigger LeadTrigger on Lead (before insert, before update, after update, after insert) {
  //Handler class 
  LeadTriggerHandler handler = new LeadTriggerHandler 
                                           (Trigger.isExecuting, Trigger.size);
  
  if(Trigger.isInsert && Trigger.isBefore) {     
      //Handler for before insert 
      handler.OnBeforeInsert(Trigger.new);     
    } else if(Trigger.isUpdate && Trigger.isBefore) {   
      //Handler for before update trigger
      handler.OnBeforeUpdate(Trigger.oldMap, Trigger.newMap);    
    }else if(Trigger.isUpdate && Trigger.isAfter){
        //Handler for After update trigger
        handler.OnAfterUpdate(Trigger.oldMap, Trigger.newMap);
    }
    
/*------------Handling the after update logic------------------*/  
  if(Trigger.isUpdate && Trigger.isAfter){
      System.debug('in after lead');
      //String ownerId = UserInfo.getUserId();
      AccountBrandTriggerHandler.updateOnwerAssigned('Leads', trigger.newmap.keyset());
  }    
}