@isTest(SeeAllData=true)
private class ContactPageController_Test{
    static testMethod void testMethod1(){
     
    	ApexPages.Standardcontroller sc;
    	CreateData();
    
    	PageReference pageRef = Page.ContactPage;
    	pageRef.getParameters().put('retURL', '%2Fhome%2Fhome.jsp');
    
    	Test.setCurrentPage(pageRef);
          
    	ContactPageController controller = new ContactPageController(sc);    
    }

  //cancel
  static testMethod void testMethod2() {
    
    ApexPages.Standardcontroller sc;
    CreateData();
    
    PageReference pageRef = Page.ContactPage;
    pageRef.getParameters().put('retURL', '/home/home.jsp');
    
    Test.setCurrentPage(pageRef);
          
    ContactPageController controller = new ContactPageController(sc);
    
    pageRef = controller.Cancel();
    
    PageReference pageRefCancel = new PageReference('/home/home.jsp');
    
    system.assertEquals(pageRef.getURL(), pageRefCancel.getURL());
  }
  
    static testMethod void testMethod6(){

        CreateData();
        
        Id accountID = [SELECT Id FROM Account LIMIT 1].Id;
        
        ApexPages.Standardcontroller sc;

        
        PageReference pageRef = Page.ContactPage;
        pageRef.getParameters().put('retURL', '/home/home.jsp');
        pageRef.getParameters().put('accid', accountID);
        
        Test.setCurrentPage(pageRef);
              
        ContactPageController controller = new ContactPageController(sc);    
        
        controller.newCon.FirstName = 'FName';
        controller.newCon.LastName = 'LName';
        
        Id ContactID = controller.newCon.Id;
        
        controller.conTypes[0].CTRecord.Type__c = 'Unknown';
          
        controller.SaveItAll();    	    
 
        
    }
    
     static testMethod void testMethod7(){

        CreateData();
         
        Id contactID = [SELECT Id FROM Contact LIMIT 1].Id;
        
        ApexPages.Standardcontroller sc;
        
        PageReference pageRef = Page.ContactPage;
        pageRef.getParameters().put('retURL', '/home/home.jsp');
        pageRef.getParameters().put('Id', contactID);
        
        Test.setCurrentPage(pageRef);
              
        ContactPageController controller = new ContactPageController(sc);    
        
        controller.newCon.FirstName = 'FNameqzwxecrvtbynumi';
        controller.newCon.LastName = 'LNameqzwxecrvtbynumi';   
        
        controller.conTypes[0].CTRecord.Type__c = 'Unknown';
            
        controller.SaveItAll();    	    

        
    }
    
    static testMethod void testMethod8(){
        
        CreateData();
        
        Id accountID = [SELECT Id FROM Account LIMIT 1].Id;
        
        ApexPages.Standardcontroller sc;
        
        PageReference pageRef = Page.ContactPage;
        pageRef.getParameters().put('retURL', '/home/home.jsp');
        pageRef.getParameters().put('accid', accountID);
        
        Test.setCurrentPage(pageRef);
              
        ContactPageController controller = new ContactPageController(sc);    
        
        controller.newCon.FirstName = 'FName';
        controller.newCon.LastName = 'LName';
        
        Id ContactID = controller.newCon.Id;
        
        //controller.conTypes[0].CTRecord.Type__c = 'Unknown';
          
        controller.SaveItAll();    	    
 
        
    }
    
     static testMethod void testMethod9(){

        CreateData();
         
        Id contactID = [SELECT Id FROM Contact LIMIT 1].Id;
        Id accountID = [SELECT Id FROM Account LIMIT 1].Id;
        Id accountID2 = [SELECT Id FROM Account where Id != :accountID LIMIT 1].Id;
         
        ApexPages.Standardcontroller sc;
        
        PageReference pageRef = Page.ContactPage;
        pageRef.getParameters().put('retURL', '/home/home.jsp');
        pageRef.getParameters().put('Id', contactID);
        
        Test.setCurrentPage(pageRef);
              
        ContactPageController controller = new ContactPageController(sc);    
        
        controller.newCon.FirstName = 'FNameqzwxecrvtbynumi';
        controller.newCon.LastName = 'LNameqzwxecrvtbynumi';  
        controller.newCon.AccountId = accountID;
        controller.AccountChanged();
        controller.conTypes[0].CTRecord.Type__c = 'Unknown';
            
        controller.SaveItAll();  
         
    }
  static void CreateData() {
        //Create Account
        Account account = TestUtils.createAccount();
        insert account;
        
        //Create Contacts
        List<Contact> contactList = TestUtils.createContacts(account, 2);
        insert contactList;
          
  }
}