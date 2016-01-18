@isTest(SeeAllData=true)
private class SandboxPostDeploymentController_Test{
    static testMethod void testMethod1(){
     
      SandboxPostDeploymentController controller = new SandboxPostDeploymentController();
    		
      //CreateData();
      
      PageReference pageRef = Page.SandboxPostDeployment;
      
      Test.setCurrentPage(pageRef);
      Test.startTest();     
      controller.runMaskContactEmail();
      controller.runMaskLeadEmail();
      controller.runMaskAltEmail();  
      Test.stopTest();  
    }

    public static testMethod void testBatch1()
    {
        Test.startTest();
        batchMaskContactEmail b = new batchMaskContactEmail();
        ID myBatchJobID = database.executebatch(b);
        Test.stopTest();
    }
    public static testMethod void testBatch2()
    {
        Test.startTest();
        batchMaskLeadEmail b = new batchMaskLeadEmail();
        ID myBatchJobID = database.executebatch(b);
        Test.stopTest();
    }
    public static testMethod void testBatch3()
    {
        Test.startTest();
        batchMaskAltEmail b = new batchMaskAltEmail();
        ID myBatchJobID = database.executebatch(b);
        Test.stopTest();
    }    
    
	public static void CreateData() {
        //Create Account
        Account account = TestUtils.createAccount();
        insert account;
        
        List<PostDeploymentSteps__c> pdsList = new List<PostDeploymentSteps__c>();
        
        PostDeploymentSteps__c pds1 = new PostDeploymentSteps__c();
        pds1.Name = 'Alternate Email Mask';
        pds1.Complete__c = false;
        
        PostDeploymentSteps__c pds2 = new PostDeploymentSteps__c();
        pds2.Name = 'Contact Email Mask';
        pds2.Complete__c = false;
        
        PostDeploymentSteps__c pds3 = new PostDeploymentSteps__c();
        pds3.Name = 'Lead Email Mask';
        pds3.Complete__c = false;        
	
        pdsList.add(pds1);
        pdsList.add(pds2);
        pdsList.add(pds3);
        
        insert pdsList;
        
	}    
}