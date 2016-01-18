/*******************************************************************
// (c) 2013 Appirio, Inc.
// 
// Class to process for autofollow for Opportunity team members created in two days.
//
// Created: Apr 12th, 2013    Naresh Ojha (Appirio Off)    
********************************************************************/
global class ScheduleAutoFollowOpptyTeamBatch implements Database.Batchable < sObject > {
  global String soqlQuery;
  global List<SObject> gllstScopeRecords;

  // Class Constructor - set query string
  global ScheduleAutoFollowOpptyTeamBatch () {
    soqlQuery = 'Select o.UserId, o.TeamMemberRole, o.OpportunityId, o.OpportunityAccessLevel, o.Id, o.CreatedDate, o.CreatedById'; 
    soqlQuery += ' From OpportunityTeamMember o where createdDate = TODAY OR createdDate = YESTERDAY';
  }
  
  // "Start" runs when the class in instanciated
  global Database.QueryLocator start(Database.BatchableContext bcMain) {
    return Database.getQueryLocator(soqlQuery);
  }
  
  // "Execute" is what is being run as a separate process per batch
  global void execute(Database.BatchableContext bcMain, List<SObject> lstBatchRecords) {
    List<EntitySubscription> esList = new List<EntitySubscription>();//List of entity subscription
    Map<String, EntitySubscription> existingSubs = new Map<String, EntitySubscription>(); //Map for entity subscription 
    Set<String> otmIdSet = new Set<String>();
    gllstScopeRecords = lstBatchRecords;
    List<OpportunityTeamMember> otmList = new List<OpportunityTeamMember>();
    OpportunityTeamMember teamMem;
    for(SObject o : gllstScopeRecords) {
      teamMem = (OpportunityTeamMember)o;
      otmIdSet.add(teamMem.OpportunityId);
      otmList.add(teamMem);
    }

    if(otmIdSet.size() > 0){
      //get existing entitysubscription for Accounts and Opportunities
      List<EntitySubscription> existingSubscriptionList = [select SubscriberId, ParentId from EntitySubscription where ParentId in : otmIdSet];
            
      //prepare a Map with key as string subscriber+parentId to check if new records already exist in database.
      for (EntitySubscription es : existingSubscriptionList) {
        existingSubs.put((String)es.SubscriberId + es.ParentId, es);
      }
    }
        
    for(OpportunityTeamMember otm: otmList) {
      //check if the record already exist in Map. If not, then create new EntitySubscription record and add in List
      if(!existingSubs.containsKey((string)otm.UserId+(string)otm.OpportunityId)) {
        EntitySubscription newSub = new EntitySubscription(parentId = otm.OpportunityId, SubscriberId = otm.UserId);
        esList.add(newSub);
      }
    }
            
    //If new EntitySubscription records are present then Insert them.
    if(esList.size()!=0) {
      try{
        upsert esList;
      }
      catch(DMLException e){
        system.debug('Exception----->'+e);
      }
    }
  }
  
  // Finish the Batch Job
  global void finish(Database.BatchableContext bcMain) {
    // Optional - you can send an email to an admin with results
    String strResultEmail = 'giggity@goo.com';
    AsyncApexJob aaJob = [SELECT NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :bcMain.getJobId()];
    Messaging.SingleEmailMessage semResult = new Messaging.SingleEmailMessage();
    semResult.setToAddresses(new String[] {Label.SFDC_ADMIN_EMAIL});
    if(aaJob.NumberOfErrors > 0) {
      semResult.setSubject('Error in Scheduled APEX');
      semResult.setPlainTextBody('Processed ' + aaJob.TotalJobItems + ' batches with ' + aaJob.NumberOfErrors + ' failures.');
    } else {
      semResult.setSubject('Scheduled APEX has been executed successfully');
      semResult.setPlainTextBody('Processed ' + aaJob.TotalJobItems + ' batches with ' + aaJob.NumberOfErrors + ' failures.');
    }
    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { semResult });
  } 
}