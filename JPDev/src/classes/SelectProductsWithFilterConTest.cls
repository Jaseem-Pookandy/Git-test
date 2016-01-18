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

@isTest
private class SelectProductsWithFilterConTest {

  @isTest
  private static void negativeTest() {
    SelectProductsWithFilterCon con;
    con = new SelectProductsWithFilterCon(new ApexPages.StandardController(new zqu__Quote__c()));
    System.assert(Apexpages.hasMessages());
  }

  @isTest
  private static void selectProduct() {

    zqu__ZProduct__c product = TestDataSetup.prepareProductCatalog();
    Id productId = product.Id;
    System.debug('SX: productID' + productId);
	
    Account acct = new Account(Name = 'TestAccount');
    acct.BillingStreet = '4 fun street';
    acct.BillingState = 'Georgia';
    acct.BillingCountry = 'USA';
    acct.BillingCity = 'Atlanta';
    acct.BillingPostalCode = '30324';
    insert acct;
    List<Contact> cList = TestUtils.createContacts(acct, 3);
    insert cList;
    
    Opportunity oppty = new Opportunity(Name = 'TestOppty', AccountId = acct.Id, StageName = 'Prospect', CloseDate = Date.parse('12/8/2013'));
    insert oppty;
    zqu__Quote__c quote = new zqu__Quote__c(Name = 'TestQuote', zqu__Opportunity__c = oppty.Id, zqu__Currency__c = 'USD', zqu__StartDate__c = Date.today(), zqu__BillToContact__c = cList[0].Id, zqu__SoldToContact__c = cList[0].Id);
    insert quote;

	//Test.startTest();
	
    SelectProductsWithFilterCon con = new SelectProductsWithFilterCon(new ApexPages.StandardController(quote));

    System.assert(con.selectedProductShare != null && con.selectedProductShare.dataObject == null);
    System.assert(con.selectedRatePlanShare != null && con.selectedRatePlanShare.dataObject == null);

    zqu.ZComponentDataShare productShare = new zqu.zComponentDataShare();
    zqu.ZComponentDataShare ratePlanShare = new zqu.zComponentDataShare();

    List < zqu__ProductRatePlan__c > ratePlans = [SELECT id FROM zqu__ProductRatePlan__c WHERE zqu__zProduct__c = : productId LIMIT 1];
    zqu__ProductRatePlan__c ratePlan = ratePlans.get(0);

    productShare.dataObject = String.valueOf(productId);
    ratePlanShare.dataObject = String.valueOf(ratePlan.Id);

    con.selectedProductShare = productShare;
    con.selectedRatePlanShare = ratePlanShare;

    System.assertEquals(true, con.getIsRenderChargeGroup());
    System.assertEquals(false, con.getNoMatchProduct());
    //System.assertEquals('/' + quote.Id, con.navigateBack().getUrl());

    con.addNewChargeGroupToQuote();

    con.currentChargeGroupId = con.chargeGroup.groupId;

    con.editChargeGroup();
    System.assert(true == con.editMode);

    //con.saveChargeGroup();

    con.deleteChargeGroup();

    con.cancelEditing();
    System.assert(false == con.editMode);

    System.assertEquals(true, con.getIsRenderRatePlan());

    con.toSelectNewProductsView();
    System.assert(con.selectedProductShare.dataObject == null);
    System.assert(con.selectedRatePlanShare.dataObject == null);

    //con.searchString = 'random search';
    con.refreshProducts();
    System.assert(true, con.getNoMatchProduct());
    
    //Test.stopTest();
  }
  
  @isTest
  private static void cancelFilledOutProduct() {

    zqu__ZProduct__c product = TestDataSetup.prepareProductCatalog();
    Id productId = product.Id;

    Account acct = new Account(Name = 'TestAccount');
    acct.BillingStreet = '4 fun street';
    acct.BillingState = 'Georgia';
    acct.BillingCountry = 'USA';
    acct.BillingCity = 'Atlanta';
    acct.BillingPostalCode = '30324';
    insert acct;
    List<Contact> cList = TestUtils.createContacts(acct, 3);
    insert cList;
    
    Opportunity oppty = new Opportunity(Name = 'TestOppty', AccountId = acct.Id, StageName = 'Prospect', CloseDate = Date.parse('12/8/2013'));
    insert oppty;
    zqu__Quote__c quote = new zqu__Quote__c(Name = 'TestQuote', zqu__Opportunity__c = oppty.Id, zqu__Currency__c = 'USD', zqu__StartDate__c = Date.today(), zqu__BillToContact__c = cList[0].Id, zqu__SoldToContact__c = cList[0].Id);
    insert quote;

	Test.startTest();
    
    SelectProductsWithFilterCon con = new SelectProductsWithFilterCon(new ApexPages.StandardController(quote));

    System.assert(con.selectedProductShare != null && con.selectedProductShare.dataObject == null);
    System.assert(con.selectedRatePlanShare != null && con.selectedRatePlanShare.dataObject == null);

    zqu.ZComponentDataShare productShare = new zqu.zComponentDataShare();
    zqu.ZComponentDataShare ratePlanShare = new zqu.zComponentDataShare();

    List < zqu__ProductRatePlan__c > ratePlans = [SELECT id FROM zqu__ProductRatePlan__c WHERE zqu__zProduct__c = : productId LIMIT 1];
    zqu__ProductRatePlan__c ratePlan = ratePlans.get(0);

    productShare.dataObject = String.valueOf(productId);
    ratePlanShare.dataObject = String.valueOf(ratePlan.Id);

    con.selectedProductShare = productShare;
    con.selectedRatePlanShare = ratePlanShare;
    
    con.getBillingFrequencyOptions();
    con.getBrandTagOptions();

    System.assertEquals(true, con.getIsRenderChargeGroup());
    System.assertEquals(false, con.getNoMatchProduct());
    
    con.getNoMatchRatePlan();
    con.getProductGroupValue();
    con.getProductSubCategory();
    con.getProductGroup();
    con.getProductName();
    con.searchString = 'Test';
    
    con.productGroupValue = 'Test';
    
    con.refreshRatePlans();
    con.clearSelectedProduct();
    con.clearFilters();
    con.cancel();
    //System.assertEquals('/' + quote.Id, con.navigateBack().getUrl());
    
    Test.stopTest();
  }  
}