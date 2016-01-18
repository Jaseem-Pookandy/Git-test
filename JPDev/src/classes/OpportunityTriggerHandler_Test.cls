/******************************************************
Name        : OpportunityTriggerHandler_Test
Created By  : Naresh Ojha  [Appirio Offshore]
Created Date: Jan 25, 2013
Description : Test class for OpportunityTriggerHandler
******************************************************/
@isTest (SeeAllData = false)
private class OpportunityTriggerHandler_Test {
    //setup method that creates test data for all test methods
    @testsetup static void setupmethod(){
    	
    		Account account = new Account();
    		account.name = 'TEst Account';
    		account.Status__c = 'Active';
    		account.Phone = '9829198291';
    		account.BillingCity = 'Des Moines';
    		account.BillingStreet = '63';
    		account.BillingState = 'Iowa';
    		account.BillingCountry = 'United States';
    		account.BillingPostalCode = '302022';
    		
    		insert account;
    		
    		Contact c = new Contact();
			c.AccountId = account.Id;
			c.FirstName = 'John';
			c.LastName = 'D';
			c.MailingCity = '33';
			c.MailingState = 'London';
			c.MailingPostalCode = '110011';
			c.MailingCountry = 'United Kingdom';			
			c.Language__c = 'English';
			c.Email = 'no@thanks.dice.com';
			insert c;
			
			 Opportunity opp = new Opportunity();
      		 opp.Name = 'Test';
      		 opp.CloseDate = Date.today().addDays(5);
     		 opp.AccountId = account.Id;
     		 opp.contact__c = c.id;
     		 opp.StageName = 'Proposal';
     		 opp.BrandTag__c = 'eFC-EMEA';
     		 opp.Primary_Brand__c = 'eFinancialCarriers';
     		 
     		 insert opp;
			
			zqu__Quote__c QuoteObj = new zqu__Quote__c();
		    QuoteObj.IsSyncing__c = true;
		    QuoteObj.zqu__Opportunity__c = opp.Id;
		    QuoteObj.zqu__SoldToContact__c = c.Id;
		    QuoteObj.BrandTag__c = 'eFC-EMEA';
		    QuoteObj.Deferred_Bill_Date__c = Date.today()-1;
		    
		    insert QuoteObj;
		    
		    pw_ccpro__CountryObject__c Country = new pw_ccpro__CountryObject__c();
		    Country.name  = 'United Kingdom';
		    Country.Require_GST_VAT_Tax__c = true;
		    Country.pw_ccpro__IsoCode_2__c = 'UK';
		    Country.pw_ccpro__IsoCode_3__c = 'UK1';
		    
		    insert Country;
		    
		    BrandTag_VAT__c BG_CS = new BrandTag_VAT__c();
		    BG_CS.name = 'eFC-EMEA';
		    
		    insert BG_CS;
    }
    //Contact Roles should be created.
    static testMethod void scenario1_test() {
        
            //Create Account
            Account account = TestUtils.createAccount();
            insert account;
            
            //Create Contacts
            List<Contact> contactList = TestUtils.createContacts(account, 2);
            insert contactList;
            
            //Create Opportunities
            List<Opportunity> oppList = new List<Opportunity>();
            Opportunity opp;
            for(integer i=0; i<2; i++) {
                opp = TestUtils.createOpportunity('Opp_'+i, account);
                opp.Contact__c = contactList.get(i).id;
                oppList.add(opp);           
            }
            insert oppList;
        
            //Verify that Contact Roles should be created.
            List<OpportunityContactRole> ocrList = [SELECT ID, ContactID, IsPrimary, Role FROM OpportunityContactRole WHERE OpportunityID IN: oppList];

            Test.startTest();

            if (ocrList.size() > 0 && contactList.size() > 0) {
              System.assertEquals(contactList.get(0).Id, ocrList.get(0).ContactID);
              System.assertEquals(true, ocrList.get(0).IsPrimary);             
              System.assertEquals(Constants.DECISION_MAKER, ocrList.get(0).Role);
              
              System.assertEquals(contactList.get(1).Id, ocrList.get(1).ContactID);
              System.assertEquals(true, ocrList.get(1).IsPrimary);             
              System.assertEquals(Constants.DECISION_MAKER, ocrList.get(1).Role);
            }
            handler_qlick.isOpportunityNotExecuted = true;// reset the recursive variable to true to get the update logic run
            //Update Contact of first opportunity
            oppList.get(0).Contact__c = contactList.get(1).id;
            update oppList.get(0);
             
            //Verify that one more Opportunity Contact Role is created for this 
            //opportunity
            ocrList = [SELECT ID, ContactID, IsPrimary, Role FROM OpportunityContactRole 
                                    WHERE OpportunityID =: oppList.get(0).Id AND ContactID =: contactList.get(1).id ];

            System.assertEquals(1, ocrList.size());             
            System.assertEquals(contactList.get(1).id, ocrList.get(0).ContactID);
            System.assertEquals(true, ocrList.get(0).IsPrimary);
            System.assertEquals(Constants.DECISION_MAKER, ocrList.get(0).Role);                     
            
            handler_qlick.isOpportunityNotExecuted = true;// reset the recursive variable to true to get the update logic run
            //Again update the Contact of this opportunity to first contact.
            oppList.get(0).Contact__c = contactList.get(0).id;
            update oppList.get(0); 
            
            //Verify that no more Opportunity Contact Role is created for this 
            //opportunity and first OpportunityContactRole is updated.
            ocrList = [SELECT ID, ContactID, IsPrimary, Role FROM OpportunityContactRole 
                                    WHERE OpportunityID =: oppList.get(0).Id AND ContactID =: contactList.get(0).id ];
                                    
            System.assertEquals(1, ocrList.size());
            System.assertEquals(contactList.get(0).id, ocrList.get(0).ContactID);
            System.assertEquals(true, ocrList.get(0).IsPrimary);
            System.assertEquals(Constants.DECISION_MAKER, ocrList.get(0).Role); 

            Test.stopTest();
     }
     
    static testMethod void OppFeedItemTest() {
     
      Opportunity opp = [select id from Opportunity limit 1];
      
      opp.StageName = 'Closed Won';
      update opp;
      
      zqu__Quote__c QuoteObj = [select id,Require_VAT__c from zqu__Quote__c where zqu__Opportunity__c =:opp.id];
      
      system.assertequals('YES',QuoteObj.Require_VAT__c);
  } 
    
    static testMethod void myUnitTest() {
      
      List<User> userList = new List<User>();      
      Profile sysAdmin = TestUtils.usrProfile('System Administrator');
      User adminUser = TestUtils.createUser('lname','firstName', 'email@c.com',
                        'tests@b0.com', 'test', 'nickName', sysAdmin.Id,'testUser_adName');
      userList.add(adminUser);
      
      User adminUser2 = TestUtils.createUser('lname2','firstName2', 'email2@c.com',
                        'tests2@b0.com', 'test2', 'nickName2', sysAdmin.Id,'testUser_adName2');
      userList.add(adminUser2);

      insert userList;
    
      //Create Account
      Account account = TestUtils.createAccount();
      insert account;

      List<Account_Brand__c> abList = createABList(account);

      Account_Team_Member__c a_t_mObj = new Account_Team_Member__c();
      a_t_mObj.Account_Brand__c = abList.get(0).ID;
      a_t_mObj.User__c = adminUser.Id;
      a_t_mObj.Role__c = 'Sales Rep';
      a_t_mObj.Account__c = account.Id;
      insert a_t_mObj;

        //Create Contacts
        List<Contact> contactList = TestUtils.createContacts(account, 2);
        insert contactList;

        //Campaign
        Campaign testCampaign = new Campaign(Name = 'Test Campaign 001');
        testCampaign.IsActive = true;
        testCampaign.isCall_List__c = true;
        testCampaign.Brand__c = 'Dice';
        insert testCampaign;
                
        //Create Opportunities
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity opp;
        //Campaign Members
        List<CampaignMember> cmList = new List<CampaignMember>();
        CampaignMember cm;

        test.startTest();
                
        for(integer i=0; i<2; i++) {
          opp = TestUtils.createOpportunity('Opp_'+i, account);
          opp.Contact__c = contactList.get(i).id;
          opp.Provisioning_Status__c = Constants.STATUS_COMPLETE;
          opp.Provisioning_Owner__c = UserInfo.getUserId();
          opp.isTeam_Added__c = false;
          opp.Brands__c = Constants.BRAND_DICE+';'+Constants.BRAND_CJ;
          opp.hasConfirmed_Owner_Assignments__c = true;
          oppList.add(opp);       
        
        cm = new CampaignMember();
        cm.CampaignId = testCampaign.ID;
        cm.ContactId = contactList.get(i).id;
        cm.Status = 'Sent';
        cmList.add(cm);
        }
      insert oppList;

      insert cmList;
            
      List<OpportunityTeamMember> optyTeamList = new List<OpportunityTeamMember>();
      OpportunityTeamMember oppTeam;
      Integer i = 0;
        for(Account_Brand__c ab : abList) {
            if(ab.Brand_Name__c == Constants.BRAND_DICE) {
            ab.Primary_Owner__c = adminUser.Id;
                ab.CS__c = adminUser2.Id;
            }
            if (ab.Brand_Name__c == Constants.BRAND_CJ) {
          ab.Primary_Owner__c = adminUser2.Id;
          ab.CS__c = adminUser.Id;
            }
        }
        update abList;
        
        //Set primary campaign.
        //System.assertNotEquals([SELECT CampaignId FROM Opportunity WHERE ID =: oppList.get(0).ID].CampaignId, null); // Removed 9/17/2013 JH
        Set<Id> oppIDs = new Set<Id>();
        handler_qlick.isOpportunityNotExecuted = true;// reset the recursive variable to true to get the update logic run
        for(Opportunity opty : oppList) {
            opty.StageName = Constants.OPPTY_CLOSED_WON;
            opty.CampaignId = null;
            opty.OwnerId = userList[1].Id;
            oppIDs.add(opty.Id);
        }
        update oppList;
        
        //Opportunity team created.
        System.assert([SELECT ID FROM OpportunityTeamMember WHERE OpportunityID =: oppList.get(0).ID].size()>0);
		handler_qlick.isOpportunityNotExecuted = true;// reset the recursive variable to true to get the update logic run
        //update the renewal owner for scenario 2 of 2125.
        oppList = [SELECT ZuoraSubscription__c, Id, SyncedQuote__c FROM Opportunity WHERE SyncedQuote__c != null and ZuoraSubscription__c != null and SyncedQuote__r.zqu__Status__c = 'Sent to Z-Billing' limit 5];
        for (Opportunity opty : oppList) {
          opty.Renewal_Owner_Assigned__c = userList[0].Id;
        }
        update oppList;

        //Boolean b = OpportunityTriggerHandler.RenewalOppShouldBeCreated(null, null, null);
        //OpportunityTriggerHandler.CreateRenewalOpps(oppIDs);

        Set<String> blah = new Set<String>();
        for (Integer p=0; p<3; p++) {
          blah.add('fakeSubID_oldValue_newValue');
        }
        OpportunityTriggerHandler.SyncLineItemsToZuora(blah);

        test.stopTest();
  } 

    static testMethod void OppRenewalTest() {    

      List<User> userList = new List<User>();      
      Profile sysAdmin = TestUtils.usrProfile('System Administrator');
      User adminUser = TestUtils.createUser('lname','firstName', 'email@c.com',
                        'tests@b0.com', 'test', 'nickName', sysAdmin.Id,'testUser_adName');
      userList.add(adminUser);
      
      User adminUser2 = TestUtils.createUser('lname2','firstName2', 'email2@c.com',
                        'tests2@b0.com', 'test2', 'nickName2', sysAdmin.Id,'testUser_adName2');
      userList.add(adminUser2);

      insert userList;
    
      //Create Account
      Account account = TestUtils.createAccount();
      insert account;

      List<Account_Brand__c> abList = createABList(account);

      Account_Team_Member__c a_t_mObj = new Account_Team_Member__c();
      a_t_mObj.Account_Brand__c = abList.get(0).ID;
      a_t_mObj.User__c = adminUser.Id;
      a_t_mObj.Role__c = 'Sales Rep';
      a_t_mObj.Account__c = account.Id;
      insert a_t_mObj;

        //Create Contacts
        List<Contact> contactList = TestUtils.createContacts(account, 2);
        insert contactList;

               
        //Create Opportunities
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity opp;

        Set<Id> oppsToCreateRenewals = new Set<Id>();

        test.startTest();
                
        for(integer i=0; i<2; i++) {
          opp = TestUtils.createOpportunity('Opp_'+i, account);
          opp.Contact__c = contactList.get(i).id;
          opp.Provisioning_Status__c = Constants.STATUS_COMPLETE;
          opp.Provisioning_Owner__c = UserInfo.getUserId();
          opp.isTeam_Added__c = false;
          opp.Brands__c = Constants.BRAND_DICE+';'+Constants.BRAND_CJ;
          opp.hasConfirmed_Owner_Assignments__c = true;
          oppList.add(opp);       
        }

        insert oppList;

        //List<OpportunityLineItem> oli = new List<OpportunityLineItem>();
        Opportunity oTasks = new Opportunity();

        for (Opportunity o : oppList) {
          oppsToCreateRenewals.add(o.Id);

          oTasks = o;
        }

        oTasks.StageName = Constants.OPPTY_CLOSED_WON;
        oTasks.Provisioning_Status__c = 'Complete';        
        update oTasks;
            
        List<OpportunityTeamMember> optyTeamList = new List<OpportunityTeamMember>();
        OpportunityTeamMember oppTeam;
        Integer i = 0;
        
        for(Account_Brand__c ab : abList) {
            if(ab.Brand_Name__c == Constants.BRAND_DICE) {
            ab.Primary_Owner__c = adminUser.Id;
                ab.CS__c = adminUser2.Id;
            }
            if (ab.Brand_Name__c == Constants.BRAND_CJ) {
          ab.Primary_Owner__c = adminUser2.Id;
          ab.CS__c = adminUser.Id;
            }
        }
        update abList;      

        //Create and insert test quote
        //zqu__Quote__c testQuote = zqu.ZQTestDataSetup.prepareNewSubscriptionQuote(false);
        zqu__Quote__c testQuote = new zqu__Quote__c();
        testQuote.zqu__ElectronicPaymentMethodId__c = 'pmid1234';
        //testQuote.zqu__ZuoraAccountId__c = 'zaid1234';
        testQuote.zqu__SoldToContact__c = contactList[0].Id;
        testQuote.zqu__BillToContact__c = contactList[0].Id;
        testQuote.zqu__SubscriptionType__c = 'New Subscription';
        testQuote.zqu__ZuoraAccountID__c = EncodingUtil.convertToHex(crypto.generateAesKey(256)).substring(1,33);
        testQuote.AR_Special_Notes__c = 'test notes';
        testQuote.BrandTag__c = 'ClearanceJobs';
        testQuote.zqu__ZuoraSubscriptionID__c = EncodingUtil.convertToHex(crypto.generateAesKey(256)).substring(1,33);
        testQuote.Global_Deal__c = false;
        testQuote.Deferred_Bill_Date__c = date.newinstance(2014, 12, 1);
        testQuote.zqu__StartDate__c = date.newinstance(2014, 1, 13);
        testQuote.AR_Special_Handling__c = false;
        testQuote.zqu__Opportunity__c = oppList[0].Id;

        insert testQuote;

        OpportunityTriggerHandler.CreateRenewalOpps(oppsToCreateRenewals);

        test.stopTest();
  } 

static testMethod void DocusignReturned_Test() {    

      List<User> userList = new List<User>();      
      Profile sysAdmin = TestUtils.usrProfile('System Administrator');
      User adminUser = TestUtils.createUser('lname','firstName', 'email@c.com',
                        'tests@b0.com', 'test', 'nickName', sysAdmin.Id,'testUser_adName');
      userList.add(adminUser);
      
      User adminUser2 = TestUtils.createUser('lname2','firstName2', 'email2@c.com',
                        'tests2@b0.com', 'test2', 'nickName2', sysAdmin.Id,'testUser_adName2');
      userList.add(adminUser2);

      insert userList;
    
      //Create Account
      Account account = TestUtils.createAccount();
      insert account;

      List<Account_Brand__c> abList = createABList(account);

      Account_Team_Member__c a_t_mObj = new Account_Team_Member__c();
      a_t_mObj.Account_Brand__c = abList.get(0).ID;
      a_t_mObj.User__c = adminUser.Id;
      a_t_mObj.Role__c = 'Sales Rep';
      a_t_mObj.Account__c = account.Id;
      insert a_t_mObj;

        //Create Contacts
        List<Contact> contactList = TestUtils.createContacts(account, 2);
        insert contactList;

               
        //Create Opportunities
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity opp;

        Set<Id> oppsToCreateRenewals = new Set<Id>();

        test.startTest();
                
        for(integer i=0; i<2; i++) {
          opp = TestUtils.createOpportunity('Opp_'+i, account);
          opp.Contact__c = contactList.get(i).id;
          opp.Provisioning_Status__c = Constants.STATUS_COMPLETE;
          opp.Provisioning_Owner__c = UserInfo.getUserId();
          opp.isTeam_Added__c = false;
          opp.Brands__c = Constants.BRAND_DICE+';'+Constants.BRAND_CJ;
          opp.hasConfirmed_Owner_Assignments__c = true;
          oppList.add(opp);       
        }

        insert oppList;

        //List<OpportunityLineItem> oli = new List<OpportunityLineItem>();
        Opportunity oTasks = new Opportunity();

        for (Opportunity o : oppList) {
          oppsToCreateRenewals.add(o.Id);

          oTasks = o;
        }

        oTasks.StageName = Constants.OPPTY_CLOSED_WON;
        oTasks.Provisioning_Status__c = 'Complete';
        oTasks.Credit_Card_Flag__c = true;
        oTasks.Approval_Source__c = 'Electronic';
        update oTasks;
            
        List<OpportunityTeamMember> optyTeamList = new List<OpportunityTeamMember>();
        OpportunityTeamMember oppTeam;
        Integer i = 0;
        
        for(Account_Brand__c ab : abList) {
            if(ab.Brand_Name__c == Constants.BRAND_DICE) {
            ab.Primary_Owner__c = adminUser.Id;
                ab.CS__c = adminUser2.Id;
            }
            if (ab.Brand_Name__c == Constants.BRAND_CJ) {
          ab.Primary_Owner__c = adminUser2.Id;
          ab.CS__c = adminUser.Id;
            }
        }
        update abList;      

        //Create and insert test quote
        //zqu__Quote__c testQuote = zqu.ZQTestDataSetup.prepareNewSubscriptionQuote(false);
        zqu__Quote__c testQuote = new zqu__Quote__c();
        testQuote.zqu__ElectronicPaymentMethodId__c = 'pmid1234';
        //testQuote.zqu__ZuoraAccountId__c = 'zaid1234';
        testQuote.zqu__SoldToContact__c = contactList[0].Id;
        testQuote.zqu__BillToContact__c = contactList[0].Id;
        testQuote.zqu__SubscriptionType__c = 'New Subscription';
        testQuote.zqu__ZuoraAccountID__c = EncodingUtil.convertToHex(crypto.generateAesKey(256)).substring(1,33);
        testQuote.AR_Special_Notes__c = 'test notes';
        testQuote.BrandTag__c = 'ClearanceJobs';
        testQuote.zqu__ZuoraSubscriptionID__c = EncodingUtil.convertToHex(crypto.generateAesKey(256)).substring(1,33);
        testQuote.Global_Deal__c = false;
        testQuote.Deferred_Bill_Date__c = date.newinstance(2014, 12, 1);
        testQuote.zqu__StartDate__c = date.newinstance(2014, 1, 13);
        testQuote.AR_Special_Handling__c = false;
        testQuote.zqu__Opportunity__c = oppList[0].Id;

        insert testQuote;

        

        test.stopTest();
  }   

  private static List<Account_Brand__c> createABList(Account testAccount) {

    List<Account_Brand__c> accBrandList = new List<Account_Brand__c>();
    testAccount = [SELECT Migration_Id__c From Account Where ID = :testAccount.Id];
    Profile sysAdmin = TestUtils.usrProfile('System Administrator');
    List<User> userList = [SELECT Id FROM User LIMIT 100];
   
    Account_Brand__c abObj = new Account_Brand__c();
    abObj.Brand_Picklist__c = 'Dice';
    abObj.Account__c = testAccount.Id;
    abObj.Primary_Owner__c = userList.get(0).Id;
    abObj.CS__c = userList.get(1).Id;
    abObj.Status__c = 'Active';
    accBrandList.add(abObj);
    insert accBrandList;

    return accBrandList; 
  }   
}