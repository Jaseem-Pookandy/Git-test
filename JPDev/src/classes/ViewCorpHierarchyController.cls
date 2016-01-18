/*******************************************************************
Name            : ViewCorpHierarchyController
Author          : Byrnes
Date            : June 26, 2014
Related Task    : CC-2632
*************************************************************************/

public class ViewCorpHierarchyController {

    //public stuff...
    public List<String> errors {get; set;}    
    public String sourceAccountID {get; set;}
    public ObjectHierarchyAccessor oha {get; set;}
    public Account sourceAccount {get; set;}
    public String returnButtonLabel {get; set;}
    public String pageHeaderLabel {get; set;}
    public String currentBrand {get; set;}              //This holds the Brand ID of the currently-selected brand from the picklist.
    public List<Account> allAccounts {get; set;}
    private Map<Id, HierarchyWrapper> hierarchyWrapperMap {get; set;}

    //private stuff...
    private User currentUser {get; set;}
    private Set<Id> accountIDsInPlay {get; set;}
    private List<HierarchyWrapper> finalResults {get; set;}
    
    //For CCBOB-148 cerating new button for AccountBrand
    public String returnButtonLabelForAccountBrand {get; set;}
    public String sourceAccountBrandID {get; set;}
    public string sourceAccountBrandName {get;set;}
    
    public ViewCorpHierarchyController(ApexPages.StandardController controller) {

    }

    public PageReference PrepPage() {

        allAccounts = new List<Account>();
        hierarchyWrapperMap = new Map<Id, HierarchyWrapper>();

        returnButtonLabel = 'Return to Account';
        pageHeaderLabel = 'Corporate Hierarchy';

        currentUser = [SELECT Username, Id, DefaultBrand__c FROM User WHERE Id = :UserInfo.getUserId()];
        Map<Id, Brand__c> brandMap = new Map<Id, Brand__c> ([SELECT Id, Name FROM Brand__c WHERE isActive__c = true ORDER BY Name]);  //brand Map for translating user's default brand to the brand Id for the selectList.

        errors = new List<String>();

        sourceAccountID = ApexPages.currentPage().getParameters().get('accid');
        sourceAccountBrandID = ApexPages.currentPage().getParameters().get('brandId');
        sourceAccountBrandName = ApexPages.currentPage().getParameters().get('brandName');
        sourceAccount = new Account();

        if (sourceAccountID == null || sourceAccountID == '') errors.add('Unable to draw the corporate hierarchy as the AccountId was not specified in the querystring.');       

        
        if (sourceAccountID != null && sourceAccountID != '') {
            List<Account> sourceAccounts = [SELECT Id, Name FROM Account WHERE Id = :sourceAccountID];

            if (sourceAccounts.size() == 1) {

                sourceAccount = sourceAccounts[0];
                returnButtonLabel = 'Return to ' + sourceAccount.Name;
                if(sourceAccountBrandID != null && sourceAccountBrandID !=''){
                    returnButtonLabelForAccountBrand = 'Return to ' + sourceAccountBrandName;
                }
                pageHeaderLabel = 'Corporate Hierarchy for ' + sourceAccount.Name;

                oha = new ObjectHierarchyAccessor();
                oha.currentObjId = sourceAccountID;
                oha.parentFieldName = 'ParentId';
                oha.nodeLabelFields = null;

                accountIDsInPlay = new Set<Id>();

                //List<ObjectHierarchyAccessor.ObjectWrapper> structureResults = oha.getObjectStructure();
                Integer i = 0;

                for (ObjectHierarchyAccessor.ObjectWrapper ow : oha.getObjectStructure()) {
                    HierarchyWrapper thisHW = new HierarchyWrapper();
                    thisHW.AccountId = ow.thisObject.id;
                    thisHW.thisAccount = new Account();
                    thisHW.order = i;
                    thisHW.thisOHWrapper = ow;

                    if (!hierarchyWrapperMap.containsKey(ow.thisObject.id)) hierarchyWrapperMap.put(ow.thisObject.id, thisHW);

                    accountIDsInPlay.add(ow.thisObject.id);
                    i++;
                }
            }
        }

        //Begin setting the default brand logic...
        Boolean bDefaulted = false;
        for (Brand__c b : brandMap.values()) {
            if (b.Name == currentUser.DefaultBrand__c) {
                currentBrand = b.Id;   //defaulting the select option list for the user upon first rendering.            
                bDefaulted = true;
            }
        }

        if (!bDefaulted && brandMap != null && brandMap.values().size() > 0) {
            //If it isn't set from the user, default it to the first active brand.
            List<Brand__c> brands = brandMap.values();
            brands.sort();
            if (brands.size() > 0) currentBrand = brands[0].Id;
        }
        //End setting the default brand logic...

        GetAccountAndBrandInfo();

        return null;
    }

    public void GetAccountAndBrandInfo() {
        //Prior to this sub being called, the wrapperclass.account object was null.  Here we populate it...
        //this is probably screwing up the order of the list.  I think I need to restructure this...

        Map<Id, Account> accounts = new Map<Id, Account>([SELECT Id, Name, Status__c, BillingState, BillingCountry, BillingCity, Account_Number__c, (SELECT Id, Brand_Picklist__c, Brand_Name__c, Status__c, Primary_Owner__r.Name FROM Account_Brands__r WHERE Brand__c = :currentBrand) FROM Account WHERE Id IN :accountIDsInPlay]);
        finalResults = new HierarchyWrapper[hierarchyWrapperMap.values().size()];

        for (HierarchyWrapper hw : hierarchyWrapperMap.values()) {

            Account matchingAccount = accounts.get(hw.thisOHWrapper.thisObject.Id);

            //build city, state, zip...
            String addressConcatenation = matchingAccount.BillingCity + ', ' + matchingAccount.BillingState + '  ' + matchingAccount.BillingCountry;

            HierarchyWrapper thisHW = new HierarchyWrapper();
            thisHW.thisAccount = matchingAccount;
            thisHW.thisOHWrapper = hw.thisOHWrapper;
            thisHW.order = hw.order;
            thisHW.addressDetails = addressConcatenation;
            finalResults[hw.order] = thisHW;
        }        
    }   

    public PageReference ReturnToAccount() {
        return new PageReference('/' + sourceAccountID);
    }
    
    public PageReference ReturnToAccountBrand() {
        return new PageReference('/' + sourceAccountBrandID);
    }

    public PageReference redrawPage() {

        //requery the accounts base on the newly selected brand...
        GetAccountAndBrandInfo();
        
        return null;
    }

    public List<HierarchyWrapper> getHierarchyWrapperList() {
        //return hierarchyWrapperMap.values();
        return finalResults;
    }

    public List<SelectOption> getBrandOptions() {
        
        List<SelectOption> brandOptions = new List<SelectOption>();
        
        for (Brand__c b : [SELECT isActive__c, Name, Id FROM Brand__c WHERE isActive__c = true ORDER BY Name ASC]) {        
            brandOptions.add(new SelectOption(b.Id, b.Name));
        }

        if (brandOptions.size() < 1) brandOptions.add(new SelectOption('', 'No active brands found.'));
        
        return brandOptions;
    }


    public with sharing class HierarchyWrapper {

        public Id AccountId {get; set;}
        public Integer order {get; set;}
        public Account thisAccount {get; set;}
        public String addressDetails {get; set;}
        public ObjectHierarchyAccessor.ObjectWrapper thisOHWrapper {get; set;}
    
        public HierarchyWrapper() {
            
        }  
    }    
}