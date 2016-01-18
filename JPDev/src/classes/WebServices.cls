/***************************************************************************
// (c) 2013 Doextra CRM Solutions
//
// Description    : Class that contains all of the public webService methods needed
//                  To execute custom code on button clicks.
//                  
// Sep 27th, 2013 : Byrnes
//***************************************************************************/

global class WebServices {

    WebService static string CloseCloneTask(string taskId) {        
        //retrieve the existing Task...
        Task t = [SELECT ActivityDate, Subject, Type__c, Brand__c, OwnerId, WhatId, WhoId, Status, Description, Strategic_Level_Engagement__c, Priority, Id FROM Task WHERE Id = :taskId LIMIT 1];
        
        t.Status = 'Completed';
        update t;
        
        Task newTask = new Task();
        
        //These fields are for validation, etc.  Not specifically requested by the business.
        //newTask.ActivityDate = DateTime.now().date();
        newTask.Status = 'Not Started';
        
        //The following fields are specific to the business' requirements.
        newTask.Subject = t.Subject;
        newTask.Type__c = t.Type__c;
        newTask.Brand__c = t.Brand__c;
        newTask.OwnerId = t.OwnerId;
        newTask.WhatId = t.WhatId;
        newTask.WhoId = t.WhoId;        
        newTask.Priority = t.Priority;
        newTask.Description = t.Description;
        newTask.Strategic_Level_Engagement__c = t.Strategic_Level_Engagement__c;
        
        insert newTask;     
        return newTask.Id;
    }
    
    // string 'action' will either be 'set' or 'clear' indicating whether 
    WebService static string SetABPrimaryRecipient(string action, string contactID, string brand, string accountID) {
        Account_Brand__c ab = [SELECT Id, Brand_Picklist__c, Primary_Recipient__c FROM Account_Brand__c WHERE Account__c = :accountId AND Brand_Picklist__c = :brand];

        if (action == 'set') ab.Primary_Recipient__c = contactID;
        if (action == 'clear') ab.Primary_Recipient__c = null;

        update ab;
        return null;
    }   

    //The string returned will be the Id of the inserted payment link object OR the error code.
    WebService static String CreatePaymentLink(String opportunityId, String contactId, String reason, String caseNotes, String addedEmailText, Boolean forceAutoPayOff, Boolean contactBelongsToChannelPartnerAccount) {

        String result = null;

        //Reason is a picklist field that will default to 'Docusign Quote' if null or empty.
        if (reason == null || reason == '') reason = 'Docusign Quote';

        if (opportunityId == null || opportunityId == '') return 'Error 001: Invalid Opportunity Id; It is null or blank.';
        if (opportunityId.length() != 15 && opportunityId.length() != 18) return 'Error 003: Invalid Opportunity Id; The length is not 15 or 18 digits. Passed Id: ' + opportunityId;
        if (!opportunityId.startsWith('006')) return 'Error 006: Invalid Opportunity Id; It does not begin with 006. Passed Id: ' + opportunityId;

        if (reason != 'For Entry on Behalf of Customer') {
            if (contactId == null || contactId == '') return 'Error 011: Invalid Contact Id; It is null or blank.';
            if (contactId.length() != 15 && contactId.length() != 18) return 'Error 013: Invalid Contact Id; The length is not 15 or 18 digits. Passed Id: ' + contactId;
            if (!contactId.startsWith('003')) return 'Error 016: Invalid Contact Id; It does not begin with 003. Passed Id: ' + contactId;            
        }
        else contactId = null;  //No contact when we're doing this on behalf of the user

        Payment_Link__c newLink = new Payment_Link__c();
        newLink.Opportunity__c = opportunityId;
        newLink.Contact__c = contactId;
        newLink.Reason__c = reason;
        newLink.AutoPay_Off__c = forceAutoPayOff;

        if (contactBelongsToChannelPartnerAccount) newLink.Link_Created_For__c = 'Sold By Partner';
        else newLink.Link_Created_For__c = 'Customer';

        if (caseNotes != null) newLink.Case_Description__c = caseNotes;
        if (addedEmailText != null) newLink.Additional_Email_Text__c = addedEmailText;

        Database.SaveResult sr = Database.insert(newLink);

        if (!sr.isSuccess()) return 'Error 101: Error inserting new Payment Link.';
        else result = newLink.Id;
        
        return result;
    }
}