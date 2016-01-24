@isTest
private class TestVerifyDate{
    static testmethod void testmethod1(){
        
        Date date1 = date.newinstance(2015,9,29);
        Date date2 = date1.adddays(25);
        Date returneddate = VerifyDate.CheckDates(date1 ,date2 );
        
        system.assertequals(date2 ,returneddate);
        
        date2 = date1.adddays(40);
        returneddate = VerifyDate.CheckDates(date1 ,date2 );
        Date assertdate = Date.newInstance(date1.year(), date1.month(), Date.daysInMonth(date1.year(), date1.month()));
        
         system.assertequals(assertdate ,returneddate);
    }

}