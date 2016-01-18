@isTest
public class QuoteData_Test {

    public static testMethod void CreateAttributeCustomSettings() {

        List<QuoteChargeAttributes__c> qcAttributes = new List<QuoteChargeAttributes__c>();

        QuoteChargeAttributes__c qca = new QuoteChargeAttributes__c();

        //Insert a country first
        pw_ccpro__CountryObject__c cty = new pw_ccpro__CountryObject__c();
        cty.Name = 'United States of Awesome';
        cty.pw_ccpro__Enabled__c = true;
        cty.pw_ccpro__IsoCode_2__c = 'US';
        cty.pw_ccpro__IsoCode_3__c = 'USA';
        insert cty;

        //Quantity
        qca.Name = 'AttrQuantity__c';
        qca.APIName__c = 'FakeQuantity__c';
        qca.PostbackAction__c = 'RecalcQuoteChargeTotal';
        qca.DefaultValue__c = 'PRPC.DefaultQuantity';
        qca.Label__c = 'Quantity';
        qca.SortOrder__c = 3;
        qca.ControlType__c = 'inputField';
        qcAttributes.add(qca);

        qca = new QuoteChargeAttributes__c();

        //Notes
        qca.Name = 'AttrNotes__c';
        qca.APIName__c = 'Notes__c';        
        qca.Label__c = 'Notes';
        qca.SortOrder__c = 20;
        qca.ControlType__c = 'inputField';      
        qcAttributes.add(qca);

        qca = new QuoteChargeAttributes__c();

        //List Price
        qca.Name = 'AttrListPrice__c';
        qca.APIName__c = 'zqu__ListPriceDisplay__c';
        qca.DefaultValue__c = 'PRPC.ListPrice';
        qca.Label__c = 'List Price';
        qca.SortOrder__c = 4;
        qca.ControlType__c = 'outputTextCurrency';
        qcAttributes.add(qca);

        qca = new QuoteChargeAttributes__c();

        //Country
        qca.Name = 'AttrCountry__c';
        qca.APIName__c = 'Country__c';
        qca.DefaultValue__c = 'FilterPreset.Country';
        qca.Label__c = 'Country';
        qca.SortOrder__c = 8;
        qca.ControlType__c = 'Country';
        qca.SoqlSelect__c = 'Select Id, Name FROM pw_ccpro__CountryObject__c WHERE pw_ccpro__Enabled__c = true ORDER BY Name';
        qca.Picklist_IDField__c = 'Name';
        qca.Picklist_ValueField__c = 'Name';
        qcAttributes.add(qca);      

        qca = new QuoteChargeAttributes__c();

        //Charge Model
        qca.Name = 'AttrChargeModel__c';
        qca.APIName__c = 'zqu__Model__c';       
        qca.Label__c = 'Charge Model';
        qca.SortOrder__c = 2;
        qca.ControlType__c = 'outputText';
        qcAttributes.add(qca);  

        qca = new QuoteChargeAttributes__c();

        //Effective Price
        qca.Name = 'AttrEffectivePrice__c';
        qca.APIName__c = 'zqu__EffectivePrice__c';      
        qca.Label__c = 'Quote Price';
        qca.SortOrder__c = 5;
        qca.ControlType__c = 'intputField';
        qca.PostbackAction__c = 'RecalcQuoteChargeTotal';
        qca.DefaultValue__c = 'PRPC.ListPrice';
        qcAttributes.add(qca);  

        qca = new QuoteChargeAttributes__c();

        //Event
        qca.Name = 'AttrEvent__c';
        qca.APIName__c = 'Event__c';        
        qca.Label__c = 'Event';
        qca.SortOrder__c = 6;
        qca.ControlType__c = 'selectListEvent';
        qca.PostbackAction__c = 'FillStartEndDates';
        qca.SoqlSelect__c = 'SELECT EventID__c, Display_Name__c, Event_Date__c, Id, Status__c FROM Recruitment_Event__c';
        qca.Picklist_IDField__c = 'Id';
        qca.Picklist_ValueField__c = 'Display_Name__c';     
        qcAttributes.add(qca);  

        qca = new QuoteChargeAttributes__c();

        //Charge Line Term
        qca.Name = 'AttrChargeLineTerm__c';
        qca.APIName__c = 'ChargeLineTerm__c';        
        qca.Label__c = 'Charge Line Term';
        qca.SortOrder__c = 100;
        qca.ControlType__c = 'outputText';
        qca.PostbackAction__c = null;
        qca.SoqlSelect__c = null;
        qca.Picklist_IDField__c = null;
        qca.Picklist_ValueField__c = null;     
        qcAttributes.add(qca);  

        qca = new QuoteChargeAttributes__c();

        //Period
        qca.Name = 'AttrPeriod__c';
        qca.APIName__c = 'zqu__Period__c';        
        qca.Label__c = 'Period';
        qca.SortOrder__c = 101;
        qca.ControlType__c = 'outputText';
        qca.PostbackAction__c = null;
        qca.SoqlSelect__c = null;
        qca.Picklist_IDField__c = null;
        qca.Picklist_ValueField__c = null;     
        qca.DefaultValue__c = 'PRPC.zqu__RecurringPeriod__c';
        qcAttributes.add(qca);  

        qca = new QuoteChargeAttributes__c();

        //SalesRep
        qca.Name = 'AttrSalesRep__c';
        qca.APIName__c = 'SalesRepId__c';        
        qca.Label__c = 'Sales Rep';
        qca.SortOrder__c = 102;
        qca.ControlType__c = 'selectList';
        qca.PostbackAction__c = null;
        qca.SoqlSelect__c = 'select Id, Name FROM User WHERE Directly_Commissionable__c = true AND IsActive = true ORDER BY Firstname';
        qca.Picklist_IDField__c = 'Id';
        qca.Picklist_ValueField__c = 'Name';     
        qca.DefaultValue__c = 'Opportunity.OwnerId';
        qcAttributes.add(qca);  

        qca = new QuoteChargeAttributes__c();

        //Service End
        qca.Name = 'AttrServiceEndDate__c';
        qca.APIName__c = 'ServiceEnd__c';        
        qca.Label__c = 'Service End';
        qca.SortOrder__c = 103;
        qca.ControlType__c = 'inputFieldDate';
        qca.PostbackAction__c = 'RecalcChargeLineTerm';
        qca.SoqlSelect__c = null;
        qca.Picklist_IDField__c = null;
        qca.Picklist_ValueField__c = null;     
        qca.DefaultValue__c = 'Quote.ServiceEndDate';
        qcAttributes.add(qca);  

        qca = new QuoteChargeAttributes__c();

        //Service Start
        qca.Name = 'AttrServiceStartDate__c';
        qca.APIName__c = 'ServiceStart__c';        
        qca.Label__c = 'Service Start';
        qca.SortOrder__c = 104;
        qca.ControlType__c = 'inputFieldDate';
        qca.PostbackAction__c = 'RecalcChargeLineTerm';
        qca.SoqlSelect__c = null;
        qca.Picklist_IDField__c = null;
        qca.Picklist_ValueField__c = null;     
        qca.DefaultValue__c = 'Quote.ServiceStartDate';
        qcAttributes.add(qca);           

        qca = new QuoteChargeAttributes__c();

        //UOM
        qca.Name = 'AttrUOM__c';
        qca.APIName__c = 'zqu__UOM__c';        
        qca.Label__c = 'Unit';
        qca.SortOrder__c = 105;
        qca.ControlType__c = 'outputText';
        qca.PostbackAction__c = null;
        qca.SoqlSelect__c = null;
        qca.Picklist_IDField__c = null;
        qca.Picklist_ValueField__c = null;     
        qca.DefaultValue__c = null;
        qcAttributes.add(qca);                   

        insert qcAttributes;
    }

    public static testMethod void CreateAccountContactOppRecords() {

        //Let's create a country first (so the picklist has at least one value!)
        pw_ccpro__CountryObject__c c = new pw_ccpro__CountryObject__c();
        c.Name = 'United Institute of Dice Holdings';
        c.pw_ccpro__IsoCode_2__c = 'DH';
        c.pw_ccpro__IsoCode_3__c = 'IDH';
        insert c;

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
    }

    public static testMethod void CreateZuoraProductRecords() {

    	List<zqu__ProductRatePlanChargeTier__c> prpcTInsert = new List<zqu__ProductRatePlanChargeTier__c>();

        zqu__ZProduct__c zProduct = new zqu__ZProduct__c(Name = 'DicezProduct');
        zProduct.zqu__ZuoraId__c = 'DICE0001';
        
        zProduct.zqu__Active__c = true;
        zProduct.zqu__SKU__c = 'DICE00001';
        insert zProduct;
        
        zqu__ProductRatePlan__c prp = new zqu__ProductRatePlan__c();
        prp.Name = 'Dice Product Rate Plan';
        prp.zqu__ZuoraId__c = 'PRPTEST001';
        
        prp.Brand__c = Constants.BRAND_DICE;
        prp.zqu__ZProduct__c = zProduct.ID;
        prp.ApprovalType__c = 'Manager';
        prp.RatePlanRecurringStatus__c = 'Recurring';
        prp.RatePlanPricingModel__c = 'List Pricing';
        prp.BillingFrequency__c = 'Annual';
        insert prp;
        
        zqu__ProductRatePlanCharge__c prpCharge = new zqu__ProductRatePlanCharge__c();
        prpCharge.Name = 'Test PRP 001';
        prpCharge.zqu__ZuoraId__c = 'TESTPRP01';        
        prpCharge.zqu__Type__c = 'Recurring';
        prpCharge.zqu__Model__c = 'Per Unit Pricing';
        prpCharge.zqu__Discount_Level__c = null;
        prpCharge.zqu__ProductRatePlan__c = prp.ID;
        insert prpCharge;   

        zqu__ProductRatePlanChargeTier__c prpcT = new zqu__ProductRatePlanChargeTier__c();
        prpcT.Name = '1';
        prpcT.zqu__Tier__c = 1;
        prpcT.zqu__Currency__c = 'USD';
        prpcT.zqu__Price__c = 10.50;
        prpcT.zqu__PriceFormat__c = 'Per Unit';
        prpcT.zqu__ProductRatePlanCharge__c = prpCharge.Id;
        prpcT.zqu__StartingUnit__c = 0;
        prpcT.zqu__ZuoraId__c = '123456983510635df';        
        prpcTInsert.add(prpcT);

		prpCharge = new zqu__ProductRatePlanCharge__c();
        prpCharge.Name = 'Test PRP 001b';
        prpCharge.zqu__ZuoraId__c = 'TESTPRP01b';        
        prpCharge.zqu__Type__c = 'Recurring';
        prpCharge.zqu__Model__c = 'Flat Fee Pricing';
        prpCharge.zqu__ProductRatePlan__c = prp.ID;
        prpCharge.zqu__Discount_Level__c = null;
        insert prpCharge;

		prpcT = new zqu__ProductRatePlanChargeTier__c();
        prpcT.Name = '1';
        prpcT.zqu__Tier__c = 1;
        prpcT.zqu__Currency__c = 'USD';
        prpcT.zqu__Price__c = 5.55;
        prpcT.zqu__PriceFormat__c = 'Per Unit';
        prpcT.zqu__ProductRatePlanCharge__c = prpCharge.Id;
        prpcT.zqu__StartingUnit__c = 0;
        prpcT.zqu__ZuoraId__c = '123456983510635dg';
        prpcTInsert.add(prpcT);

		prpCharge = new zqu__ProductRatePlanCharge__c();
        prpCharge.Name = 'Test PRP 001b Discount';
        prpCharge.zqu__ZuoraId__c = 'TESTPRP01c';        
        prpCharge.zqu__Type__c = 'Recurring';
        prpCharge.zqu__Model__c = 'Discount-Percentage';
        prpCharge.zqu__ProductRatePlan__c = prp.ID;
        prpCharge.zqu__Discount_Level__c = 'RatePlan';
        insert prpCharge;

		prpcT = new zqu__ProductRatePlanChargeTier__c();
        prpcT.Name = '1';
        prpcT.zqu__Tier__c = 1;
        prpcT.zqu__Currency__c = 'USD';
        prpcT.zqu__Price__c = 10;
        prpcT.zqu__PriceFormat__c = 'Per Unit';
        prpcT.zqu__ProductRatePlanCharge__c = prpCharge.Id;
        prpcT.zqu__StartingUnit__c = 0;
        prpcT.zqu__ZuoraId__c = '123456983510635dh';
        prpcTInsert.add(prpcT);

		prpCharge = new zqu__ProductRatePlanCharge__c();
        prpCharge.Name = 'Test PRP 001b Vol';
        prpCharge.zqu__ZuoraId__c = 'TESTPRP01d';        
        prpCharge.zqu__Type__c = 'Recurring';
        prpCharge.zqu__Model__c = 'Volume Pricing';
        prpCharge.zqu__ProductRatePlan__c = prp.ID;
        prpCharge.zqu__Discount_Level__c = null;
        insert prpCharge;

		prpcT = new zqu__ProductRatePlanChargeTier__c();
        prpcT.Name = '1';
        prpcT.zqu__Tier__c = 1;
        prpcT.zqu__Currency__c = 'USD';
        prpcT.zqu__Price__c = 10;
        prpcT.zqu__PriceFormat__c = 'Per Unit';
        prpcT.zqu__ProductRatePlanCharge__c = prpCharge.Id;
        prpcT.zqu__StartingUnit__c = 0;
        prpcT.zqu__EndingUnit__c = 1000;
        prpcT.zqu__ZuoraId__c = '123456983510635dI';
        prpcTInsert.add(prpcT);

		prpCharge = new zqu__ProductRatePlanCharge__c();
        prpCharge.Name = 'Test PRP 001b No Tier';
        prpCharge.zqu__ZuoraId__c = 'TESTPRP01e';        
        prpCharge.zqu__Type__c = 'Recurring';
        prpCharge.zqu__Model__c = 'Per Unit';
        prpCharge.zqu__ProductRatePlan__c = prp.ID;
        prpCharge.zqu__Discount_Level__c = null;
        insert prpCharge;        

        insert prpcTInsert;
    }
}