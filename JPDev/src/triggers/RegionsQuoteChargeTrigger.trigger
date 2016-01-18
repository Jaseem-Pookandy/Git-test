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
 
trigger RegionsQuoteChargeTrigger on zqu__QuoteCharge__c (before insert, before update){
	
	//Commented all this out as it was moved to zquQuoteChargeTriggerHandlerc.cls
	//as part of completing Jira CC-3055
	
/*	Set<String> quoteChrgCountries = new Set<String>();
	Set<String> quoteIds = new Set<String>();
	
	for(zqu__QuoteCharge__c quoteCharge: Trigger.new) {
		quoteChrgCountries.add(quoteCharge.Country__c);
		quoteIds.add(quoteCharge.zqu__Quote__c);
	}
		
	List<pw_ccpro__CountryObject__c> countryList = [
		Select Id, Name, Region__c, Region_Energy__c, Sub_Region1__c, Sub_Region2__c
		From pw_ccpro__CountryObject__c
		Where Name IN: quoteChrgCountries
	];
	
	List<zqu__QuoteCharge__c> quoteChrgList = [
		SELECT Id, Sales_Representative__c, Country__c, zqu__Quote__r.Global_Deal__c 
		from zqu__QuoteCharge__c 
		where zqu__Quote__c IN:quoteIds
	];
	
	List<zqu__Quote__c> quoteList = [Select Id, Global_Deal__c from zqu__Quote__c where Id IN:quoteIds];
		
	for (zqu__QuoteCharge__c qc : Trigger.new){
				
		// Set the country Regions and Sub-Regions
		for (pw_ccpro__CountryObject__c country : countryList){
			
			if(qc.Country__c == country.Name) {
				if(country.Region__c != null){
					qc.Region__c = country.Region__c;
				}
								
				if(country.Region_Energy__c != null){
					qc.EnergyRegion__c = country.Region_Energy__c;
				}
								
				if(country.Sub_Region1__c != null){
					qc.SubRegion1__c = country.Sub_Region1__c;
				}
								
				if(country.Sub_Region2__c != null){
					qc.SubRegion2__c = country.Sub_Region2__c;
				}
			}
		}
		
		if (Trigger.isUpdate){
			// To update Global Deal on the Quote when the Country/Sales Rep fields have been changed on a Quote Charge:
			boolean tempGlobalDeal = false;
			
			if (quoteChrgList.size() > 0){			
				for (zqu__QuoteCharge__c quoteChrg : quoteChrgList){		
					// Look for Global Deal 	
				    if(quoteChrg.Country__c != null && quoteChrg.Sales_Representative__c != null){
						if(quoteChrgList[0].Country__c != quoteChrg.Country__c){		
							for (zqu__QuoteCharge__c myQC : quoteChrgList){															
								if(quoteChrgList[0].Sales_Representative__c != myQC.Sales_Representative__c){
									tempGlobalDeal = true;
								    break; //Global Deal has been found don't continue iterating
								}
								else{
									tempGlobalDeal = false;																
								}
							}
							break;
						} 
						else {
							tempGlobalDeal = false;									
						}				
				     } 
				     else {
				     	tempGlobalDeal = false;			     	
				     }       			
				 }
				 System.Debug(tempGlobalDeal);
				 for (zqu__Quote__c quote : quoteList){
					 if (quote.Global_Deal__c != tempGlobalDeal){
					 	System.debug('Global Deal: '+ quote.Global_Deal__c);
					 	quote.Global_Deal__c = tempGlobalDeal;
					 	update quote;
					 	System.debug('Global Deal: '+ quote.Global_Deal__c);	
					 }
				 }
			}			 
		}// End of Global Deal section			
	} */
}