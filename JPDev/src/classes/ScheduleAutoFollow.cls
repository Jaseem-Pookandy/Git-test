global class ScheduleAutoFollow implements Schedulable{
   global void execute(SchedulableContext sc) {
        ScheduleAutoFollowAccTeamBatch a = new ScheduleAutoFollowAccTeamBatch(); 
        ID myBatchJobID1 = database.executebatch(a);
        
        ScheduleAutoFollowOpptyTeamBatch b = new ScheduleAutoFollowOpptyTeamBatch(); 
        ID myBatchJobID2 = database.executebatch(b); 
    }
   /* 
    public static testMethod void testscheduleMerge() {
        Test.startTest();
        ScheduleAutoFollow autoFollowBatch = new ScheduleAutoFollow();
        string sch = '0 0 0 * * ?';
        system.schedule('Auto Follow Schedule', sch, autoFollowBatch); 
        Test.stopTest();
    }
    

   global void execute(SchedulableContext SC) {
       autoFollowRecord(); //calling function which autoFollows Account and Opportunity record.
   }

   public void autoFollowRecord()
   {
        
        List<Id> atmIdList = new List<Id>(); //List for collection of Ids of AccountTeamMembers
        List<Id> otmIdList = new List<Id>(); //List for collection of Ids of OpportunityTeamMembers
         
        List<EntitySubscription> esList = new List<EntitySubscription>(); //List of entity subscription
        Map<String, EntitySubscription> existingSubs = new Map<String, EntitySubscription>(); //Map for entity subscription
        
        //Get the List of Opportunity Team Members and Account Team members added today or yesterday in the database.
        List<AccountTeamMember> atmList = [Select a.UserId, a.TeamMemberRole, a.IsDeleted, a.Id, a.CreatedDate, a.CreatedById, 
                                            a.AccountId, a.AccountAccessLevel 
                                            From AccountTeamMember a 
                                            where createdDate = TODAY OR createdDate = YESTERDAY];
                                            
        List<OpportunityTeamMember> otmList = [Select o.UserId, o.TeamMemberRole, o.OpportunityId, 
                                                o.OpportunityAccessLevel, o.Id, o.CreatedDate, o.CreatedById 
                                                From OpportunityTeamMember o
                                                where createdDate = TODAY OR createdDate = YESTERDAY];
                                                
        
        if(atmList.size()!=0)
        {
            for(AccountTeamMember a: atmList)
            {
                atmIdList.add(a.AccountId); // collect ids of Accounts
            }
        }
        
        if(otmList.size()!=0)
        {
            for(OpportunityTeamMember o: otmList)
            {
                otmIdList.add(o.OpportunityId); // collect ids of Opportunities
            }
        }
        
        if(atmIdList.size()!=0 || otmIdList.size()!=0)
        {
            //get existing entitysubscription for Accounts and Opportunities
            List<EntitySubscription> existingSubscriptionList = [select SubscriberId, ParentId from EntitySubscription where ParentId in :atmIdList OR ParentId in: otmIdList];
            
            //prepare a Map with key as string subscriber+parentId to check if new records already exist in database.
                for (EntitySubscription es : existingSubscriptionList) {
                    existingSubs.put((String)es.SubscriberId + es.ParentId, es);
                }
        }
        
            for(AccountTeamMember atm: atmList)
            {
                //check if the record already exist in Map. If not, then create new EntitySubscription record and add in List
                if(existingSubs.containsKey((string)atm.UserId+(string)atm.AccountId)==false)
                {
                    EntitySubscription newSub = new EntitySubscription(parentId = atm.AccountId, SubscriberId = atm.UserId);
                    esList.add(newSub);
                }
            }
            
            for(OpportunityTeamMember otm: otmList)
            {
                //check if the record already exist in Map. If not, then create new EntitySubscription record and add in List
                if(existingSubs.containsKey((string)otm.UserId+(string)otm.opportunityId)==false)
                {
                    EntitySubscription newSub = new EntitySubscription(parentId = otm.OpportunityId, SubscriberId = otm.UserId);
                    esList.add(newSub);
                }
            }
            
            //If new EntitySubscription records are present then Insert them.
            if(esList.size()!=0)
            {
                system.debug('esList.size()--->'+esList.size());
                try{
                    upsert esList;
                }
                catch(DMLException e){
                    system.debug('Exception----->'+e);
                }
            }
   }*/
}