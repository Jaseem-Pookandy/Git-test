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

trigger FirstToBillAndServEndDate on zqu__Quote__c (before insert, before update, after insert) {
    
    
    
    
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {   
        for(zqu__Quote__c quote : Trigger.new) {
            //CC-2336 - 1) User leaves the First Bill Date null and it will default to Service Start Date. 2) User sets the date it will be maintained
            if(Trigger.isInsert)
                if(quote.Deferred_Bill_Date__c == null && quote.zqu__StartDate__c != null) quote.Deferred_Bill_Date__c = quote.zqu__StartDate__c;
            
            //Removed CC-2336 - First Bill Date can be a date prior to date
            /*else if(quote.Deferred_Bill_Date__c != null && quote.zqu__StartDate__c != null)
            {
                if(quote.Deferred_Bill_Date__c.day() < System.today().day() && quote.Deferred_Bill_Date__c.month() <= System.today().month() 
                    && quote.Deferred_Bill_Date__c.year() <= System.today().year()) // QC-423 First Bill Date can't be a date before today
                    quote.Deferred_Bill_Date__c = quote.zqu__StartDate__c;
            }*/
            
            //CC-2978 - Dice Holdings business wants to recognize the contract end date as one day less than 
            //the method used by Zuora. 
            //For example: Contract Start Date of Feb 22, 2014 for a 12 month contract. 
            //Zuora's calculated contract end date = Feb 22, 2015. 
            //DHI would like that contract end date to be = Feb 21, 2015
            //So, we are subtracting 1 day from the Contract End Date here
            if(quote.Service_End_Date__c == null && quote.Contract_End_Date_Apex__c != null) quote.Service_End_Date__c = quote.Contract_End_Date_Apex__c.addDays(-1);
        }
    }

    // Set the Invoice Template Name on Quote

    if (Trigger.isAfter && Trigger.isInsert) {
        List<Invoice_Template__c> invoiceTemplates = [
            SELECT Id, Name, Invoice_Template_Id__c
            FROM Invoice_Template__c        
        ];
        
        //Map of Invoice Templates
        Map<String, String> mapInvoiceTemplates = new Map<String, String>();
        
        for(Invoice_Template__c invoiceTemplate : invoiceTemplates) {
            mapInvoiceTemplates.put(invoiceTemplate.Name.toUpperCase(), invoiceTemplate.Id);
        }
        
        List<pw_ccpro__CountryObject__c> countries = [
            SELECT Id, Name, Sub_Region1__c, Region_Energy__c 
            FROM pw_ccpro__CountryObject__c 
        ];
        
        List<String> quoteIds = new List<String>();
        
        for(zqu__Quote__c quote: Trigger.new) {
            quoteIds.add(quote.Id);
        }
        
        Map<Id, zqu__Quote__c> mapQuotes = new Map<Id, zqu__Quote__c>([
            SELECT Id, zqu__SoldToContact__r.pw_ccpro__MailingCountryLookup__r.Sub_Region1__c, zqu__SoldToContact__r.pw_ccpro__MailingCountryLookup__r.Region_Energy__c, zqu__Currency__c, zqu__SoldToContact__r.Language__c, BrandTag__c
            FROM zqu__Quote__c
            Where Id IN: quoteIds
        ]);
                
        for(zqu__Quote__c quote : mapQuotes.values()) {

            if (!Test.isRunningTest()) {
                if (((quote.zqu__SoldToContact__c != null) && (quote.BrandTag__c.startsWithIgnoreCase('efc')) && (quote.zqu__SoldToContact__r.pw_ccpro__MailingCountryLookup__c != null) && (quote.zqu__SoldToContact__r.pw_ccpro__MailingCountryLookup__r.Sub_Region1__c == 'Middle East')))     quote.InvoiceTemplateName__c = mapInvoiceTemplates.get(('eFC-MiddleEast_'               + (String)quote.zqu__SoldToContact__r.Language__c + '_' + (String)quote.zqu__Currency__c).toUpperCase());
                else if ((quote.BrandTag__c.equalsIgnoreCase('rigzone')) && (quote.zqu__SoldToContact__r.pw_ccpro__MailingCountryLookup__r.Region_Energy__c != 'AMERICAS'))                                                                                                                                        quote.InvoiceTemplateName__c = mapInvoiceTemplates.get(('Rigzone-ROW_'                  + (String)quote.zqu__SoldToContact__r.Language__c + '_' + (String)quote.zqu__Currency__c).toUpperCase());
                else if (mapInvoiceTemplates.get(((String)quote.BrandTag__c + '_' + (String)quote.zqu__SoldToContact__r.Language__c + '_' + (String)quote.zqu__Currency__c).toUpperCase()) != null)                                                                                                                quote.InvoiceTemplateName__c = mapInvoiceTemplates.get(((String)quote.BrandTag__c + '_' + (String)quote.zqu__SoldToContact__r.Language__c + '_' + (String)quote.zqu__Currency__c).toUpperCase());
            }
        }   
        
        if (!Test.isRunningTest()) update mapQuotes.values();
    }
}