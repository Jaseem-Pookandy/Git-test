/*    Copyright (c) 2013 Zuora, Inc.
 *
 *   Permission is hereby granted, free of charge, to any person obtaining a copy of 
 *   this software and associated documentation files (the "Software"), to use copy, 
 *   modify, merge, publish the Software and to distribute, and sublicense copies of 
 *   the Software, provided no fee is charged for the Software.  In addition the
 *   rights specified above are conditioned upon the following:
 *
 *   The above copyright notice and this permission notice shall be included in all
 *   copies or substantial portions of the Software.
 *
 *   Zuora, Inc. or any other trademarks of Zuora, Inc.  may not be used to endorse
 *   or promote products derived from this Software without specific prior written
 *   permission from Zuora, Inc.
 *
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL
 *   ZUORA, INC. BE LIABLE FOR ANY DIRECT, INDIRECT OR CONSEQUENTIAL DAMAGES
 *   (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 *   LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 *   ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 *   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.  

 *   IN THE EVENT YOU ARE AN EXISTING ZUORA CUSTOMER, USE OF THIS SOFTWARE IS GOVERNED

 *   BY THIS AGREEMENT AND NOT YOUR MASTER SUBSCRIPTION AGREEMENT WITH ZUORA.
 */
 
public with sharing class CustomChargeGroupController {
    
    private final ApexPages.StandardController controller;
    public ID quoteId { get; set; }
    public zqu__Quote__c quote {get;set;}
    
    public List<zqu.zCharge> zcCharges {get;set;}
    public zqu.zChargeGroup chargeGroupToEdit {get;set;}
    public String selectedChargeGroupId {get;set;}
    public String chargeId {get;set;}
    public Map<Integer, String> stringCalendarMonth = new Map<Integer, String>();
    
    //The chargeGroups for the quote    
    public List<zqu.zChargeGroup> chargeGroups {get;set;}

    public boolean allowEditInComponent{
        get
        {
            if(allowEditInComponent == null) return false;
            return allowEditInComponent;
        }

        set;
    }
    
    //are we editing a chargeGroup
    public Boolean editMode {
        get {
            if (editMode == null) editMode = false;
            return editMode;
        }
        set;
    }
    
    //account id for the quote gotten from the opp
    public string accountId{
        get{
            if(accountId == null){
        
                zqu__Quote__c quote = [SELECT Id, zqu__Opportunity__r.Account.Id
                    FROM zqu__Quote__c 
                    WHERE id = :quoteId
                    LIMIT 1];
            
                if(quote!= null)    accountId = quote.zqu__Opportunity__r.Account.Id;
            
                return accountId;
            }
            else    return accountId;
        }
    
        set;
    }   
    
    public List<WrapperForChargeGroup> listWrapperChargeGroups {
        get{
                //setStringCalendarMonth();
                zqu.GlobalCustomFieldDefinition.CHARGE_FIELDS = new Set<String> { 'Notes__c', 'Event__c', 'EventID__c', 'Country__c', 'ServiceStart__c', 'ServiceEnd__c', 'Sales_Representative__c'};
                //If the wrapper class list is empty, populate it with zCharges list
               
                listWrapperChargeGroups = new List<WrapperForChargeGroup>();
                zcCharges = new List<zqu.zCharge>();
                                           
                if(chargeGroups != null)
                {
                    List<zqu__QuoteCharge__c> listNewSubCharges = new List<zqu__QuoteCharge__c>();
                    List<zqu__QuoteRatePlanCharge__c> listAmendCharges = new List<zqu__QuoteRatePlanCharge__c>();

                    zqu__Quote__c tempQuote = [SELECT Id, zqu__SubscriptionType__c FROM zqu__Quote__c WHERE Id=: quoteId];
                    if(tempQuote.zqu__SubscriptionType__c == 'New Subscription')
                    {
                        listNewSubCharges = [
                            Select Id, zqu__ProductRatePlanCharge__c, Country__c, Notes__c, Event__c, EventID__c, ServiceStart__c, ServiceEnd__c, Sales_Representative__c
                            FROM zqu__QuoteCharge__c
                            WHERE zqu__Quote__c =: quoteId
                        ];
                        
                    }
                    else if(tempQuote.zqu__SubscriptionType__c == 'Amend Subscription' || tempQuote.zqu__SubscriptionType__c == 'Renew Subscription')
                    {           
                        List<zqu__QuoteRatePlan__c> quoteRatePlans = [Select z.Id FROM zqu__QuoteRatePlan__c z WHERE zqu__Quote__c=:quoteId];
                        
                        for(zqu__QuoteRatePlan__c quoteRatePlan : quoteRatePlans)
                        {
                            listAmendCharges = [
                                Select Id, Country__c, Notes__c, Event__c, EventID__c, ServiceStart__c, ServiceEnd__c, Sales_Representative__c
                                From zqu__QuoteRatePlanCharge__c 
                                WHERE zqu__QuoteRatePlan__c =:quoteRatePlan.Id
                            ];
                        }
                    }
                        
                    List<Recruitment_Event__c> eventObjs = [
                        SELECT  r.Id, r.EventID__c, r.Event_Date__c, r.Name  
                        FROM Recruitment_Event__c r
                    ];
                    List<zqu__ZProduct__c> zProducts = [Select z.Id, z.Name, z.ProductGroup__c, z.ProductSubCategory__c, PriceEditable__c From zqu__ZProduct__c z WHERE zqu__Deleted__c =: false];
                    //List<zqu__ProductRatePlan__c> zRatePlans = [Select z.Id, z.zqu__ZuoraId__c, z.zqu__ZProduct__c From zqu__ProductRatePlan__c z WHERE zqu__ZProduct__c IN : zProducts];
                    for(zqu.zChargeGroup currentChargeGroup : chargeGroups)
                    {
                        if (currentChargeGroup != null && currentChargeGroup.zCharges.size() > 0){
                            WrapperForChargeGroup wg = new WrapperForChargeGroup();
                            wg.productName = currentChargeGroup.productName;
                            wg.ratePlanName = currentChargeGroup.rateplanName;
                            wg.groupID = currentChargeGroup.groupID;
                            wg.types = currentChargeGroup.groupType;
                            
                            for(zqu__ZProduct__c zProduct : zProducts)
                            {
                                if(zProduct.Name == currentChargeGroup.productName)
                                {
                                    wg.productGroup = zProduct.ProductGroup__c;
                                    wg.productSubCategory = zProduct.ProductSubCategory__c ;
                                    wg.priceEditable = zProduct.PriceEditable__c;
                                }
                            }
                            
                            List<WrapperForCharges> listWrapperCharges = new List<WrapperForCharges>();
                            for ( zqu.zCharge zc : currentChargeGroup.zCharges ) {
                                WrapperForCharges wc = new WrapperForCharges();
                                wc.wCharge = zc;
                                
                                if (tempQuote.zqu__SubscriptionType__c == 'New Subscription') {
                                    for (zqu__QuoteCharge__c qCharge : listNewSubCharges) {
                                        if (qCharge.Id ==  zc.Id) {                                                    
                                            for (Recruitment_Event__c eventObj : eventObjs) {
                                                if (wc.wCharge.chargeObject.get('Event__c') == eventObj.Id) {
                                                    if (eventObj.Event_Date__c != null) {
                                                        //Byrnes, INC24399 - added check for null so as to not blow up the page.
                                                        wc.wCharge.chargeObject.put('ServiceStart__c', date.newInstance(eventObj.Event_Date__c.year(), eventObj.Event_Date__c.month(), eventObj.Event_Date__c.day()));
                                                        wc.wCharge.chargeObject.put('ServiceEnd__c', date.newInstance(eventObj.Event_Date__c.year(), eventObj.Event_Date__c.month(), eventObj.Event_Date__c.day()));
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                else if((tempQuote.zqu__SubscriptionType__c == 'Amend Subscription' || tempQuote.zqu__SubscriptionType__c == 'Renew Subscription') && (currentChargeGroup.groupType == 4 || currentChargeGroup.groupType == 8))
                                {
                                    for (zqu__QuoteRatePlanCharge__c qCharge : listAmendCharges) {
                                        if (qCharge.Id ==  zc.Id) {                                                    
                                            for (Recruitment_Event__c eventObj : eventObjs) {
                                                if (wc.wCharge.chargeObject.get('Event__c') == eventObj.Id) {
                                                    if (eventObj.Event_Date__c != null) {
                                                        //Byrnes, INC24399 - added check for null so as to not blow up the page.
                                                        wc.wCharge.chargeObject.put('ServiceStart__c', date.newInstance(eventObj.Event_Date__c.year(), eventObj.Event_Date__c.month(), eventObj.Event_Date__c.day()));
                                                        wc.wCharge.chargeObject.put('ServiceEnd__c', date.newInstance(eventObj.Event_Date__c.year(), eventObj.Event_Date__c.month(), eventObj.Event_Date__c.day()));
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                else if((tempQuote.zqu__SubscriptionType__c == 'Amend Subscription' || tempQuote.zqu__SubscriptionType__c == 'Renew Subscription') && (currentChargeGroup.groupType != 4 || currentChargeGroup.groupType != 8))
                                {
                                    List<Zuora__SubscriptionProductCharge__c> listOldAmendCharges = getSubscriptionCharge(this.accountId);
                                    
                                    for(Zuora__SubscriptionProductCharge__c oldCharge : listOldAmendCharges)
                                    {
                                        if (oldCharge.Zuora__Zuora_Id__c  == zc.getQuoteRatePlanChargeZuoraId())
                                        {                                                    
                                            wc.wCharge.chargeObject.put('Country__c', oldCharge.Country__c);
                                            wc.wCharge.chargeObject.put('Notes__c', oldCharge.Notes__c);
                                            wc.wCharge.chargeObject.put('ServiceStart__c', oldCharge.ServiceStart__c);
                                            wc.wCharge.chargeObject.put('ServiceEnd__c', oldCharge.ServiceEnd__c);
                                            wc.wcharge.chargeObject.put('Sales_Representative__c', oldCharge.Sales_Representative__c);
                                        }
                                    }
                                }
                               
                                listWrapperCharges.add(wc);
                            }
                            wg.listOfCharges = listWrapperCharges;
                            listWrapperChargeGroups.add(wg);
                        }
                    }
                }                
                return listWrapperChargeGroups;
        } 
        
        set;
    }
    
    public CustomChargeGroupController(ApexPages.StandardController controller)
    {
        this.controller = controller;   
        quoteId = this.controller.getRecord().Id;
            
        this.quote = [SELECT Id, zqu__Currency__c, zqu__ZuoraAccountID__c, zqu__ZuoraSubscriptionID__c, zqu__Opportunity__c, zqu__Opportunity__r.Account.Id, zqu__SubscriptionType__c, zqu__Status__c FROM zqu__Quote__c WHERE id = :quoteId LIMIT 1];
                
        if (this.validate()) {
           try {
               zqu.GlobalCustomFieldDefinition.CHARGE_FIELDS = new Set<String> { 'Notes__c', 'Event__c', 'EventID__c', 'Country__c', 'ServiceStart__c', 'ServiceEnd__c', 'Sales_Representative__c'};
               chargeGroups = zqu.zQuoteUtil.getChargeGroups(quoteId);   
           } catch(Exception e) { appendMessage(ApexPages.Severity.ERROR, e.getMessage()); }
        }
    }
    
    public CustomChargeGroupController(){}
        
    //THIS SHOULD BE A GLOBAL METHOD
    //Returns a map of the subscription charges
    private List<Zuora__SubscriptionProductCharge__c> getSubscriptionCharge(String sfdcAccountId){
        
        List<Zuora__Subscription__c> subscriptions = new List<Zuora__Subscription__c>();
        
        subscriptions = [SELECT id, Zuora__Account__c 
          FROM Zuora__Subscription__c
          WHERE Zuora__Account__c = :sfdcAccountId];
        
        List<Id> subIds = new List<Id>();
        
        for(Zuora__Subscription__c sub : subscriptions) subIds.add(sub.Id);
        
        List<Zuora__SubscriptionProductCharge__c> charges = [SELECT Id, Zuora__Zuora_Id__c, Country__c, Notes__c, EventID__c, ServiceStart__c, ServiceEnd__c, Sales_Representative__c
            FROM  Zuora__SubscriptionProductCharge__c
            WHERE Zuora__Subscription__c IN :subIds];
        
        return charges;
    }
    
  /*
    OnChange actions to interact with the Zuora charges
  */
  public void discountChange() {
        List<zqu.zCharge> charges = zqu.zQuoteUtil.calculateChargesOnDiscountChange(chargeGroupToEdit.zCharges);
        chargeGroupToEdit.zCharges = charges;
    }
    public void quantityChange() {
        List<zqu.zCharge> charges = zqu.zQuoteUtil.calculateChargesOnQuantityChange(chargeGroupToEdit.zCharges);
        chargeGroupToEdit.zCharges = charges;
    }
    public void effectiveChange() {
        List<zqu.zCharge> charges = zqu.zQuoteUtil.calculateChargesOnEffectivePriceChange(chargeGroupToEdit.zCharges);
        chargeGroupToEdit.zCharges = charges;
    }
    public void totalChange() {
        List<zqu.zCharge> charges = zqu.zQuoteUtil.calculateChargesOnTotalChange(chargeGroupToEdit.zCharges);
        chargeGroupToEdit.zCharges = charges;
    }
    public void eventIDChange() {
        listWrapperChargeGroups = null;
        listWrapperChargeGroups = new List<WrapperForChargeGroup>();
    }
    
   /*
        Button Actions
   */
   public void editChargeGroup() {
        zqu.GlobalCustomFieldDefinition.CHARGE_FIELDS = new Set<String> { 'Notes__c', 'Event__c', 'EventID__c', 'Country__c', 'ServiceStart__c', 'ServiceEnd__c', 'Sales_Representative__c'};
        if (this.selectedChargeGroupId != null && this.quoteId != null) {
            for (Integer i = 0; i < this.chargeGroups.size(); i++) {
                zqu.ZChargeGroup zchargeGrp = this.chargeGroups.get(i);
                if (this.selectedChargeGroupId == zchargeGrp.groupId) {
                    this.chargeGroupToEdit = zchargeGrp.deepclone();
                    System.Debug('AB: chargeGroupToEdit ' + this.chargeGroupToEdit);
                    break;                    
                }
            }
            
            this.editMode = true;            
        }
    }
    
    public PageReference saveChargeGroup() {
        if (null != this.quoteId) {
          zqu.ZChargeGroup updatedChargeGroup = null;
          
          try {
            zqu.GlobalCustomFieldDefinition.CHARGE_FIELDS = new Set<String> { 'Notes__c', 'Event__c', 'Country__c', 'ServiceStart__c', 'ServiceEnd__c', 'Sales_Representative__c'};
            updatedChargeGroup = zqu.zQuoteUtil.updateChargeGroup(this.chargeGroupToEdit);
          } catch (zqu.ZQException e) { ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage());    ApexPages.addMessage(msg);  return null; }
          for (Integer i = 0; i < this.chargeGroups.size(); i++) {
            zqu.ZChargeGroup zchargeGrp = this.chargeGroups.get(i);
            if (updatedChargeGroup.groupId == zchargeGrp.groupId)   this.chargeGroups.set(i, updatedChargeGroup);
          }
          
          //Save the custom field value given in UI
          if(updatedChargeGroup != null) {

                Set<ID> setOfQCIds = new Set<ID>();
                for (zqu.zCharge zc : updatedChargeGroup.zCharges)  setOfQCIds.add(zc.Id);
                
                //Query the just inserted QuoteCharges via global method and update the QuoteCharge records with custom field values.
                List<zqu__QuoteCharge__c> listOfJustSavedQCs = [
                    SELECT ServiceStart__c, ServiceEnd__c, zqu__ProductRatePlanCharge__c 
                    FROM zqu__QuoteCharge__c 
                    WHERE Id IN :setOfQCIds];
                    
                List<zqu__QuoteCharge__c> toBeUpdatedList = new List<zqu__QuoteCharge__c>();
                
                for (WrapperForChargeGroup wcg : listWrapperChargeGroups) {

                    if (wcg.groupID == chargeGroupToEdit.groupID) {

                        for (WrapperForCharges wc: wcg.listOfCharges) {

                            for (zqu__QuoteCharge__c qc : listOfJustSavedQCs) {

                                if (wc.wCharge.PRODUCT_RATE_PLAN_CHARGE_SFDC_ID == qc.zqu__ProductRatePlanCharge__c) {

                                    if(!Test.isRunningTest()) { 
                                        qc.ServiceStart__c = Date.valueOf(wc.wCharge.chargeObject.get('ServiceStart__c')); 
                                        qc.ServiceEnd__c = Date.valueOf(wc.wCharge.chargeObject.get('ServiceEnd__c'));
                                    }

                                    toBeUpdatedList.add(qc);
                                }
                            }
                        }
                    }
                }
                try {
                        update toBeUpdatedList;
                } catch(Exception e) { ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()); ApexPages.addMessage(msg); return null; }
           }
        }
        this.editMode = false;
        return null;
    }
    
    public PageReference deleteChargeGroup() {
        if (this.selectedChargeGroupId != null && this.quoteId != null) {
          for (Integer i = 0; i < this.chargeGroups.size(); i++) {
            zqu.ZChargeGroup zchargeGrp = this.chargeGroups.get(i);
            if (this.selectedChargeGroupId == zchargeGrp.groupId) {
              this.chargeGroupToEdit = zchargeGrp;
              zqu.ZChargeGroup deletedChargeGroup = null;
              try {
                deletedChargeGroup = zqu.zQuoteUtil.deleteChargeGroup(zchargeGrp);
              } catch (zqu.ZQException e) { appendMessage(ApexPages.Severity.ERROR, e.getMessage()); return null; }
              
              if (deletedChargeGroup != null)   this.chargeGroups.set(i, deletedChargeGroup);
              else this.chargeGroups.remove(i);
              
              break;
            }
          }
        }
        return null;
    }
    
    //Button action takes you out of edit mode
    public void goBack(){
        editMode = false;
    }
    
    public boolean getRenderEventId()
    {
        List<zqu__ZProduct__c> zProducts = [Select z.Id, z.Name, z.ProductGroup__c  From zqu__ZProduct__c z WHERE zqu__Deleted__c =: false];
        zqu.GlobalCustomFieldDefinition.CHARGE_FIELDS = new Set<String> { 'Notes__c', 'Event__c', 'Country__c', 'EventID__c', 'ServiceStart__c', 'ServiceEnd__c', 'Sales_Representative__c'};
        if(chargeGroups != null)
        {
            for(zqu.zChargeGroup tempChargeGroup : chargeGroups)
            {
                if(tempChargeGroup.groupID == selectedChargeGroupId)
                {
                    for(zqu__ZProduct__c zProduct : zProducts)
                    {
                        if(zProduct.Name == tempChargeGroup.productName)
                        {
                            if(zProduct.ProductGroup__c == 'Attending') return true;
                        }
                    }   
                }
            }
        }
        
        return false;
    }  
    
    public boolean getDatesFieldEditable()
    {
        List<zqu__ZProduct__c> zProducts = [Select z.Id, z.Name, z.ProductGroup__c  From zqu__ZProduct__c z WHERE zqu__Deleted__c =: false];
        zqu.GlobalCustomFieldDefinition.CHARGE_FIELDS = new Set<String> { 'Notes__c', 'Event__c', 'EventID__c', 'Country__c', 'ServiceStart__c', 'ServiceEnd__c', 'Sales_Representative__c'};
        if(chargeGroups != null)
        {
            for(zqu.zChargeGroup tempChargeGroup : chargeGroups)
            {
                if(tempChargeGroup.groupID == selectedChargeGroupId)
                {
                    for(zqu__ZProduct__c zProduct : zProducts)
                    {
                        if(zProduct.Name == tempChargeGroup.productName)
                        {
                            if(zProduct.ProductGroup__c == 'Advertising')   return true;
                        }
                    }   
                }
            }
        }
        
        return false;
    }
    
    public boolean getNoEventFields()
    {
        List<zqu__ZProduct__c> zProducts = [Select z.Id, z.Name, z.ProductGroup__c  From zqu__ZProduct__c z WHERE zqu__Deleted__c =: false];
        zqu.GlobalCustomFieldDefinition.CHARGE_FIELDS = new Set<String> { 'Notes__c', 'Event__c', 'EventID__c', 'Country__c', 'ServiceStart__c', 'ServiceEnd__c', 'Sales_Representative__c'};
        if(chargeGroups != null)
        {
            for(zqu.zChargeGroup tempChargeGroup : chargeGroups)
            {
                if(tempChargeGroup.groupID == selectedChargeGroupId)
                {
                    for(zqu__ZProduct__c zProduct : zProducts)
                    {
                        if(zProduct.Name == tempChargeGroup.productName)
                        {
                            if(zProduct.ProductGroup__c == 'Attending' || zProduct.ProductGroup__c == 'Advertising')    return false;
                        }
                    }   
                }
            }
        }
        
        return true;
    }
    
    public boolean getRenderDiscountRate()
    {
        List<zqu__ZProduct__c> zProducts = [Select z.Id, z.Name, z.ProductGroup__c, z.ProductSubCategory__c From zqu__ZProduct__c z WHERE zqu__Deleted__c =: false];
        zqu.GlobalCustomFieldDefinition.CHARGE_FIELDS = new Set<String> { 'Notes__c', 'Event__c', 'EventID__c', 'Country__c', 'ServiceStart__c', 'ServiceEnd__c', 'Sales_Representative__c'};
        if(chargeGroups != null)
        {
            for(zqu.zChargeGroup tempChargeGroup : chargeGroups)
            {
                if(tempChargeGroup.groupID == selectedChargeGroupId)
                {
                    for(zqu__ZProduct__c zProduct : zProducts)
                    {
                        if(zProduct.Name == tempChargeGroup.productName)
                        {
                            if(zProduct.ProductGroup__c == 'Other' && (zProduct.ProductSubCategory__c == 'Discount' || zProduct.ProductSubCategory__c == 'Agency Discount'))    return true;
                        }
                    }   
                }
            }
        }
        
        return false;
    }
    
        
    public boolean getPriceEditable()
    {
        List<zqu__ZProduct__c> zProducts = [
            SELECT z.Id, z.Name, z.ProductGroup__c, z.ProductSubCategory__c, PriceEditable__c 
            FROM zqu__ZProduct__c z 
            WHERE zqu__Deleted__c =: false
        ];
        zqu.GlobalCustomFieldDefinition.CHARGE_FIELDS = new Set<String> { 'Notes__c', 'Event__c', 'EventID__c', 'Country__c', 'ServiceStart__c', 'ServiceEnd__c', 'Sales_Representative__c'};
        
        if(chargeGroups != null)
        {
            for(zqu.zChargeGroup tempChargeGroup : chargeGroups)
            {
                if(tempChargeGroup.groupID == chargeGroupToEdit.groupID)
                {
                    for(zqu__ZProduct__c zProduct : zProducts)
                    {
                        if(zProduct.Name == tempChargeGroup.productName)
                        {
                            if(zProduct.PriceEditable__c == 'Yes')  return true;
                        }
                    }   
                }
            }
        }
        
        return false;
    }
    
    public List<SelectOption> getCountryOptions()
    {
        List<SelectOption> options = new List<SelectOption>();
         
        List<pw_ccpro__CountryObject__c> countryObjs = [
                Select p.Id, p.Name, p.pw_ccpro__IsoCode_2__c, p.pw_ccpro__IsoCode_3__c 
                From pw_ccpro__CountryObject__c p
                Where pw_ccpro__Enabled__c =: true
                ORDER BY Name
            ];
            
        Set<String> topTenCountries = new Set<String>();
        
        for(pw_ccpro__CountryObject__c countryObj : countryObjs)
        {
            if(String.valueOf(countryObj.Name) == 'United States')  topTenCountries.add('United States');
            else if(String.valueOf(countryObj.Name) == 'United Kingdom')    topTenCountries.add('United Kingdom');
            else if( String.valueOf(countryObj.Name) == 'France')   topTenCountries.add('France');
            else if(String.valueOf(countryObj.Name) == 'Singapore') topTenCountries.add('Singapore');
            else if(String.valueOf(countryObj.Name) == 'Australia') topTenCountries.add('Australia');
            else if(String.valueOf(countryObj.Name) == 'Hong Kong') topTenCountries.add('Hong Kong');
            else if(String.valueOf(countryObj.Name) == 'Germany')   topTenCountries.add('Germany');
            else if(String.valueOf(countryObj.Name) == 'Switzerland')   topTenCountries.add('Switzerland');
            else if(String.valueOf(countryObj.Name) == 'Middle East')   topTenCountries.add('Middle East');
            else if(String.valueOf(countryObj.Name) == 'Italy') topTenCountries.add('Italy');
        }

        if(topTenCountries.contains('United States'))   options.add(new SelectOption('United States', 'United States'));
        if(topTenCountries.contains('United Kingdom'))  options.add(new SelectOption('United Kingdom', 'United Kingdom'));
        if(topTenCountries.contains('France'))  options.add(new SelectOption('France', 'France'));
        if(topTenCountries.contains('Singapore'))   options.add(new SelectOption('Singapore', 'Singapore'));
        if(topTenCountries.contains('Australia'))   options.add(new SelectOption('Australia', 'Australia'));
        if(topTenCountries.contains('Hong Kong'))   options.add(new SelectOption('Hong Kong', 'Hong Kong'));
        if(topTenCountries.contains('Germany')) options.add(new SelectOption('Germany', 'Germany'));
        if(topTenCountries.contains('Switzerland')) options.add(new SelectOption('Switzerland', 'Switzerland'));
        if(topTenCountries.contains('Middle East')) options.add(new SelectOption('Middle East', 'Middle East'));
        if(topTenCountries.contains('Italy'))   options.add(new SelectOption('Italy', 'Italy'));
        
        
        for(pw_ccpro__CountryObject__c countryObj : countryObjs)
        {
            if(String.valueOf(countryObj.Name) != 'United States' && String.valueOf(countryObj.Name) != 'United Kingdom' && String.valueOf(countryObj.Name) != 'France' 
                && String.valueOf(countryObj.Name) != 'Singapore' && String.valueOf(countryObj.Name) != 'Australia' && String.valueOf(countryObj.Name) != 'Hong Kong' 
                && String.valueOf(countryObj.Name) != 'Germany' && String.valueOf(countryObj.Name) != 'Switzerland' && String.valueOf(countryObj.Name) != 'Middle East' 
                && String.valueOf(countryObj.Name) != 'Italy') {
                    
                    options.add(new SelectOption(String.valueOf(countryObj.Name), String.valueOf(countryObj.Name)));
                }
        }
        return options;
    }
    
    public List<SelectOption> getEventIDOptions()
    {
        List<SelectOption> options = new List<SelectOption>();
         
        List<Recruitment_Event__c> eventObjs = [
                Select  r.Id, r.EventID__c, r.Event_Date__c, r.Name  
                From Recruitment_Event__c r
                ORDER BY Event_Date__c DESC
            ];
        
        options.add(new SelectOption('--None--', '--None--'));
        
        for(Recruitment_Event__c eventObj : eventObjs)  options.add(new SelectOption(String.valueOf(eventObj.Id), String.valueOf(eventObj.Event_Date__c) + ' ' + String.valueOf(eventObj.Name) + ' ' + String.valueOf(eventObj.EventID__c)));
        
        return options;
    }
    
    public List<SelectOption> getActiveUsers() {
        List<SelectOption> options = new List<SelectOption>();
    
        zqu__Quote__c cQuote = [
            SELECT Id, zqu__Opportunity__r.Account.Id, zqu__Opportunity__r.Account_Brand__c, zqu__Opportunity__r.Owner.Name, zqu__Opportunity__r.Owner.Directly_Commissionable__c
            FROM zqu__Quote__c 
            WHERE id =: quoteId
            LIMIT 1
        ];
        
        List<User> activeUsers = [
            SELECT u.Id, u.Name
            FROM User u
            WHERE IsActive =: true AND Directly_Commissionable__c = :true
            ORDER BY u.Name
        ];      
        
        if (cQuote.zqu__Opportunity__r.Owner.Directly_Commissionable__c == true) options.add(new SelectOption(cQuote.zqu__Opportunity__r.Owner.Name, cQuote.zqu__Opportunity__r.Owner.Name));
        //else options.add(new SelectOption('null', '--None--'));
          
        if(activeUsers.size() != 0 && activeUsers != null)
        {           
            for(User user : activeUsers)
            {
                if(cQuote.zqu__Opportunity__r.Owner.Name != user.Name)  options.add(new SelectOption(user.Name, user.Name));
            }
        }
        
        return options;
    }

    //Wrapper class for holding your custom field value in QuoteCharge and global data structure class zCharge
    public class WrapperForChargeGroup
    {
        public String ratePlanName {get;set;}
        public String productName {get;set;}
        public String groupID {get;set;}
        public Integer types {get;set;}
        public String productGroup {get;set;}
        public String productSubCategory {get;set;}
        public String priceEditable {get;set;}
        public List<WrapperForCharges> listOfCharges {get;set;}
    }
    
    public class WrapperForCharges
    {
        public zqu.zCharge wCharge {get;set;}
        public String country {get;set;}
        public String eventID {get;set;}
        public String notes {get;set;}
        public String serviceStartDate {get;set;}
        public String serviceEndDate {get;set;} 
    }
    
    private Boolean validate() {
        if (null == this.controller.getRecord() || null == this.controller.getRecord().Id) {
            appendMessage(ApexPages.Severity.ERROR, 'Need to specify the id of quote for creating subscription.');
            return false;
        }
        return true;
    }
    
    private static void appendMessage(ApexPages.Severity messageType, String message) {
        ApexPages.addMessage(new ApexPages.Message(messageType, message));
    }
}