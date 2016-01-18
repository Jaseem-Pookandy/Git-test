//Byrnes
//2015.05.26

global class SchedulePaymentLinksExpiration implements Schedulable {

    global void execute(SchedulableContext sc) {

    	SchedulePaymentLinksExpirationBatch ple = new SchedulePaymentLinksExpirationBatch();
    	ID thisBatchJob = Database.executeBatch(ple);

    }
}