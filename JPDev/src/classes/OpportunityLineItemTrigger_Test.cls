/***************************************************************
Name        : OpportunityLineItemTrigger_Test
Created By  : Naresh Kr. Ojha  [Appirio Offshore]
Created Date: Jan 23, 2013
Description : Test class for OpportunityLineItemTriggerHandler
***************************************************************/
@isTest(SeeAllData=true)
private class OpportunityLineItemTrigger_Test {

    static List<PricebookEntry> pricebookEntryList ;
    static Map<String, Brand__c> brandMap;
    
    static testMethod void myUnitTest() {
    brandMap = CommonUtil.getBrandMap();
    List<Opportunity> opps = createOpps();
    List<Product2> products = createProducts();
    
    products = [Select id, name, External_Id__c from Product2 where id in : products];        
       
    pricebookEntryList = getPriceBookEntryList(getStandardPriceBookId(), products);
    pricebookEntryList = [Select id, Product2.name, Product2.External_Id__c, 
                          product2id, Name, Product2.Brand__c  from 
                          PricebookEntry where id in : pricebookEntryList];
    
    //**************** For Insert ***************
    
    List<OpportunityLineItem> oppLineItems = createOppProducts(opps);
    oppLineItems = [SELECT Brand__c, Country__c FROM OpportunityLineItem WHERE Id in :oppLineItems];
            
    //Verify that OpportunityLineItem Brand__c becomes 
    //same as PriceBookEntry's Product's Brand__c
    System.assertEquals(pricebookEntryList.get(0).Product2.Brand__c, 
                        oppLineItems.get(0).Brand__c);
    System.assertEquals(pricebookEntryList.get(1).Product2.Brand__c, 
                        oppLineItems.get(1).Brand__c);
    
    Map<String, Brand__c> BrandID_Brandmap = CommonUtil.getID_BrandMap();
    
    String brand0 = BrandID_Brandmap.get(oppLineItems.get(0).Brand__c).Name;
    String brand1 = BrandID_Brandmap.get(oppLineItems.get(1).Brand__c).Name;
    String brand2 = BrandID_Brandmap.get(oppLineItems.get(2).Brand__c).Name;
    
    String CountryJoinString = getCountryString(oppLineItems, 3);
    
    //Query Brands__c and Countries__c from parent opportunity
    List<Opportunity> opp = [SELECT Brands__c, Countries__c FROM Opportunity
                                                            WHERE id =: opps.get(0).Id];
    
    //Verify that parent Opportunity's Brands__c contains opportunityLineItems
    //Brands.
    System.assertEquals(true, opp.get(0).Brands__c.contains(brand0));
    System.assertEquals(true, opp.get(0).Brands__c.contains(brand1));
    System.assertEquals(true, opp.get(0).Brands__c.contains(brand2));
    
    //Verify that parent Opportunity's Countries__c is equals to CountryJoinString.
     Set<String> CountrySet = new Set<String>();
     String country = CountryJoinString.split(';', 5).get(0);
     for(String c : opp.get(0).Countries__c.split(';')) {
      CountrySet.add(c);
     }
     System.assert(CountrySet.contains(country));
     country = CountryJoinString.split(';', 5).get(1);
     System.assert(CountrySet.contains(country));
     country = CountryJoinString.split(';', 5).get(2);
     System.assert(CountrySet.contains(country));
        
    //**************** For Update ****************                    
                        
    oppLineItems.get(2).Brand__c = null;
    oppLineItems.get(3).Brand__c = null;    
    update oppLineItems;
    
    //Verify that OpportunityLineItem Brand__c does not become null.
    oppLineItems = [SELECT Id, Brand__c, Country__c FROM OpportunityLineItem 
                                    WHERE Id in :oppLineItems];
    
    System.assertEquals(pricebookEntryList.get(2).Product2.Brand__c, 
                        oppLineItems.get(2).Brand__c);
    System.assertEquals(pricebookEntryList.get(3).Product2.Brand__c, 
                        oppLineItems.get(3).Brand__c);
    
                        
    //**************** For Delete ******************
    
    //Delete an OpportunityLineItem from those that have same OpportunityId
    delete oppLineItems.get(2);
    opp = [SELECT Brands__c, Countries__c FROM Opportunity WHERE id =: opps.get(0).Id];
    
    //Verify that parent Opportunity's Brands__c does not contain deleted 
    //opportunityLineItem's Brand.
    System.assertEquals(true, opp.get(0).Brands__c.contains(brand0));
    System.assertEquals(true, opp.get(0).Brands__c.contains(brand1));
    System.assertEquals(false, opp.get(0).Brands__c.contains(brand2));    
    
    CountryJoinString = getCountryString(oppLineItems, 2);
    
    //Verify that parent Opportunity's Countries__c now does not
    //contain deleted OpportunityLineItem's country.
     CountrySet = new Set<String>();
     for(String c : opp.get(0).Countries__c.split(';')) {
      CountrySet.add(c);
     }
     System.assertEquals(CountrySet.size(), 2);
     country = CountryJoinString.split(';', 5).get(0);
     System.assert(CountrySet.contains(country));
     country = CountryJoinString.split(';', 5).get(1);
     System.assert(CountrySet.contains(country));

    //System.assertEquals(CountryJoinString, opp.get(0).Countries__c);
    }
     
    /*********************************************
    // Create Opportunities 
    *********************************************/
    public static List<Opportunity> createOpps(){
    List<Opportunity> opps = new List<Opportunity>();
    Account acc = TestUtils.createAccount();
    
    Opportunity opp = null;
    for(Integer index = 0; index < 4; index++){ 
        opp = TestUtils.createOpportunity('Test Opp' + index, acc);
        opps.add(opp);
    }
    insert opps;
    return opps;
    }
    
    /*********************************************
    // Create  Products 
    *********************************************/
    public static List<Product2> createProducts(){
    List<Product2> products = new List<Product2>();
    Product2 product = null;
    for(Integer index = 0; index < 4; index++){
        product = new Product2();
        product.name = 'TestProduct' + index;
        product.Family = 'TestFamily' + index;
        product.External_Id__c = 'TP' + index;
        product.ProductCode = 'TestProduct' + index;
        product.isMigrated__c = true;
        product.Description = 'Test Product' + index;
        product.IsActive = true;
        product.Brand__c = brandMap.values().get(index).id;
        products.add(product);
    }
    insert products;
    return products;
    }
    
    /**********************************************************
    // Returns standard price book id
    *********************************************************/
    private static Id getStandardPriceBookId(){
    // Fetch standard pricebookid.
    Id priceBookId;
    for(priceBook2 priceBook : [select ID from Pricebook2 
                                where IsStandard = TRUE]){
        priceBookId = priceBook.id;
    }
    return priceBookId;
    }
    
    /**********************************************************
    // Creates price book entry data 
    *********************************************************/
    public static List<PricebookEntry> getPriceBookEntryList(String pricebookId, 
    List<Product2> products) {
        
    List<PricebookEntry> pbEntryList = new List<PricebookEntry>();
    PricebookEntry entry = null;      
    for(Integer index = 0; index < 4; index++){
        entry = new PricebookEntry();
        entry.Product2Id = products.get(index).id;
        entry.Pricebook2Id = pricebookId;
        entry.UnitPrice = 100 * (index + 1);
        entry.IsActive = true;
        pbEntryList.add(entry);
    }
    insert pbEntryList;
    return pbEntryList;
    }
    
    /*********************************************
    // Create OpportunityLineItems
    *********************************************/
    public static List<OpportunityLineItem> createOppProducts(List<Opportunity> opps){
    List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
    
    Map<String, String> CountryNameIdMap = CommonUtil.getCountryNameIDMap();
                          
    OpportunityLineItem lineItem = null;
    for(Integer index = 0; index < 4; index++){ 
        lineItem = new OpportunityLineItem();
        lineItem.OpportunityId = opps.get(index).id;
        lineItem.Quantity = 1;            
        lineItem.PricebookEntryId = pricebookEntryList.get(index).Id;
        lineItem.UnitPrice = 100;
        lineItem.Country__c = CountryNameIdMap.values().get(index); 
        oppLineItems.add(lineItem);
    }
    
    //Opportunity Line Items with same OpportunityId
    oppLineItems[1].OpportunityId = opps.get(0).id;
    oppLineItems[2].OpportunityId = opps.get(0).id;
    
    insert oppLineItems;
    return oppLineItems;
    } 
    
    /***************************************************
    // Concatenates Opportunity Line Item Country names
    ****************************************************/
    public static String getCountryString(List<OpportunityLineItem> oppLineItems, 
                                                                                Integer OppLineItemCount) {
        Map<String, String>  countryId_NameMap = CommonUtil.getCountryNameMap();    
    Set<String> CountrySet = new Set<String>();
    
    //Join the country of Opportunity Line Items 
    for(Integer i=0; i<OppLineItemCount; i++) {   
            String country = countryId_NameMap.get(oppLineItems.get(i).Country__c);
        CountrySet.add(country);
    }
        String CountryJoinString = CommonUtil.joinString(CountrySet, ';');
    return CountryJoinString;
    }
}