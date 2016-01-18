@isTest
public class zCC_PrimaryControllerTest{
    //------dummy data variables-----------//
    public static Account accTest;
    public static Opportunity oppTest;
    public static zqu__Quote__c quoteTest;
    //------dummy data variables-----------//
    
    //Test case 1: test config are loaded properly and no error if this is a first onload
    @isTest
    private static void testOnloadFirstTime(){
        
        zCC_PrimaryControllerTest.prepareHPMSetting();
        PageReference pageRef = Page.zCC_Primary;
        System.Test.setCurrentPage(pageRef);
        zCC_PrimaryController hpmsc = new zCC_PrimaryController();
        //-------------additions------------------------//
        createDummyData();
        ApexPages.currentPage().getParameters().put( 'QID', quoteTest.Id );
        //-------------additions------------------------// 
        hpmsc.onload();
        //direct call to method as it is not called by any other method..
        hpmsc.getExtraParamString();
        System.assertEquals(false, ApexPages.hasMessages(), 'Not working for HPM sample page loading for first time, has errors during loading the page first time.');
       
    }
    
    @isTest
    private static void onloadWithInvalidSignature() {
      
      removeHPMSetting(); 
      prepareHPMSetting(); 
      
      PageReference pageRef = Page.zCC_CallBack; 
      System.Test.setCurrentPage( pageRef ); 
      
      pageRef.getParameters().put( 'errorCode', 'Invalid_Security' );
      
      zCC_PrimaryController hpmsc = new zCC_PrimaryController(); 
        //-------------additions------------------------//
        createDummyData();
        ApexPages.currentPage().getParameters().put( 'QID', quoteTest.Id );
        //-------------additions------------------------// 
      hpmsc.onload(); 
      
      System.assertEquals( true, hpmsc.hasConfigError );
      
      pageRef = Page.zCC_CallBack;
      System.Test.setCurrentPage( pageRef );
      
      pageRef.getParameters().put( 'errorCode', 'InvalidCallbackSecurity' );
      
      hpmsc = new zCC_PrimaryController(); 
        //-------------additions------------------------//
        //createDummyData();
        ApexPages.currentPage().getParameters().put( 'QID', quoteTest.Id );
        //-------------additions------------------------// 
      hpmsc.onload(); 
      
      System.assertEquals( true, hpmsc.hasConfigError );
      
      System.assert( hpmsc.iframeSrc.contains( 'field_maxConsecutivePaymentFailures=1') ); 
     
    }
    
    //Test case 2: error message are tracked as expected for all 256 cases
    @isTest
    private static void testOnloadWithFailureInCallBack(){  
        
        createDummyData(); 
        Test.startTest();
        zCC_PrimaryControllerTest.prepareHPMSetting();
        PageReference pageRef = Page.zCC_Primary;
        System.Test.setCurrentPage(pageRef);
        zCC_PrimaryController hpmsc = new zCC_PrimaryController();
        Integer i = 1;
        //for(Integer i = 1; i < 255; i++){           
            if( (i & 1) != 0){
                pageRef.getParameters().put('errorCode', 'This is error code');
            }
            if( ((i>>1) & 1) != 0){
                pageRef.getParameters().put('errorCode', 'This is error code');
                pageRef.getParameters().put('errorMessage', 'This is error Message');
            }
            if( (i>>2 & 1) != 0){
                pageRef.getParameters().put('errorField_creditCardType','This is error credit Card Type');
            }
            if( (i>>3 & 1) != 0){
                pageRef.getParameters().put('errorField_creditCardNumber', 'This is error credit Card Number');
            }
            if( (i>>4 & 1) != 0){
                pageRef.getParameters().put('errorField_creditCardExpirationMonth', 'This is error credit Card Expiration Month' );
            }
            if( (i>>5 & 1) != 0){
                pageRef.getParameters().put('errorField_creditCardExpirationYear', 'This is error credit Card Expiration Year');
            }
            if( (i>>6 & 1) != 0){
                pageRef.getParameters().put('errorField_cardSecurityCode', 'This is error Security Code');
            }
            if( (i>>7 & 1) != 0){
                pageRef.getParameters().put('errorField_creditCardHolderName', 'This is error credit card holder name');
            }
            //-------------additions------------------------//                         
            //createDummyData();      
            ApexPages.currentPage().getParameters().put( 'QID', quoteTest.Id );
            //-------------additions------------------------//             
            hpmsc.onload();
            System.assertEquals(true, ApexPages.hasMessages(), 'Not working for HPM sample page loading failure case ' + i + ', no expected error display to page.');
           
        //}
         Test.stopTest();
    }
    
    //Test case 3: no HPM custom setting set up
    @isTest
    private static void testWithoutHPMSettingConfigSetup(){
        
        //zCC_PrimaryControllerTest.removeHPMSetting();
        HPM_Setting__c hpmsetting = HPM_Setting__c.getInstance ('Zuora HPM Setting - USD');
        if(hpmsetting != null) {
            delete hpmsetting;
        }        
        PageReference pageRef = Page.zCC_Primary;        
        System.Test.setCurrentPage(pageRef);  
        //-------------additions------------------------//
        createDummyData();

        update quoteTest;
        ApexPages.currentPage().getParameters().put( 'QID', quoteTest.Id );
        //-------------additions------------------------//      
        zCC_PrimaryController hpmsc = new zCC_PrimaryController();
      
        hpmsc.onload(); 
        //System.assert( hpmsc.hasConfigError );
        system.assertEquals( ErrorCodeMapping.VALUES.get( 'Sfdc.ErrorLoadingFrame' ) + ErrorCodeMapping.VALUES.get( 'Sfdc.NoConfiguration' ), ApexPages.getMessages().get(0).getSummary() );
        
        zCC_PrimaryControllerTest.prepareHPMSetting();
        hpmsetting = HPM_Setting__c.getInstance ('Zuora HPM Setting - USD');
        hpmsetting.HPM_Page_Id__c = ''; 
        upsert hpmsetting;       
        hpmsc.onload(); 
        System.assert( hpmsc.hasConfigError );
        system.assertEquals( ErrorCodeMapping.VALUES.get( 'Sfdc.ErrorLoadingFrame' ) + ErrorCodeMapping.VALUES.get( 'Sfdc.InvalidConfiguration' ) + ' Page ID', ApexPages.getMessages().get(1).getSummary() );
        
        zCC_PrimaryControllerTest.prepareHPMSetting();
        hpmsetting = HPM_Setting__c.getInstance ('Zuora HPM Setting - USD');
        hpmsetting.HPM_Page_Id__c = ''; 
        hpmsetting.HPM_Tenant_Id__c = '';
        upsert hpmsetting;        
        hpmsc.onload(); 
        System.assert( hpmsc.hasConfigError );
        //system.assertEquals( ErrorCodeMapping.VALUES.get( 'Sfdc.ErrorLoadingFrame' ) + ErrorCodeMapping.VALUES.get( 'Sfdc.InvalidConfiguration' ) + ' Page ID, Tenant ID', ApexPages.getMessages().get(2).getSummary() );
        
        zCC_PrimaryControllerTest.prepareHPMSetting();
        hpmsetting = HPM_Setting__c.getInstance ('Zuora HPM Setting - USD');
        hpmsetting.HPM_Page_Id__c = ''; 
        hpmsetting.HPM_Tenant_Id__c = '';
        hpmsetting.HPM_Security_Token__c = '';
        upsert hpmsetting;        
        hpmsc.onload(); 
        System.assert( hpmsc.hasConfigError );
        //system.assertEquals( ErrorCodeMapping.VALUES.get( 'Sfdc.ErrorLoadingFrame' ) + ErrorCodeMapping.VALUES.get( 'Sfdc.InvalidConfiguration' ) + ' Page ID, Tenant ID, Security Token', ApexPages.getMessages().get(3).getSummary() );
        
        zCC_PrimaryControllerTest.prepareHPMSetting();
        hpmsetting = HPM_Setting__c.getInstance ('Zuora HPM Setting - USD');
        hpmsetting.HPM_Security_Token__c = '';
        hpmsetting.HPM_Page_Id__c = ''; 
        hpmsetting.HPM_Tenant_Id__c = '';
        hpmsetting.HPM_Security_Token__c = '';
        hpmsetting.HPM_App_Url__c = '';
        upsert hpmsetting;        
        hpmsc.onload(); 
        System.assert( hpmsc.hasConfigError );
        //system.assertEquals( ErrorCodeMapping.VALUES.get( 'Sfdc.ErrorLoadingFrame' ) + ErrorCodeMapping.VALUES.get( 'Sfdc.InvalidConfiguration' ) + ' Page ID, Tenant ID, Security Token, App URL', ApexPages.getMessages().get(4).getSummary() );
        
    } 
    
    
    @isTest
    public static void prepareHPMSetting(){
        HPM_Setting__c hpmsetting = HPM_Setting__c.getInstance ('Zuora HPM Setting - USD');
        if(hpmsetting == null)
            hpmsetting = new HPM_Setting__c();
        hpmsetting.Name = 'Zuora HPM Setting - USD';
        hpmsetting.HPM_Page_Id__c = 'page_id';
        hpmsetting.HPM_Tenant_Id__c = '100';
        hpmsetting.HPM_Security_Token__c = 'security_token'; 
        hpmsetting.HPM_App_Url__c = 'www.zuora.com/service/a/27.0';
        upsert hpmsetting;
    }
    
    @isTest
    public static void removeHPMSetting(){
        HPM_Setting__c hpmsetting = HPM_Setting__c.getInstance ('Zuora HPM Setting');
        if(hpmsetting != null) {
            delete hpmsetting;
        }
    }
    //--------------additions-----------------//    
    //method to create dummy data for testing..
    private static void createDummyData(){     
    	
    	//TestUtils.CreateCustomSettingsRecords();
    	
        accTest = TestUtils.createAccount();   
        insert accTest;
        List<Contact> cList = TestUtils.createContacts(accTest, 3);
        insert cList;
        oppTest = TestUtils.createOpportunity('test opportunity', accTest);
        insert oppTest;
        quoteTest = new zqu__Quote__c(zqu__Opportunity__c = oppTest.id, Name='test quote', zqu__Currency__c='USD', zqu__PaymentMethod__c = 'Credit Card', zqu__BillToContact__c = cList[0].Id, zqu__SoldToContact__c = cList[0].Id);
        quoteTest.Deferred_Bill_Date__c = Date.today().addDays(30);       //byrnes, 2014.05.13 for CC-2496
        insert quoteTest;
        //oppTest.SyncedQuote__c = quoteTest.id;
        update oppTest;      
    }  
}