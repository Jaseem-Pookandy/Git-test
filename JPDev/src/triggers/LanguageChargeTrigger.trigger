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

trigger LanguageChargeTrigger on zqu__QuoteRatePlanCharge__c (before insert) {

    
    	Set<String> ids = new Set<String>();
          
    	for(zqu__QuoteRatePlanCharge__c qrpChrg : Trigger.new)
    	{
         	if(qrpChrg.zqu__ProductRatePlanChargeZuoraId__c != null){
         	
         		ids.add(qrpChrg.zqu__ProductRatePlanChargeZuoraId__c);
                 	
         	}                       
    	}
    	System.Debug('ids: '+ids);    

		//....... Get Languages and ZuoraIds from Product Rate Plan Charge...
 
		List<zqu__ProductRatePlanCharge__c> listPrpcs = [
			SELECT Id, zqu__ZuoraId__c, DutchChargeName__c, EnglishChargeName__c, FrenchChargeName__c, GermanChargeName__c, ItalianChargeName__c, RussianChargeName__c, SpanishChargeName__c, SimplifiedChineseChargeName__c 
			FROM zqu__ProductRatePlanCharge__c 
			WHERE zqu__ZuoraId__c IN:ids AND zqu__Deleted__c = false
		];
    
    	System.Debug('listPrpcs: ' + listPrpcs);
    
	
		if(listPrpcs.size() > 0){	
			for(zqu__QuoteRatePlanCharge__c qrpChrg : Trigger.new){
				
				System.Debug('qrpChrg: '+qrpChrg);
					  							
				for (zqu__ProductRatePlanCharge__c prodRatePlanChrg : listPrpcs){
																					
					if(prodRatePlanChrg.DutchChargeName__c != null){
						qrpChrg.DutchChargeName__c = prodRatePlanChrg.DutchChargeName__c;
					}
					if(prodRatePlanChrg.EnglishChargeName__c != null){
						qrpChrg.EnglishChargeName__c = prodRatePlanChrg.EnglishChargeName__c;
					}
					if(prodRatePlanChrg.FrenchChargeName__c != null){
						qrpChrg.FrenchChargeName__c = prodRatePlanChrg.FrenchChargeName__c;
					}
					if(prodRatePlanChrg.GermanChargeName__c != null){
						qrpChrg.GermanChargeName__c = prodRatePlanChrg.GermanChargeName__c;
					}
					if(prodRatePlanChrg.ItalianChargeName__c != null){
						qrpChrg.ItalianChargeName__c = prodRatePlanChrg.ItalianChargeName__c;
					}	
					if(prodRatePlanChrg.RussianChargeName__c != null){
						qrpChrg.RussianChargeName__c = prodRatePlanChrg.RussianChargeName__c;
					}					
					if(prodRatePlanChrg.SpanishChargeName__c != null){
						qrpChrg.SpanishChargeName__c = prodRatePlanChrg.SpanishChargeName__c;
					}
					if(prodRatePlanChrg.SimplifiedChineseChargeName__c != null){
						qrpChrg.SimplifiedChineseChargeName__c = prodRatePlanChrg.SimplifiedChineseChargeName__c;
					}
				
		    	}
		    	System.Debug('qrpChrg: '+qrpChrg);
					
			}
		}			
	
	
	
	
}