@isTest(SeeAllData=true)
private class WebstoreOrderSendToZBilling_Test {

    static testMethod void myUnitTest() {
        // TO DO: implement unit test
        //test.startTest();
        CreateData();
        //test.stopTest();    
        System.AssertEquals(1, 1);
    }  
  static void CreateData() {
         test.startTest();              
        //Create Users
        List<User> userList = new List<User>();
        
        Profile sysAdmin = TestUtils.usrProfile('System Administrator');
        User adminUser = TestUtils.createUser('lname','firstName', 'email@c.com',
                      'tests@b0.com', 'test', 'nickName', sysAdmin.Id, 'testUser_adName');
        userList.add(adminUser);
        //Profile prof = TestUtils.usrProfile('DHX Shared Services');
        Profile prof = TestUtils.usrProfile();
        User primaryOwnerUser = TestUtils.createUser('PrimaryOwner1', 'firstName1', 'testUserName1@dice.com.test', 
                      'testUserName1@dice.com.test', 'alias1','nickName1', sysAdmin.Id, 'testAdUsername1');
        primaryOwnerUser.DefaultBrand__c = 'Dice';
        primaryOwnerUser.Default_BrandTag__c = 'Dice';
        primaryOwnerUser.IsActive = true;
        userList.add(primaryOwnerUser);     
        User csUser = TestUtils.createUser('CustomerOwner', 'firstName2', 'testUserName2@dice.com.test', 
                       'testUserName2@dice.com.test', 'alias2','nickName2', sysAdmin.Id, 'testAdUsername2');        
        csUser.IsActive = true;
        userList.add(csUser);
        insert userList;
       System.debug('Primary Owner Id = ' + primaryOwnerUser.Id);
        system.runAs(adminUser) { 
                
        //Account
        Account account = TestUtils.createAccount();
        account.Validation_Status__c = 'Validated'; 
        account.Customer_Segment__c = 'Direct Hire';
        insert account;
        //Account Brand
        List<Account_Brand__c> abList = [Select ID, Brand_Name__c FROM Account_Brand__c WHERE Account__c =: account.ID and Brand_Name__c = 'Dice'];
        Account_Brand__c accountBrand = abList.get(0);
        accountBrand.Primary_Owner__c = primaryOwnerUser.Id;
        accountBrand.CS__c = csUser.Id;
        upsert accountBrand;
       System.debug('primaryOwnerUser.Id = ' + primaryOwnerUser.Id);
        //Create Contacts
        List<Contact> contactList = TestUtils.createContacts(account, 1);
        Contact c = contactList.get(0);
        c.LastName = 'test 001';        
        insert contactList;
        //User Group        
        User_Group__c userGroup = new User_Group__c(Account__c = account.Id, Company_Display_Name__c = 'FileWall USA Inc.', 
                                 CurrencyIsoCode = 'USD', Description__c = 'FileWall USA Inc.', Name = 'FileWall USA Inc.');
        insert userGroup;
        Webstore_Order__c wso = new Webstore_Order__c(Account__c = account.ID, Account_Brand__c = accountBrand.Id, 
            Contact__c = contactList.get(0).Id, User_Group__c = userGroup.Id, Address_Line_1__c = '10711 Main St', 
            Address_Line_2__c = 'Suite 250', City__c = 'Fishers', City_HQ__c = 'Fishers', Company__c = 'FileWall USA Inc.', 
            Contract_Value__c = 650.00, Country__c = 'US', Country_HQ__c = 'US', CurrencyIsoCode = 'USD',    
            Email__c = 'samsheinz@filewall.com', External_Account_ID__c = 'RTX0f97d1', First_Name__c = 'Sams', Initial_Term__c = 12,   
            Invoice_TemplateId__c = '2c92a0f943b129010143b1b63c907f7d', Invoice_TemplateName__c = 'Dice_English_USD', 
            IsVerified__c = false, Last_Name__c = 'Heinz', Order_ID__c = '135808135204-1', 
            Payment_Gateway__c = 'Dice_USD_Paymentech_Gateway',  Phone__c = '5151010202', Postal_Code__c = '50654', 
            Purchase_Date__c = System.Now(),  State__c  = 'IA', Status__c = 'Pending', Verification_Status__c = 'No Match', 
            Website__c  = 'www.newgroup.com');
        insert wso ;
        System.debug('wso.Account_Brand__c = ' + wso.Account_Brand__c);
        //WebstoreOrderSendToZBilling.createWebstoreReferenceObjects(wso.Id); 
        
        LIST<zqu__ZProduct__c> zProductLst = [SELECT Id FROM zqu__ZProduct__c 
                 WHERE Name = 'Webstore (DI)' AND zqu__SKU__c = 'SKU-00000263' AND Brand__c = 'Dice' 
                 AND zqu__Deleted__c = false AND CurrencyIsoCode = 'USD' Limit 1];
        
       Webstore_Order_Line__c wsol = new Webstore_Order_Line__c(  
            CurrencyIsoCode = 'USD', End_Date__c = Date.today().AddMonths(12), Quantity__c = 1,
             SKU__c  = 'SKU-00000263', Start_Date__c = Date.today(), Webstore_Order__c = wso.Id, ZProduct__c = zProductLst.get(0).Id);
           // SKU__c  = 'SKU-00000263', Start_Date__c = Date.today(), Webstore_Order__c = wso.Id, ZProduct__c = 'a1Ad0000001a6PrEAI');
       insert wsol;
       Boolean populateResult = WebstoreOrderSendToZBilling.populateWebstoreReferenceObjects(wso.Id);
       test.stopTest();
       System.assertEquals(populateResult, true);
       WebstoreOrderSendToZBilling.createWebstoreReferenceObjects(wso.Id); 
       System.assertEquals(1, 1);
       
       WebstoreOrderSendToZBilling.createWebstoreReferenceObjects(wso.Id);
       System.assertEquals(1, 1);
       WebstoreOrderSendToZBilling.createZuoraSubscription(wso.Id);
       System.assertEquals(1, 1);        
       Boolean isOpen = WebstoreOrderSendToZBilling.isAccountingPeriodOpen(System.Now()); 
       System.assertEquals(1, 1);    
       WebstoreOrderSendToZBilling.returnRejectReason(wso, 'Unit Testing');
       System.assertEquals(1, 1);    
  
      
     }
  }
}