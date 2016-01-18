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

trigger GlobalDealTriggerForQuote on zqu__Quote__c (before update) {
	
	//REMOVED AS OF 2014.1.09 by Byrnes!
	//Put where it belongs in the zquQuoteTriggerHandler class.
	
	/*if(System.isFuture()) return;
	
	Set<String> quoteIds = new Set<String>();
	
	for (zqu__Quote__c quote : Trigger.new){
		if (quote.IsFutureContext__c) {
        	quote.IsFutureContext__c = false;
         }
         else {	
			quoteIds.add(quote.Id);			
		}
	}
	System.Debug('quoteIds: ' + quoteIds);
	
	//.... For New Subscription Quotes: .......
		
	// Quote Charge: Query for Sales Rep, Country with matching Quote Ids, where Subscription Type is 'New Subscription'  ....................//
	
	List<zqu__QuoteCharge__c> quoteChrgList = new List<zqu__QuoteCharge__c>();
	
	quoteChrgList = [
		SELECT Id, Name, Sales_Representative__c, Country__c, zqu__Quote__r.Global_Deal__c, zqu__Quote__r.Discount__c, zqu__Quote__r.zqu__Previewed_Discount__c 
		from zqu__QuoteCharge__c 
		where zqu__Quote__r.Id IN:quoteIds AND zqu__Quote__r.zqu__SubscriptionType__c = 'New Subscription'
	];
	
	        	
	for (zqu__Quote__c myQuote : Trigger.new){	
		
		// Update discount field on quote:
		if(myQuote.zqu__Previewed_Discount__c != myQuote.Discount__c){
			myQuote.Discount__c = myQuote.zqu__Previewed_Discount__c;
		}
		
		// Global Deal:
		if (quoteChrgList.size() > 0){	    
				
			for (zqu__QuoteCharge__c quoteChrg : quoteChrgList){
				
				// Look for Global Deal 	
			    if(quoteChrg.Country__c != null && quoteChrg.Sales_Representative__c != null){
					if(quoteChrgList[0].Country__c != quoteChrg.Country__c){		
						for (zqu__QuoteCharge__c qc : quoteChrgList){
															
							if(quoteChrgList[0].Sales_Representative__c != qc.Sales_Representative__c){
								myQuote.Global_Deal__c = true;
							    System.debug('Global Deal: '+myQuote.Global_Deal__c);
							    break; //Global Deal has been found don't continue iterating
							}
							else{
								myQuote.Global_Deal__c = false;
								System.debug('Global Deal: '+myQuote.Global_Deal__c);																
							}
						}
						break;
					} 
					else {
						myQuote.Global_Deal__c = false;
						System.debug('Global Deal: '+myQuote.Global_Deal__c);					
					}				
			     } 
			     else {
			     	myQuote.Global_Deal__c = false;
			     	System.debug('Global Deal: '+myQuote.Global_Deal__c);
			     }       			
			 }
			 System.debug('Global Deal: '+myQuote.Global_Deal__c);
		}
	*/			
		//....... For Amendment Quotes:  ..............
		/*else if(myQuote.zqu__SubscriptionType__c == 'Amend Subscription' || myQuote.zqu__SubscriptionType__c == 'Renew Subscription'){
    	
    		if(!myQuote.IsFutureContext__c){
                               
        		myQuote.IsFutureContext__c = true;
            	ClassForGlobalDealTriggerForQuote gdtfq = new ClassForGlobalDealTriggerForQuote(String.valueOf(myQuote.Id));
			}
		}*/
	//}  
}