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
 
public with sharing class SelectProductsWithFilterCon {
       
    public List<zqu.zChargeGroup> chargeGroupList           {get; set;}
    public Boolean   editMode                               {get; set;}
    public String    currentChargeGroupId                   {get; set;}
    public zqu.zChargeGroup currentChargeGroup              {get; set;}
    private final zqu__Quote__c quote                       {get; set;}
    private List<ID> productIDs;
    private List<ID> rateplanIDs;

    public String filterBrandTag                      {get;set;}
    public String filterBillingFrequency              {get;set;}
    
    public List<SelectOption> productGroupList        {get;set;}
    public String productGroupValue                   {get;set;}
    public List<SelectOption> brandList               {get;set;}
    public String brandValue                          {get;set;}

    // Table data share
    public zqu.zComponentDataShare productDataShare         {get; set;}
    public zqu.zComponentDataShare rateplanDataShare        {get; set;}
    public zqu.zChargeGroup chargeGroup                     {get; set;}
    public Boolean selectNewProductViewMode                 {get; private set;}
    public Boolean initFailed                               {get; private set;}

    public final static Integer PRODUCT_TABLE_PAGE_SIZE = 10;
    public final static Integer RATEPLAN_TABLE_PAGE_SIZE = 10;
   
    private String quoteId;
    public String searchString {get;set;}
   
    public SelectProductsWithFilterCon(ApexPages.StandardController controller) {
        initFailed = true;
        
        filterBrandTag = '-All-';
        filterBillingFrequency = '-All-';
        
        quoteId = controller.getId();
        if (null == quoteId || '' == quoteId) {
            appendErrorMessage('Need to specify the id of quote.');
            return;
        }  
        List<zqu__Quote__c> quotelist = [SELECT Id, Name, zqu__Opportunity__r.Name, zqu__Opportunity__r.Account.Name, zqu__Opportunity__r.Account.Id, zqu__RecordReadOnly__c, zqu__Currency__c, zqu__Status__c, zqu__StartDate__c, RecordTypeId
           FROM zqu__Quote__c WHERE Id = :quoteId LIMIT 1];
       
        if(1 != quotelist.size()){
            appendErrorMessage('Invalid quote id.');
            return ;
        }
        this.quote = quotelist[0];
        try {        
            zqu.GlobalCustomFieldDefinition.CHARGE_FIELDS = new Set<String> { 'Notes__c', 'Event__c', 'Country__c', 'ServiceStart__c', 'ServiceEnd__c' };
            this.chargeGroupList = zqu.zQuoteUtil.getChargeGroups(this.quote.Id);
            this.editMode = false;
            this.selectNewProductViewMode = !(this.chargeGroupList.size() > 0);
            this.productDataShare = new zqu.zComponentDataShare();
                 
            this.productIDs = getFilteredZProductIds(this.quote.zqu__Currency__c, this.quote.zqu__StartDate__c);
            this.productDataShare.dataObject = zqu.ZQuoteUtil.getProductSetController(this.productIDs, this.getProductDisplayFields(), PRODUCT_TABLE_PAGE_SIZE);
        } catch(zqu.ZQException e) {
            appendErrorMessage(e.getMessage());
            return;
        }
        
        this.rateplanDataShare = new zqu.zComponentDataShare();
        this.selectedProductShare = new zqu.zComponentDataShare();
        this.selectedRatePlanShare = new zqu.zComponentDataShare();        
        this.initFailed = false;
        
        productGroupList = getProductGroupValue();
        brandList = getBrandValue();
    }
    
    public List < Id > searchProducts(List < Id > prodids, Date zqStartDate) {
        List < Id > productIds = new List < Id > ();
        try {
          String searchQuery = '*' + searchString + '*';
          searchQuery = 'FIND \'' + searchQuery + '\' IN ALL FIELDS RETURNING zqu__zProduct__c(Id, Name, zqu__SKU__c, zqu__Description__c, zqu__ZuoraId__c WHERE id in :prodids AND zqu__Deleted__c = false AND zqu__EffectiveStartDate__c <= :zQStartDate AND zqu__EffectiveEndDate__c >= :zQStartDate ORDER BY Name ASC)';
          List < SObject > results = search.query(searchQuery)[0];
          for (SObject sobj: results) {
            productIds.add(sobj.Id);
          }
        } catch (Exception e) { ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()); ApexPages.addMessage(msg); }
        return productIds;
    }
    
    public void refreshProducts(){
        this.productDataShare = new zqu.ZComponentDataShare();
        this.productIDs = this.getFilteredZProductIds(quote.zqu__Currency__c, quote.zqu__StartDate__c);
        if (this.searchString != null && this.searchString != '')   this.productIds = searchProducts(this.productIDs, quote.zqu__StartDate__c);
            
        this.productDataShare.dataObject = zqu.zQuoteUtil.getProductSetController(this.productIDs, this.getProductDisplayFields(), PRODUCT_TABLE_PAGE_SIZE);
        
        if(this.rateplanIDs != null)    this.rateplanDataShare.dataObject = zqu.zQuoteUtil.getRatePlanSetController(this.rateplanIDs, getRatePlanDisplayFields(), RATEPLAN_TABLE_PAGE_SIZE);
    }
    
     public void refreshRatePlans(){
        
        final String productId = (String) selectedProductShare.dataObject;
        if(productId != null)   this.rateplanIDs = getFilteredRatePlanIds(productId, this.quote.zqu__Currency__c, this.quote.zqu__StartDate__c);    
        
        if(this.rateplanIDs != null)    this.rateplanDataShare.dataObject = zqu.zQuoteUtil.getRatePlanSetController(this.rateplanIDs, getRatePlanDisplayFields(), RATEPLAN_TABLE_PAGE_SIZE);
    }
    
    public void clearSelectedProduct(){
        selectedProductShare.dataObject = null;
    }
    
    public void clearFilters(){
        filterBrandTag = '-All-';
        filterBillingFrequency = '-All-';
        brandValue = '-None-';
        productGroupValue = '-None-';
        
        refreshProducts();
        refreshRatePlans();
    }
    
    public PageReference cancel()
    {
        return new PageReference('/'+this.quoteId);
    }
    
    public PageReference saveChargeGroup(){
        if(null != this.quote && null != this.quote.Id){
            zqu.zChargeGroup updatedChargeGroup = null;
            try {
                updatedChargeGroup = zqu.zQuoteUtil.updateChargeGroup(this.currentChargeGroup);
            } catch (zqu.ZQException e) {   ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()); ApexPages.addMessage(msg); return null; }
            
            for(Integer i =0 ; i < this.chargeGroupList.size() ; i++){
                zqu.zChargeGroup zchargeGrp = this.chargeGroupList.get(i);
                if(updatedChargeGroup.groupId == zchargeGrp.groupId)    this.chargeGroupList.set(i, updatedChargeGroup);
            }
        }
        this.editMode = false;
        return null;
    }
    public void cancelEditing(){
        this.editMode = false;
        this.selectNewProductViewMode = false;
    }
    public void editChargeGroup(){
        if(this.currentChargeGroupId != null && this.quote.Id != null){
            for(Integer i =0 ; i < this.chargeGroupList.size() ; i++){
                zqu.zChargeGroup zchargeGrp = this.chargeGroupList.get(i);
                if(this.currentChargeGroupId == zchargeGrp.groupId){
                    this.currentChargeGroup = zchargeGrp.deepclone();
                    break;
                }
            }
            this.editMode = true;
        }
    }
    public PageReference deleteChargeGroup(){
        if(this.currentChargeGroupId != null && this.quote.Id != null){
            for(Integer i =0 ; i < this.chargeGroupList.size() ; i++){
                zqu.zChargeGroup zchargeGrp = this.chargeGroupList.get(i);
                if(this.currentChargeGroupId == zchargeGrp.groupId){
                    this.currentChargeGroup = zchargeGrp;
                    zqu.zChargeGroup deletedChargeGroup = null;
                    try {
                        deletedChargeGroup = zqu.ZQuoteUtil.deleteChargeGroup(zchargeGrp);
                    } catch(zqu.ZQException e) { appendErrorMessage(e.getMessage()); return null; }
                    
                    if(deletedChargeGroup != null)  this.chargeGroupList.set(i, deletedChargeGroup);
                    else    this.chargeGroupList.remove(i);
                    
                    break;
                }
            }
        }
        return null;
    }
    
   public zqu.ZComponentDataShare selectedProductShare {
    get {
      //when select product happening, get the related rateplans
      if (null != selectedProductShare) {
        if (selectedProductShare.dataObject != null && selectedProductShare.componentActionFlag) {
          final String productId = (String) selectedProductShare.dataObject;

          //put your custom code here to retrieve the rateplan ids or the setcontroller for product rateplan
          try {
            List < ID > rateplanIDs = this.getFilteredRatePlanIds(productId, quote.zqu__Currency__c, quote.zqu__StartDate__c);
            this.rateplanDataShare.dataObject = zqu.zQuoteUtil.getRatePlanSetController(ratePlanIDs, getRatePlanDisplayFields(), RATEPLAN_TABLE_PAGE_SIZE);
            System.debug('tina dataObject = ' + selectedRatePlanShare.dataObject);
          } catch (zqu.ZQException e) { appendErrorMessage(e.getMessage()); return null; }
          
          //need to disable the extra re-write to component controller here, will set to true from component action
          selectedProductShare.componentActionFlag = false;
          selectedRatePlanShare.dataObject = null;
        } else if (selectedProductShare.dataObject == null) selectedRatePlanShare.dataObject = null;
      } else    selectedProductShare = new zqu.ZComponentDataShare();
      
      return selectedProductShare;
    }
    set;
  }

  public zqu.ZComponentDataShare selectedRatePlanShare {
    get {
      //when select rateplan happening, get the related chargegroup
      if (selectedRatePlanShare.dataObject != null && selectedRatePlanShare.componentActionFlag) {
        final String rateplanId = (String) selectedRatePlanShare.dataObject;
        System.debug('Tina componentActionFlag = ' + selectedRatePlanShare.componentActionFlag + ', ratePlanId = ' + ratePlanId);
        try {
          this.chargeGroup = zqu.zQuoteUtil.getChargeGroup(quote.Id, ratePlanID);
        } catch (zqu.ZQException e) { appendErrorMessage(e.getMessage()); return null; }
        //need to disable the extra re-write to component controller here, will set to true from component action
        selectedRatePlanShare.componentActionFlag = false;
      }
      return selectedRatePlanShare;
    }
    set;
  }
  
    public PageReference addNewChargeGroupToQuote() {
        final zqu.ZChargeGroup chargeGroup;
        try {
            chargeGroup = zqu.ZQuoteUtil.addChargeGroup(this.chargeGroup);
        } catch(zqu.ZQException e) { ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()); ApexPages.addMessage(msg); return null; }
        this.chargeGroupList.add(chargeGroup);
        this.selectNewProductViewMode = false;
        return null;
    }
    public void toSelectNewProductsView() {
        this.selectNewProductViewMode = true;
        this.rateplanDataShare = new zqu.zComponentDataShare();
        this.selectedProductShare = new zqu.zComponentDataShare();
        this.selectedRatePlanShare = new zqu.zComponentDataShare();
    }
    public String[] getProductDisplayFields() {
        return new String[] {'Name','zqu__Description__c'};
    }
    public String[] getRatePlanDisplayFields() {
        return new String[] {'Name', 'zqu__Description__c'};
    }
    
    private List<ID> getFilteredZProductIds(String zCurrency, Date zStartDate){
        
        List < zqu__ZProduct__c > products;
        List < Id > productIds = new List < Id > ();
        
        if((productGroupValue == null || productGroupValue == '-None-') && (brandValue == '-None-' || brandValue == null))
        {
            for (zqu__ProductRatePlanChargeTier__c result : [SELECT zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__zProduct__r.Id, zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__zProduct__r.zqu__deleted__c
                FROM zqu__ProductRatePlanChargeTier__c
                WHERE zqu__Currency__c = : zCurrency
                AND zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__zProduct__r.zqu__Deleted__c = false
            ]) {
            
                productIds.add(result.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__zProduct__r.Id);
            }
    
            //for (zqu__ProductRatePlanChargeTier__c result: groupedResults)  
        }
        else    productIds = getZProductIds(zCurrency);
    
        String baseSoql = 'SELECT Id FROM zqu__ZProduct__c WHERE Id IN :productIds AND zqu__Deleted__c = false AND zqu__EffectiveStartDate__c <= :zStartDate AND zqu__EffectiveEndDate__c >= :zStartDate ';
        baseSoql += ' ORDER BY Name ASC LIMIT 10000 ';
    
        products = Database.query(baseSoql);
        
        productIds = new List < Id > ();
        for (zqu__zProduct__c product: products)    productIds.add(product.Id);
    
        return productIds;
    }    
    
    //
    //My get z products, filters on a product custom field ProductGroup__c defined in Zuora and synced to SFDC
    //
    public List<ID> getZProductIds(String zCurrency)
    {
        this.selectedRatePlanShare.dataObject = null;
        selectedProductShare.dataObject = null;
        
        List<String> finalProdIds = new List<String>{};
        
        String queryString;
        
        if(productGroupValue != null && brandValue != null)
        {
            queryString = 'SELECT zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__zProduct__r.Id FROM zqu__ProductRatePlanChargeTier__c WHERE zqu__Currency__c = \'' + zCurrency +
                '\' AND zqu__Deleted__c = false AND zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__zProduct__r.ProductGroup__c = \'' + productGroupValue + 
                '\' AND zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__zProduct__r.Brand__c LIKE \'%' + brandValue +
                '%\' GROUP BY zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__zProduct__r.Id';
        }
        else if(productGroupValue != null && brandValue == null)
        {
            queryString = 'SELECT zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__zProduct__r.Id FROM zqu__ProductRatePlanChargeTier__c WHERE zqu__Currency__c = \'' + zCurrency +
                '\' AND zqu__Deleted__c = false AND zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__zProduct__r.ProductGroup__c = \'' + productGroupValue + 
                '\' GROUP BY zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__zProduct__r.Id';
        }
        else if(productGroupValue == null && brandValue != null)
        {
            queryString = 'SELECT zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__zProduct__r.Id FROM zqu__ProductRatePlanChargeTier__c WHERE zqu__Currency__c = \'' + zCurrency +
                '\' AND zqu__Deleted__c = false AND zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__zProduct__r.Brand__c LIKE \'%' + brandValue + 
                '%\' GROUP BY zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__zProduct__r.Id';
        }
            
        AggregateResult[] tempProds = new AggregateResult[0];
        
        if(!Test.isRunningTest())   tempProds = Database.query(queryString);
                                    
        for(AggregateResult prod : tempProds)   finalProdIds.add(prod.Id); 
            
        return finalProdIds;
    }
            
    private List < Id > getFilteredRatePlanIds(Id zProductId, String zCurrency, Date zStartDate) {
        
        List < ID > ratePlanIds = new List<ID>{};

        if(filterBrandTag.equals('-All-') && filterBillingFrequency.equals('-All-'))
        {
            for(zqu__ProductRatePlanChargeTier__c result : [SELECT zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Id, zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__Deleted__c
                FROM zqu__ProductRatePlanChargeTier__c
                WHERE zqu__Currency__c = : zCurrency
                AND zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__Deleted__c =  false
                AND zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__zProduct__r.Id = : zProductID
            ]) {
                ratePlanIds.add(result.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Id);
            }
            //for (zqu__ProductRatePlanChargeTier__c gr: groupedResults)  
        }
        else    ratePlanIds = getFilteredZProductRateplanIds(zProductId, zCurrency);
        
        String baseSoql = 'SELECT Id FROM zqu__ProductRatePlan__c WHERE Id IN :ratePlanIds AND zqu__Deleted__c = false AND zqu__EffectiveStartDate__c <= :zStartDate AND zqu__EffectiveEndDate__c >= :zStartDate ';
        baseSoql += ' ORDER BY Name ASC LIMIT 10000 ';
    
        List < zqu__ProductRatePlan__c > ratePlans = Database.query(baseSoql);
        ratePlanIds = new List < Id > ();
        for (zqu__ProductRatePlan__c ratePlan: ratePlans)   ratePlanIds.add(ratePlan.Id);

        return ratePlanIds;
    }
    
    public List<ID> getFilteredZProductRateplanIds(String productId, String zCurrency){
        List<ID> rateplanids = new List<ID>{};
        
        String queryString;
        
        if(filterBrandTag != '-All-' && filterBillingFrequency == '-All-')
        {
            queryString = 'SELECT zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Id FROM zqu__ProductRatePlanChargeTier__c WHERE zqu__Currency__c = \'' + zCurrency + 
                '\' AND zqu__Deleted__c = false AND zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__zProduct__r.Id = \'' + productId + '\' AND zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.BrandTag__c = \''
                + filterBrandTag + '\' GROUP BY zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Id';
        }
        else if(filterBrandTag == '-All-' && filterBillingFrequency != '-All-')
        {           
            queryString = 'SELECT zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Id FROM zqu__ProductRatePlanChargeTier__c WHERE zqu__Currency__c = \'' + zCurrency + 
                '\' AND zqu__Deleted__c = false AND zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__zProduct__r.Id = \'' + productId + '\' AND zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.BillingFrequency__c = \''
                + filterBillingFrequency + '\' GROUP BY zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Id';
        }
        else 
        {            
            queryString = 'SELECT zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Id FROM zqu__ProductRatePlanChargeTier__c WHERE zqu__Currency__c = \'' + zCurrency + 
                '\' AND zqu__Deleted__c = false AND zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__zProduct__r.Id = \'' + productId + '\' AND zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.BrandTag__c = \''
                + filterBrandTag + '\' AND zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.BillingFrequency__c = \'' + filterBillingFrequency +'\' GROUP BY zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Id';
        }
        
        AggregateResult[] ratePlans = new AggregateResult[0];
        
        if(!Test.isRunningTest())   ratePlans = Database.query(queryString);
        
        for(AggregateResult ratePlan : ratePlans)   rateplanids.add(ratePlan.Id);
      
        return rateplanids;
    }

    public String getProductName(){
        if(this.selectedProductShare.dataObject != null)
        {
            zqu__ZProduct__c product = [Select z.Name, z.Id From zqu__ZProduct__c z WHERE Id =: String.valueOf(this.selectedProductShare.dataObject) LIMIT 1];
            
            return product.Name;
        }
        
        return null;
    }
    
    public String getProductGroup(){
        if(this.selectedProductShare.dataObject != null)
        {
            zqu__ZProduct__c product = [Select z.Id, z.ProductGroup__c From zqu__ZProduct__c z WHERE Id =: String.valueOf(this.selectedProductShare.dataObject) LIMIT 1];
            
            return product.ProductGroup__c;
        }
        
        return null;
    }
    
    public String getProductSubCategory(){
        if(this.selectedProductShare.dataObject != null)
        {
            zqu__ZProduct__c product = [Select z.Id, z.ProductSubCategory__c From zqu__ZProduct__c z WHERE Id =: String.valueOf(this.selectedProductShare.dataObject) LIMIT 1];
            
            return product.ProductSubCategory__c;
        }
        
        return null;
    }
    
    public String getPriceEditable(){
        if(this.selectedProductShare.dataObject != null)
        {
            zqu__ZProduct__c product = [Select z.Id, z.PriceEditable__c From zqu__ZProduct__c z WHERE Id =: String.valueOf(this.selectedProductShare.dataObject) LIMIT 1];
            
            return product.PriceEditable__c;
        }
        
        return null;
    }

    public Boolean getIsRenderRatePlan(){
        return this.selectedProductShare.dataObject != null;
    }
    public Boolean getIsRenderChargeGroup(){
        return this.selectedRatePlanShare.dataObject != null;
    }
    public Boolean getNoMatchProduct() {
        return (null == this.productIDs || 0 == this.productIDs.size());
    }
    public Boolean getNoMatchRatePlan()
    {
        return (this.selectedProductShare.dataObject != null) && (null == this.rateplanIDs || 0 == this.rateplanIDs.size());
    }

    public List<SelectOption> getBrandTagOptions()
    {
        //Get picklist options for company size
        List<SelectOption> options = new List<SelectOption>();
        
        options.add(new selectOption('-All-', '-All-'));
        
        Schema.DescribeFieldResult fieldResult =
            zqu__ProductRatePlan__c.BrandTag__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for( Schema.PicklistEntry f : ple)  options.add(new SelectOption(f.getLabel(), f.getValue()));
               
        return options;
    }
    
    public List<SelectOption> getBillingFrequencyOptions()
    {
        //Get picklist options for company size
        List<SelectOption> options = new List<SelectOption>();
        
        options.add(new selectOption('-All-', '-All-'));
            
        Schema.DescribeFieldResult fieldResult =
            zqu__ProductRatePlan__c.BillingFrequency__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            
        for( Schema.PicklistEntry f : ple)  options.add(new SelectOption(f.getLabel(), f.getValue()));
        
        return options;
    }
    
     //
     //gets the Product Group from the org
     //
    public List<SelectOption> getProductGroupValue()
    {
        List<SelectOption> options = new List<SelectOption>();
            
        options.add(new selectOption('', '- None -'));
        
        Schema.DescribeFieldResult fieldResult = zqu__ZProduct__c.ProductGroup__c.getDescribe();
                
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    
        for( Schema.PicklistEntry f : ple)  options.add(new SelectOption(f.getLabel(), f.getValue()));
    
        return options;    
   }
   
   public List<SelectOption> getBrandValue()
   {
        List<SelectOption> options = new List<SelectOption>();    
        
        options.add(new selectOption('', '- None -'));
        
        Schema.DescribeFieldResult fieldResult = zqu__ZProduct__c.BrandPicklist__c.getDescribe();
                
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    
        for( Schema.PicklistEntry f : ple)  options.add(new SelectOption(f.getLabel(), f.getValue()));
    
        return options;    
   }
   
   private static void appendErrorMessage(String message) {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, message));
   }
}