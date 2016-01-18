public class ChatterAutoFollowController{


    public PageReference Nightly(){
        ScheduleAutoFollowScheduler.Start();
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Job Has Been Scheduled'));
        return null;
    }
    public PageReference RunNow(){
        ScheduleAutoFollow s = new ScheduleAutoFollow();
        //s.autoFollowRecord();
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Chatter Following Has Been Started'));
        return null;
    }
    
    @isTest
    public static void testRunNow(){
        ChatterAutoFollowController c = new ChatterAutoFollowController();
        c.RunNow();
        try {
            c.Nightly();
        } catch(Exception e) {
            //If job already scheduled
        }
    }

}