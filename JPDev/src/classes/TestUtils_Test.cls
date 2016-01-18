/****
*Class            Utils_AccountContactCreation_Test
*Author           @GMwamsoyo
*Story            CCBOB-88
*Date             11/04/2015
*Description      Unit Test class for Utils_AccountContactCreation 
-----------------------------Modifications Updates ------------------------------

***/
@isTest(SeeAllData=false)
private class TestUtils_Test {
    static Id newAccountId;
    static testMethod void myUnitTest() {
      Profile usrProfile =  TestUtils.usrProfile();
      User testUser = TestUtils.createUser('Doe', 'John' , 'johnDoe@examples.com', 'John.Doe@dice.com',
                                      'Johnny', 'Invisible', usrProfile.Id,  'john.doe');
        List<User> userList = new List<User>();
        Profile prof = TestUtils.usrProfile();
        User primaryOwnerUser = TestUtils.createUser('PrimaryOwner1', 'firstName1', 'testUserName1@dice.com.test', 
                      'testUserName1@dice.com.test', 'alias1','nickName1', prof.Id, 'testAdUsername1');
        primaryOwnerUser.DefaultBrand__c = 'Dice';
        primaryOwnerUser.Default_BrandTag__c = 'Dice';
        primaryOwnerUser.IsActive = true;
        userList.add(primaryOwnerUser);     
        User csUser = TestUtils.createUser('CustomerOwner', 'firstName2', 'testUserName2@dice.com.test', 
                       'testUserName2@dice.com.test', 'alias2','nickName2', prof.Id, 'testAdUsername2');        
        csUser.IsActive = true;
        userList.add(csUser);
        insert userList;


        test.startTest();
        System.runAs(testUser) {
          //Create Brands
          List<Brand__c> brandLst =  TestUtils.createBrands();
           System.AssertEquals(brandLst.size(), 5);

           Map<String, Brand__c> brandMap = TestUtils.getBrands();
           System.AssertEquals(brandMap.size(), 5);

          //Create a single account
           Account account1 = TestUtils.createAccount();
           insert account1;

          //Create multiple accounts
           List<Account> acctLst = TestUtils.createAccounts(20);
           insert acctLst;
           System.AssertEquals(acctLst.size(), 10);

          //Create multiple contacts
            List<Contact> contacts = TestUtils.createContacts(acctLst[0], 10);
            insert contacts;
           System.AssertEquals(contacts.size(), 10);

           //Create an Opportunity
           Opportunity oppty =  TestUtils.createOpportunity('Oppty1', acctLst[0]);

           //Run CreateCustomSettingsRecords;
           TestUtils.CreateCustomSettingsRecords();

           //Run createDomaintoBrandMap;
           TestUtils.createDomaintoBrandMap();

           //Run createEmailHandlerRecords;
           TestUtils.createEmailHandlerRecords('Test Account1', 'migrationID');

           //Run createTasks;
           List<Task> taskLst = TestUtils.createTasks(contacts[0].Id, oppty.Id, 'Dice', 2);
           System.AssertEquals(taskLst.size(), 2);

           //Run createUserGroup;
           User_Group__c userGroup = TestUtils.createUserGroup(acctLst[0]);
           System.assert(userGroup.Id != null);

           //Run createProductUser;
           Account_Brand__c accountBrand = [SELECT Id, Name, Account__c FROM Account_Brand__c 
                                            WHERE Account__c = :acctLst[0].Id AND Brand_Name__c = 'Dice' LIMIT 1];
           //Assign Sales Rep and Customer Service Rep
           accountBrand.Primary_Owner__c = primaryOwnerUser.Id;
           accountBrand.CS__c = csUser.Id;
           upsert accountBrand;

           //Run createProductUser
           //Product_User__c productUser = TestUtils.createProductUser(userGroup, accountBrand, contacts[0]);
           //System.assert(productUser.Id != null);

           //Run CreateWebstoreOrder
           Webstore_Order__c wso = TestUtils.createWebstoreOrder(userGroup, accountBrand, contacts[0]);
           System.assert(wso.Id != null);

           //Run CreateZuoraQuoteProduct
           zqu__ZProduct__c zproduct =  TestUtils.createZuoraQuoteProduct('Dice', 'Webstore (DI)', 'false', 'Webstore',
                                                       'Webstore', 'Webstore', 'SKU-00000263', 'abcdefghijklmnopqrstuvwxyz1');
           System.assert(zproduct.Id != null);

           //Run createWebstoreOrderLine
           Webstore_Order_Line__c wsol = TestUtils.createWebstoreOrderLine(wso, zproduct, 1);
           System.assert(wsol.Id != null);

        }
        test.stopTest();   
    }  
    
  }