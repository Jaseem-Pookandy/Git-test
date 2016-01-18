/*******************************************************************
Name  : WebstoreProcessController_Test
Author: Godfrey Mwamsoyo
Date  : 04-24-2015
*************************************************************************/
@isTest(SeeAllData=false)
public with sharing class WebstoreProcessController_Test {

    static testMethod void testMethod1() {
        
        test.startTest();
        
        PageReference pageRef = Page.WebstoreProcess;
        
        Test.setCurrentPage(pageRef);
                
        ApexPages.Standardcontroller sc;
        
        WebstoreProcessController controller = new WebstoreProcessController(sc); 
        controller.theWebstoreId = '1234'; 
        String returnValue = controller.theWebstoreId;
        System.assertEquals(returnValue, '1234');
        
        test.stopTest();
    } 
}