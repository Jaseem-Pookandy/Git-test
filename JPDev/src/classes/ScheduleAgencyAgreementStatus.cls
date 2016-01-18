//bergman
//2014.08.15

global class ScheduleAgencyAgreementStatus implements Schedulable {
  
  global void execute(SchedulableContext ctx) {
    
    batchAgencyAgreementStatus aas = new batchAgencyAgreementStatus();
    ID thisBatchJob = database.executebatch(aas); 
  }
}