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

////////////////////////////////////////////////////////////////////////////////////////////
// This was completely refactored by Byrnes on 2014.07.16 in order to conform to standards.
// All logic was pushed to the new handler class, 'zquQuoteRatePlanChargeTriggerHandler.cls'
// The poor name for this trigger will remain for the foreseeable future, sadly...
////////////////////////////////////////////////////////////////////////////////////////////

trigger RegionsQuoteRatePlanChargeTrigger on zqu__QuoteRatePlanCharge__c (before insert, before update, after insert, after update, before delete, after delete) {

	//Handler class
	zquQuoteRatePlanChargeTriggerHandler handler = new zquQuoteRatePlanChargeTriggerHandler(Trigger.isExecuting, Trigger.size);
	
	if(Trigger.isInsert && Trigger.isBefore){     
		//Handler for Before insert
	    handler.OnBeforeInsert(Trigger.new);     
	} else if(Trigger.isInsert && Trigger.isAfter){     
	    //Handler for After insert
	    handler.OnAfterInsert(Trigger.newMap);     
	} else if(Trigger.isUpdate && Trigger.isAfter){   
	    //Handler for after update trigger
	    handler.OnAfterUpdate(Trigger.oldMap, Trigger.newMap);    
	} else if(Trigger.isUpdate && Trigger.isBefore){   
	    //Handler for before update trigger
	    handler.OnBeforeUpdate(Trigger.newMap, Trigger.oldMap);     
	} else if (Trigger.isDelete && Trigger.isBefore) {     
      	//Handler for before Delete trigger - not built yet, just stubbed.
      	//handler.OnBeforeDelete(Trigger.oldMap);    
    } else if (Trigger.isDelete && Trigger.isAfter) {     
      	//Handler for After Delete trigger - not built yet, just stubbed.
      	//handler.OnAfterDelete(Trigger.oldMap); 
    }
}