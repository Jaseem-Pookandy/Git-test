/*******************************************************************
Name  : SmartAccountSearchExtension_Test
Author: Appirio Offshore (Urminder Vohra)
Date  : July 19, 2011
Added   :   Dec 4th, 2012. by Naresh Kr Ojha (Appirio Offshore) 
*************************************************************************/
@isTest
private class SmartAccountSearchExtension_Test {

    static testMethod void myUnitTest() {
        ApexPages.StandardController sc;
        createData();
        SmartAccountSearchExtension controller = new SmartAccountSearchExtension(sc);
        controller.accountNameToSeaarch = '00TestAccount0';
       
        controller.requestedPage = '1';
        controller.performSearch();
        
        System.assert(55<=controller.searchCount);
        System.assertEquals(1,controller.showingFrom);
        System.assertEquals(20,controller.showingTo);
        System.assertEquals(3,controller.totalPage);
        System.assertEquals(true,controller.hasNext);
        System.assertEquals(false,controller.hasPrevious);
        
        controller.nextAccountPage();
        System.assertEquals(21,controller.showingFrom);
        System.assertEquals(40,controller.showingTo);
        System.assertEquals(3,controller.totalPage);
        System.assertEquals(true,controller.hasNext);
        System.assertEquals(true,controller.hasPrevious);
        
        controller.previousAccountPage();
        
        // Go to 3rd page(last page in this case)
        controller.nextAccountPage();
        controller.nextAccountPage();
        System.assertEquals(false,controller.hasNext);
        System.assertEquals(true,controller.hasPrevious);
                
        // come back to 2nd page
        controller.previousAccountPage();
        System.assertEquals(true,controller.hasNext);
        System.assertEquals(true,controller.hasPrevious);
        
        controller.requestedPage = '3';
        controller.requestedAccountPage();
        System.assertEquals(41,controller.showingFrom);
        System.assertEquals(55,controller.showingTo);
        System.assertEquals(3,controller.totalPage);
        System.assertEquals(false,controller.hasNext);
        System.assertEquals(true,controller.hasPrevious);
        
        controller.sortData();
        controller.cancel();
        
        controller.sortField = 'Type';
        controller.sortData();
        controller.cancel();
        
        controller.requestedPage = '5';
        controller.requestedAccountPage();
        
        controller.requestedPage = '1';
        controller.requestedAccountPage();
        System.assertEquals(true,controller.hasNext);
        System.assertEquals(false,controller.hasPrevious);
        
        // testing default constructor
        SmartAccountSearchExtension controller2 = new SmartAccountSearchExtension();
        
        // testing for no result found condition
        controller2.accountNameToSeaarch = '01TestAccount0';   
        
        controller2.requestedPage = '1';
        controller2.performSearch();
             
        System.assertEquals(0,controller2.searchCount);
        System.assertEquals(false,controller2.showGrid);
        
        // testing for results touching limit results        
        controller2.accountNameToSeaarch = '02TestAccount0';   
        
        controller2.requestedPage = '1';
        controller2.performSearch();
             
        System.assert(250<=controller2.searchCount);
        
        
        
    }
    static void CreateData() {
       list<Account> accList = new list<Account>();
       for(Integer i=0;i<55;i++) {
           Account acc = new Account();
           acc.Name = '00TestAccount0' + i;
           acc.BillingCity = 'Jaipur';
			     acc.BillingStreet = 'test street';
			     acc.BillingState = 'Rajasthan';
			     acc.BillingCountry = 'India';
			     acc.BillingPostalCode = '302022';
           accList.add(acc);
       }
       
       insert accList;
       
       list<Account> accList2 = new list<Account>();
       for(Integer i=0;i<260;i++) {
           Account acc2 = new Account();
           acc2.Name = '02TestAccount0' + i;
           acc2.BillingCity = 'Jaipur';
                 acc2.BillingStreet = 'test street';
                 acc2.BillingState = 'Rajasthan';
                 acc2.BillingCountry = 'India';
                 acc2.BillingPostalCode = '302022';
           accList2.add(acc2);
       }
       
       insert accList2;
    }
}