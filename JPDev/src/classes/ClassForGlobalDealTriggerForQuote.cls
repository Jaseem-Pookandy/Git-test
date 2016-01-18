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

//Shawn Xuereb: This will be used in a future release for amendments. Please don't delete.
public with sharing class ClassForGlobalDealTriggerForQuote {

    //byrnes - for code coverage
    public ClassForGlobalDealTriggerForQuote() {
        
    }

    //... Set Global Deal field for Amendments.....
/*    
    public ClassForGlobalDealTriggerForQuote(String quoteId) {
        updateGlobalDeal(quoteId);
    }
  
    
    @future(callout=true)
    public static void updateGlobalDeal(String quoteId){
        System.Debug('AB: quote Id: ' + quoteId);
        zqu__Quote__c quote = [
                                SELECT Id, Global_Deal__c, zqu__Opportunity__r.AccountId 
                                FROM zqu__Quote__c 
                                WHERE Id =:quoteId
        ];
        System.Debug('AB: quote: ' + quote);
                          
        // Query the new charges for Sales Rep, Country, where SubscriptionType is Amend Subscription.....//                    
        List<zqu__QuoteRatePlanCharge__c> qrpcList = [SELECT Id, Name, Sales_Representative__c, Country__c  
                                                      FROM zqu__QuoteRatePlanCharge__c 
                                                      WHERE zqu__QuoteRatePlan__r.zqu__Quote__c =: quoteId
        ];//AND zqu__QuoteRatePlan__r.zqu__Quote__r.zqu__SubscriptionType__c = 'Amend Subscription'
        System.Debug('AB: qrpcList size: '+qrpcList.size());
        System.Debug('SX: qrpcList: '+ qrpcList);
        
        //....For all existing charge groups................//      
        zqu.GlobalCustomFieldDefinition.CHARGE_FIELDS = new Set<String> {'Country__c', 'Notes__c', 'Event__c', 'ServiceStart__c', 'ServiceEnd__c', 'Sales_Representative__c'};
        zqu.GlobalCustomFieldDefinition.QUOTE_FIELDS = new Set<String> {'Global_Deal__c'};
        
        // Get all existing charge groups
        List<zqu.zChargeGroup> existingChrgGrpList = new List<zqu.zChargeGroup>();
        if (!Test.isRunningTest()){
        	existingChrgGrpList = zqu.zQuoteUtil.getChargeGroups(quoteId);                                                   
        	System.Debug('existingChrgGrpList: '+ existingChrgGrpList);
        }
        boolean tempGlobalDeal;
        
	    boolean countryFlag = false; //Used to determine Global Deal
	    boolean salesRepFlag = false; //Used to determine Global Deal
        
        if(existingChrgGrpList.size() > 0){     
                                            
	    	//List of Old Amendment Charges            
	        List<Zuora__SubscriptionProductCharge__c> listOldAmendCharges = getSubscriptionCharge(quote.zqu__Opportunity__r.AccountId);
	        System.Debug('listOldAmendCharges: ' + listOldAmendCharges);
            
            for(zqu.zChargeGroup existingChargeGroup : existingChrgGrpList) {
            	//Ignore if it is has been removed (groupType = 6)
            	if(existingChargeGroup.groupType != 6) {                                                           
                    
            		// When Amendment Type is original (groupType 3) or update (groupType 5):
                    if(existingChargeGroup.groupType == 3 || existingChargeGroup.groupType == 5 ){
                    		
                    	//List<zqu.zCharge> existingChrgsList = existingChargeGroup.zCharges;
                    	//System.Debug('existing charges: ' + existingChrgsList);
                    		
                    	// Go through the old charges first to find Global Deal:
                    	for(Zuora__SubscriptionProductCharge__c oldCharge : listOldAmendCharges){
                    		for(zqu.zCharge existingCharge : existingChargeGroup.zCharges){
                    			
                    			if(oldCharge.Zuora__Zuora_Id__c  == existingCharge.getQuoteRatePlanChargeZuoraId()){                    			
                    				
		                            if(oldCharge.Country__c != null){
		                            	
		                                if(listOldAmendCharges[0].Country__c != oldCharge.Country__c) {
		                                    countryFlag = true;
		                                } else {
		                                	countryFlag = false;
		                                }
		                            }
		                            if(oldCharge.Sales_Representative__c != null){
		                            	System.debug('SX listOldAmendCharges' + listOldAmendCharges);
		                            	System.debug('SX listOldAmendCharges[0].Sales_Representative__c' + listOldAmendCharges[0].Sales_Representative__c);
		                            	System.debug('SX oldCharge' + oldCharge.Sales_Representative__c);
		                                if(listOldAmendCharges[0].Sales_Representative__c != oldCharge.Sales_Representative__c){
		                                    salesRepFlag = true;
		                                } else {
		                                	salesRepFlag = false;
		                                }
		                            }
		                            
		                            if(countryFlag && salesRepFlag) {
		                                tempGlobalDeal = TRUE;
		                                break;
		                            }
		                            else{                    	
		                    			// Look through the qrpc's & old charges to find Global Deal
		                    			if(qrpcList.size() > 0){
			                    			for (zqu__QuoteRatePlanCharge__c qrpc : qrpcList){							
									    	
									    		if(qrpc.Country__c != null && qrpc.Sales_Representative__c != null){
												
													if((qrpcList[0].Country__c != qrpc.Country__c) || (qrpcList[0].Country__c != oldCharge.Country__c)){
														countryFlag = true;
													}		
																						
													if((qrpcList[0].Sales_Representative__c != qrpc.Sales_Representative__c) || (qrpcList[0].Sales_Representative__c != oldCharge.Sales_Representative__c)){
														salesRepFlag = true;
													}
													
													if(countryFlag && salesRepFlag) {
			                                			tempGlobalDeal = TRUE;
			                                			break;	                                
		                            				}   			
									 				else{
										 				tempGlobalDeal = TRUE;
									 				}
			                    				}else{
			                    					tempGlobalDeal = FALSE;
									    		}
		                    				}
		                    				break;
		                    			
		                    			}else{
		                    				tempGlobalDeal = FALSE;
		                    			}
	                    			}
                    			}
                    		}
                    	}
                    }
                }
            }
        }
        	
        if(quote.Global_Deal__c != tempGlobalDeal) {            
            quote.Global_Deal__c = tempGlobalDeal;
            if(!Test.isRunningTest()){
            	update quote;
            }
        }
        
	} // end of updateGlobalDeal method
        
        
     
        
    //THIS SHOULD BE A GLOBAL METHOD
    //Returns a map of the subscription charges 
    public static List<Zuora__SubscriptionProductCharge__c> getSubscriptionCharge(String sfdcAccountId){
        
        List<Zuora__Subscription__c> subscriptions = new List<Zuora__Subscription__c>();
        
        subscriptions = [SELECT id, Zuora__Account__c 
          FROM Zuora__Subscription__c
          WHERE Zuora__Account__c = :sfdcAccountId];
        
        List<Id> subIds = new List<Id>();
        
        for(Zuora__Subscription__c sub : subscriptions){
            subIds.add(sub.Id);
        }
        List<Zuora__SubscriptionProductCharge__c> charges = [SELECT Id, Zuora__Zuora_Id__c, Country__c, Notes__c, EventID__c, ServiceStart__c, ServiceEnd__c, Sales_Representative__c
            FROM  Zuora__SubscriptionProductCharge__c
            WHERE Zuora__Subscription__c IN :subIds];
        
        return charges;
    }*/
}