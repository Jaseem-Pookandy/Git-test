/*******************************************************************
Name  : ViewCorpHierarchyController_Test
Author: Byrnes
Date  : 2014.07.02
*************************************************************************/
@isTest
private class ViewCorpHierarchyController_Test{

    //first method with no querystring parameters, no data, nothing...
    static testMethod void testMethod1() {

        ApexPages.Standardcontroller sc;        
        PageReference pageRef = Page.ViewCorpHierarchy;
                
        Test.setCurrentPage(pageRef);
                    
        ViewCorpHierarchyController controller = new ViewCorpHierarchyController(sc);

        pageRef = controller.PrepPage();

        //without parameters, the pageref better be null.
        System.assertEquals(null, pageRef);
    }

    //second test here we will pass in a legit account id
    static testMethod void testMethod2() {

        Account a = TestUtils.createAccount();
        TestUtils.createBrands();

        List<Brand__c> brands = [SELECT Id from Brand__c WHERE isActive__c = true];     

        insert a;

        ApexPages.Standardcontroller sc;        
        PageReference pageRef = Page.ViewCorpHierarchy;
        pageRef.getParameters().put('accid', a.Id);
                
        Test.setCurrentPage(pageRef);
                    
        ViewCorpHierarchyController controller = new ViewCorpHierarchyController(sc);
        List<SelectOption> options = controller.getBrandOptions();

        pageRef = controller.PrepPage();

        if (brands.size() > 1) controller.currentBrand = brands[1].Id;
        pageRef = controller.redrawPage();

        List<ViewCorpHierarchyController.HierarchyWrapper> results = controller.getHierarchyWrapperList();

        //with parameters the result should still be null because no redirects are going to happen.
        System.assertEquals(null, pageRef);

        //now cancel out...

        pageRef = controller.ReturnToAccount();
        System.assertNotEquals(pageRef, null);
    }   
}