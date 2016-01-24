trigger ClosedOpportunityTrigger on Opportunity (after insert,after update) {

    list<Opportunity> updateopp = new list<Opportunity>();
    for(Opportunity opp:trigger.new){
        if(opp.StageName== 'Closed Won'){
            updateopp.add(opp);
        }
    
    }
    list<Task> tasklist = new list<Task>();
    for(Opportunity opp:updateopp){
        Task t = new task();
        t.whatid=opp.id;
        t.subject = 'Follow Up Test Task';
        tasklist.add(t);
    
    }
    
    insert tasklist;

}