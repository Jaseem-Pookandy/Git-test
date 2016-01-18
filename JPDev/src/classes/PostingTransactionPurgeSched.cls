global class PostingTransactionPurgeSched implements Schedulable {

  global void execute(SchedulableContext ctx) {
    
    
    PostingTransactionPurge ptp = new PostingTransactionPurge();
    ID thisBatchJob = database.executebatch(ptp, 40); 
  }
}