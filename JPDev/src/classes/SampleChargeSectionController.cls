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

public with sharing class SampleChargeSectionController {
    
    public ID quoteId { get; set; }
    public ID opportunityID { get; set; }
    public String productGroup { get; set; }
    public String productSubCategory { get; set; }
    public String priceEditable { get; set; }
    public ID accountBrandId { get; set; } 
    
    public String chargeId { get;set;}
    
    public zqu.zChargeGroup currentChargeGroup { get; set { this.currentChargeGroup = value; this.listWrappedCharges = null; }}
    public List<zqu.zChargeGroup> chargeGroups { get; set; }
   
    public void discountChange() {
        List<zqu.zCharge> charges = zqu.zQuoteUtil.calculateChargesOnDiscountChange(currentChargeGroup.zCharges);
        currentChargeGroup.zCharges = charges;
    }
    public void quantityChange() {
      try {
          List<zqu.zCharge> charges = zqu.zQuoteUtil.calculateChargesOnQuantityChange(currentChargeGroup.zCharges);
          currentChargeGroup.zCharges = charges;
      }
      catch(Exception e) {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
      }
    }
    public void effectiveChange() {
        List<zqu.zCharge> charges = zqu.zQuoteUtil.calculateChargesOnEffectivePriceChange(currentChargeGroup.zCharges);
        currentChargeGroup.zCharges = charges;
    }
    public void totalChange() {
        List<zqu.zCharge> charges = zqu.zQuoteUtil.calculateChargesOnTotalChange(currentChargeGroup.zCharges);
        currentChargeGroup.zCharges = charges;
    }
    public void eventIDChange() {
        listWrappedCharges = new List<WrapperForCustomField>();     
    }
    public List<WrapperForCustomField> listWrappedCharges {
        get{
                
                System.debug('SX: currentChargeGroup' + this.currentChargeGroup);
                List<Recruitment_Event__c> eventObjs = [
                    SELECT r.Id, r.EventID__c, r.Event_Date__c, r.Name  
                    FROM Recruitment_Event__c r
                ];
                            
                zqu.GlobalCustomFieldDefinition.CHARGE_FIELDS = new Set<String> { 'Notes__c', 'Event__c', 'Country__c', 'ServiceStart__c', 'ServiceEnd__c', 'Sales_Representative__c'};
                //If the wrapper class list is empty, populate it with zCharges list
                if ( listWrappedCharges == null ){
                        if (currentChargeGroup != null && currentChargeGroup.zCharges.size() > 0){
                                listWrappedCharges = new List<WrapperForCustomField>();
                                for ( zqu.zCharge zc : currentChargeGroup.zCharges ){
                                        WrapperForCustomField wc = new WrapperForCustomField();
                                        wc.wCharge = zc; 
                                        
                                        for(Recruitment_Event__c eventObj : eventObjs)
                                        {
                                            if(!Test.isRunningTest())
                                            {
                                                if(wc.wCharge.chargeObject.get('Event__c') == eventObj.Id)
                                                {                                                    
                                                    wc.wCharge.chargeObject.put('ServiceStart__c', date.newInstance(eventObj.Event_Date__c.year(), eventObj.Event_Date__c.month(), eventObj.Event_Date__c.day()));
                                                    wc.wCharge.chargeObject.put('ServiceEnd__c', date.newInstance(eventObj.Event_Date__c.year(), eventObj.Event_Date__c.month(), eventObj.Event_Date__c.day()));
                                                }
                                            }
                                        }
                                        
                                        listWrappedCharges.add(wc);
                                }
                        }      
                //If the wrapper class list is not empty, update it with the new calculated values      
                }else{
                        for ( WrapperForCustomField wc : listWrappedCharges ){
                                for ( zqu.zCharge zc : currentChargeGroup.zCharges ){
                                        if ( wc.wCharge.PRODUCT_RATE_PLAN_CHARGE_SFDC_ID  == zc.PRODUCT_RATE_PLAN_CHARGE_SFDC_ID ){
                                                wc.wCharge = zc;   
                                        }
                                }
                        }
                }
                return listWrappedCharges;
        } set;}
       
    public PageReference saveCharges(){
      //Use global method to add zCharges with the Quote.
        final zqu.ZChargeGroup chargeGroup;
        boolean addCharges = true;
        //System.Debug('Reached line 119: '+addCharges);
        if( listWrappedCharges != null && listWrappedCharges.size() > 0 ){
             try {
                 zqu.GlobalCustomFieldDefinition.CHARGE_FIELDS = new Set<String> {'Notes__c', 'Event__c', 'Country__c', 'ServiceStart__c', 'ServiceEnd__c', 'Sales_Representative__c'};

                 Boolean errorsFound = false;
                 Integer rowNum = 0;

                 for ( zqu.zCharge zc : currentChargeGroup.zCharges ) {
                    if(!Test.isRunningTest()) { 

                      rowNum++;

                      if ((zc.chargeObject.get('Sales_Representative__c') == 'null') || (zc.chargeObject.get('Country__c') == 'null')) {
                        if ((zc.chargeObject.get('Sales_Representative__c') == 'null') && (zc.chargeObject.get('Country__c') == 'null')) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Missing data on charge row ' + rowNum + '.  Sales Representative and Country are required.'));
                        if ((zc.chargeObject.get('Sales_Representative__c') != 'null') && (zc.chargeObject.get('Country__c') == 'null')) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Missing data on charge row ' + rowNum + '.  Country is required.'));
                        if ((zc.chargeObject.get('Sales_Representative__c') == 'null') && (zc.chargeObject.get('Country__c') != 'null')) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Missing data on charge row ' + rowNum + '.  Sales Representative is required.'));
                        errorsFound = true;
                        addCharges = false;
                      }
                    }
                 }
                 
                 if(addCharges && errorsFound == false) chargeGroup = zqu.ZQuoteUtil.addChargeGroup(this.currentChargeGroup);

                 } catch(zqu.ZQException e) { ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()); ApexPages.addMessage(msg); return null; }
                
                //Save the custom field value given in UI
                if(chargeGroup != null) {

                  Set<ID> setOfQCIds = new Set<ID>();

                  for ( zqu.zCharge zc : chargeGroup.zCharges ){
                      setOfQCIds.add(zc.Id);
                  }

                  //Query the just inserted QuoteCharges via global method and update the QuoteCharge records with custom field values.
                  List<zqu__QuoteCharge__c> listOfJustSavedQCs = [SELECT ServiceStart__c, ServiceEnd__c, zqu__ProductRatePlanCharge__c FROM zqu__QuoteCharge__c WHERE Id in :setOfQCIds];
                  List<zqu__QuoteCharge__c> toBeUpdatedList = new List<zqu__QuoteCharge__c>();
                  for (WrapperForCustomField wc : listWrappedCharges) {
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
                  try {
                      update toBeUpdatedList;
                  } 
                  catch(Exception e) { ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()); ApexPages.addMessage(msg); return null; }
                }
        }
        
        if(addCharges) return new PageReference('/'+this.quoteId);
        
        return null;
    }
    
    public PageReference saveNewCharges(){
        //Use global method to add zCharges with the Quote.
        final zqu.ZChargeGroup chargeGroup;
        boolean addCharges = false;
        if( listWrappedCharges != null && listWrappedCharges.size() > 0 ){
             try {
                 zqu.GlobalCustomFieldDefinition.CHARGE_FIELDS = new Set<String> {'Notes__c', 'Event__c', 'Country__c', 'ServiceStart__c', 'ServiceEnd__c',  'Sales_Representative__c'};
                 for ( zqu.zCharge zc : currentChargeGroup.zCharges )
                 {
                    if(!Test.isRunningTest())
                    {
                      
                      if(zc.chargeObject.get('Country__c') == 'null')
                      {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please Enter a Valid Country.'));
                        addCharges = false;
                        break;
                      }
                      else {
                        addCharges = true;
                      }
                      
                    }
                    else
                    {
                      addCharges = true;
                    }
                 }
                 
                 if(addCharges)
                 {
                      chargeGroup = zqu.ZQuoteUtil.addChargeGroup(this.currentChargeGroup);
                 }
             } 
             catch(zqu.ZQException e) { ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()); ApexPages.addMessage(msg); return null; }
                //Save the custom field value given in UI
                if(chargeGroup != null)
                {
                  Set<ID> setOfQCIds = new Set<ID>();
                  for ( zqu.zCharge zc : chargeGroup.zCharges ){
                      setOfQCIds.add(zc.Id);
                  }
                  //Query the just inserted QuoteCharges via global method and update the QuoteCharge records with custom field values.
                  List<zqu__QuoteCharge__c> listOfJustSavedQCs = [select ServiceStart__c, ServiceEnd__c, zqu__ProductRatePlanCharge__c from zqu__QuoteCharge__c where Id in :setOfQCIds];
                  
                  List<zqu__QuoteCharge__c> toBeUpdatedList = new List<zqu__QuoteCharge__c>();
                for ( WrapperForCustomField wc : listWrappedCharges ){
                      for ( zqu__QuoteCharge__c qc : listOfJustSavedQCs ){
                              if ( wc.wCharge.PRODUCT_RATE_PLAN_CHARGE_SFDC_ID == qc.zqu__ProductRatePlanCharge__c ){
                                
                                if(!Test.isRunningTest())
                                {
                                  qc.ServiceStart__c = Date.valueOf(wc.wCharge.chargeObject.get('ServiceStart__c')); 
                                  qc.ServiceEnd__c = Date.valueOf(wc.wCharge.chargeObject.get('ServiceEnd__c'));
                                }
                                  toBeUpdatedList.add(qc);
                              }
                      }
                }
                try {
                        update toBeUpdatedList;
                } catch(Exception e) { ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()); ApexPages.addMessage(msg); return null; }
               }
        }
        
        if(addCharges)
        {
          PageReference curPage = ApexPages.currentPage();
          curPage.setRedirect(true);
          curPage.getParameters().put('Id' , quoteId);
          curPage.getParameters().put('skipDisplay','true');
          return curPage;
        }
        
        return null;
    }
    
    public PageReference cancel()
    {
        return new PageReference('/'+this.quoteId);
    }
    
    public List<SelectOption> getCountryOptions()
    {
        List<SelectOption> options = new List<SelectOption>();
         
        List<pw_ccpro__CountryObject__c> countryObjs = [
                Select p.Id, p.Name, p.pw_ccpro__IsoCode_2__c, p.pw_ccpro__IsoCode_3__c, pw_ccpro__Enabled__c 
                From pw_ccpro__CountryObject__c p
                Where pw_ccpro__Enabled__c =: true
                ORDER BY Name
            ];
            
    options.add(new SelectOption('null', '--None--'));            
            
        Set<String> topTenCountries = new Set<String>();
        
        for(pw_ccpro__CountryObject__c countryObj : countryObjs)
        {
          if(String.valueOf(countryObj.Name) == 'United States')
          {
            topTenCountries.add('United States');
            
          } 
          else if(String.valueOf(countryObj.Name) == 'United Kingdom')
          {
            topTenCountries.add('United Kingdom');
            
          }
          else if( String.valueOf(countryObj.Name) == 'France')
          {
            topTenCountries.add('France');
            
          }
          else if(String.valueOf(countryObj.Name) == 'Singapore')
          {
            topTenCountries.add('Singapore');
            
          }
          else if(String.valueOf(countryObj.Name) == 'Australia')
          {
            topTenCountries.add('Australia');
            
          }
          else if(String.valueOf(countryObj.Name) == 'Hong Kong')
          {
            topTenCountries.add('Hong Kong');
            
          }
          else if(String.valueOf(countryObj.Name) == 'Germany')
          {
            topTenCountries.add('Germany');
            
          }
      else if(String.valueOf(countryObj.Name) == 'Switzerland')
      {
        topTenCountries.add('Switzerland');
        
      }
      else if(String.valueOf(countryObj.Name) == 'Middle East')
      {
        topTenCountries.add('Middle East');
        
      }
      else if(String.valueOf(countryObj.Name) == 'Italy')
      {
        topTenCountries.add('Italy');
        
      }
        }
    
    
    if(topTenCountries.contains('United States'))
    {
        options.add(new SelectOption('United States', 'United States'));
    }
  
    if(topTenCountries.contains('United Kingdom'))
    {
        options.add(new SelectOption('United Kingdom', 'United Kingdom'));
    }
  
    if(topTenCountries.contains('France'))
    {
        options.add(new SelectOption('France', 'France'));
    }
  
    if(topTenCountries.contains('Singapore'))
    {
        options.add(new SelectOption('Singapore', 'Singapore'));
    }
  
    if(topTenCountries.contains('Australia'))
    {
        options.add(new SelectOption('Australia', 'Australia'));
    }
  
    if(topTenCountries.contains('Hong Kong'))
    {
      options.add(new SelectOption('Hong Kong', 'Hong Kong'));
    }
  
    if(topTenCountries.contains('Germany'))
    {
        options.add(new SelectOption('Germany', 'Germany'));
    }
  
    if(topTenCountries.contains('Switzerland'))
    {
        options.add(new SelectOption('Switzerland', 'Switzerland'));
    }
  
    if(topTenCountries.contains('Middle East'))
    {
        options.add(new SelectOption('Middle East', 'Middle East'));
    }
  
    if(topTenCountries.contains('Italy'))
    {
        options.add(new SelectOption('Italy', 'Italy'));
    }
        
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
                Select r.Id, r.EventID__c, r.Event_Date__c, r.Name  
                From Recruitment_Event__c r
                ORDER BY Event_Date__c DESC
            ];
        
        options.add(new SelectOption('nullnullnullnul', '--None--'));
        
        for(Recruitment_Event__c eventObj : eventObjs)
        {
            options.add(new SelectOption(String.valueOf(eventObj.Id), String.valueOf(eventObj.Event_Date__c) + ' ' + String.valueOf(eventObj.Name) + ' ' + String.valueOf(eventObj.EventID__c)));
        }
        
        return options;
    }
    
    public List<SelectOption> getActiveUsers() {
      List<SelectOption> options = new List<SelectOption>();
  
      List<User> activeUsers = [
        Select u.Id, u.Name
        From User u
        Where IsActive =: true AND Directly_Commissionable__c = :true
        ORDER BY u.Name
      ];
      
      Opportunity opp = [
        Select Id, Owner.Name, Owner.Directly_Commissionable__c
        From Opportunity
        Where Id =: opportunityId
      ];
      
      if (opp.Owner.Directly_Commissionable__c == true) options.add(new SelectOption(opp.Owner.Name, opp.Owner.Name));
      else options.add(new SelectOption('null', '--None--'));
      
      if(activeUsers.size() != 0 && activeUsers != null)
      {     
        for(User user : activeUsers)
        {
          if(opp.Owner.Name != user.Name) options.add(new SelectOption(user.Name, user.Name));
        }
      }
      
      return options;
    }
    
    public boolean getEventIdField()
    {
        if(this.productGroup == 'Attending')
        {
            return true;
        }
        
        return false;
    }
    
    public boolean getDatesFieldEditable()
    {
        if(this.productGroup == 'Advertising')
        {
            return true;
        }
        
        return false;
    }
    
    public boolean getDatesFieldNonEditable()
    {
        if(this.productGroup == 'Attending')
        {
            return true;
        } 
        
        return false;
    }
    
    public boolean getPriceEditableDiscounts()
    {
      if(this.priceEditable == 'Yes')
      {
        return true;
      }
      
      return false;
    }
    
    public boolean getRenderDiscountRate()
    {
        if(this.productGroup == 'Other' && (this.productSubCategory == 'Discount' || this.productSubCategory == 'Agency Discount'))
        {
            return true;
        }
        
        return false;
    }
    
    //Wrapper class for holding your custom field value in QuoteCharge and global data structure class zCharge
    public class WrapperForCustomField{
        public zqu.zCharge wCharge { get; set; }
    }
}