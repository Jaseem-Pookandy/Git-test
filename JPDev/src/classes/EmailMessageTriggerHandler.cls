/***************************************************************************
// (c) 2012 Appirio, Inc.
//
// Description    : Class that contains all of the functionality called by the 
//                  EmailMessageTrigger. All contexts should be in this class.
//                  
// Feb 11th, 2012  :  Naresh Ojha (Appirio Offshore)
//***************************************************************************/
public with sharing class EmailMessageTriggerHandler {
  private boolean m_isExecuting = false;  
  private integer BatchSize = 0;
  private static final String CASE_AUTORESPONSE_NAME = 'Case Auto Response';
  private static final String DUMMY_EMAIL_CREATE_IN_PROGRESS = 'Dummy_Email_Create_In_Progress';
  private static final String UNKNOWN_BRAND = 'No_D2BM_Found';
  
  //Constructor
  public EmailMessageTriggerHandler(boolean isExecuting, integer size){
    m_isExecuting = isExecuting;
    BatchSize = size;
  }

  //On After insert trigger method 
  public void OnBeforeInsert (List<EmailMessage> newList) {   
  }  
  
  //On After insert trigger method 
  public void OnAfterInsert (List<EmailMessage> newList) {   

   ExtractBrandAssignment(newList);  //CC-3210
   SendAutoResponse(newList);
  }  

// Determine the brand based upon the Domain to brand object data
private void ExtractBrandAssignment(List<EmailMessage> newlist){
//  complete rewrite - CA - CC-3210
//
    List <ID> CaseIDs = new List<ID>();
    Map <String, String> db = new Map<String, String> (); 


    for (Domain_to_Brand_Map__c db_src: [Select Domain_Name__c, Brand__r.Name from Domain_to_Brand_Map__c order by Domain_Name__c] ) {
      if (!db.containsKey(db_src.Domain_Name__c.toLowerCase())) {           // Domain_name is the key and it is unique already.
          db.put(db_src.Domain_Name__c.toLowerCase(), db_src.Brand__r.Name);
        }
      }

    // find all of the cases associated to these emails
  for (EmailMessage em : newList) {
    if ((em.ParentId <> null) && (em.Incoming) && em.ToAddress <> null) {
      CaseIDs.add(em.ParentId);
    }
  }

// Get all of the cases that I need to update
 Map<ID, Case> CaseList = new Map<ID, Case>([Select id, Brand__c, Recipient__c, Domain__c, Inbound_Email_Address__c from Case where ID in :CaseIDs]);

  boolean updated_needed = false;
  String singleEmail;
//  The process is to set the case' inbound email address 
//  Then strip the to_address into left (recipient) and right (domain) parts.
//  Set the brand based upon the domain.
//
for (EmailMessage em : newList) {
      if (CaseList.containsKey(em.ParentId)) {
        updated_needed = true;              

        singleEmail = em.ToAddress;
        if (singleEmail.containsAny(',;')) {
          singleEmail = singleEmail.left(singleEmail.indexOfAny(',;'));
        }
        CaseList.get(em.ParentId).Inbound_Email_Address__c = singleEmail;

        String[] emailParts = singleEmail.toLowerCase().split('@');
        if (emailParts[1] <> null) {
          CaseList.get(em.ParentId).Recipient__c = emailParts[0]; 
          CaseList.get(em.ParentId).Domain__c = emailParts[1];
          if (db.containsKey(emailParts[1])) { 
              CaseList.get(em.ParentId).Brand__c = db.get(emailParts[1]); 
          }
          else {
            CaseList.get(em.ParentId).Brand__c = UNKNOWN_BRAND;
          }
        }
      }
    }  
  if (updated_needed) {
//        Database.DMLOptions dlo = new Database.DMLOptions();               
//        dlo.EmailHeader.triggerAutoResponseEmail = true;
//        Database.update(CaseList.values(), dlo);
    update CaseList.values(); 
  }
}
 
  //byrnes, new 2013.08.09
  public static boolean CaseAutoResponseIsEnabled()
  {
    GlobalFlags__c gf = [SELECT Enabled__c FROM GlobalFlags__c WHERE Name = :CASE_AUTORESPONSE_NAME LIMIT 1];
    
    if (gf == null) return true;    
    if (gf.Enabled__c == false) return false;
    
    return true;
  } 
  
  //I-45640
  //CC-3210 - major rewrite of the function.
  private void SendAutoResponse (List<EmailMessage> emList) {
     
    //byrnes - to allow for global disabling...
    if (!CaseAutoResponseIsEnabled()) return;
    
    Set<String> caseIdSet = new Set<String>();         
    //Adding cases to update.
    for (EmailMessage em : emList) {
      if (em.ParentId <> null && !caseIdSet.contains(em.ParentId) && (em.Incoming == true)) {
        caseIdSet.add(em.ParentId);
      }
    }

 //  if there really wasn't anything here, just leave.
    if (caseIdSet.size() == 0) return;
   
    //byrnes - CC-2222
    List<Group> junkSpamList = [SELECT Id FROM Group WHERE Name = 'Email-SPAM/JUNK'];
    Set<Id> junkSpamQueueIDs = new Set<Id>();

    for (Group g : junkSpamList) {
      junkSpamQueueIDs.add(g.Id);
    }

  
    List<Case> newList = [SELECT   c.Contact.Email, 
                            c.isCSR_Assignment_Found__c, 
                            c.User_Group__c, 
                            c.Type__c, 
                            c.SystemModstamp, 
                            c.SuppliedPhone, 
                            c.SuppliedName, 
                            c.SuppliedEmail, 
                            c.SuppliedCompany, 
                            c.Subject, 
                            c.Status, 
                            c.Reason_Code__c, 
                            c.Reason, 
                            c.Queue_Owned_Indicator__c, 
                            c.Product_User__c, 
                            c.Priority, 
                            c.Parent_Case__c, 
                            c.ParentId, 
                            c.OwnerId, 
                            c.Origin, 
                            c.LastModifiedDate, 
                            c.LastModifiedById, 
                            c.IsEscalated, 
                            c.IsDeleted, 
                            c.IsClosed, 
                            c.Id, 
                            c.HasSelfServiceComments, 
                            c.HasCommentsUnreadByOwner, 
                            c.Description, 
                            c.CurrencyIsoCode, 
                            c.CreatedDate, 
                            c.CreatedById, 
                            c.ContactId, 
                            c.ClosedDate, 
                            c.Case_Queue_Region__c, 
                            c.Case_Age__c, 
                            c.CaseNumber, 
                            c.Brand__c, 
                            c.Assign_to_CSR__c, 
                            c.Account_Brand__c, 
                            c.AccountId, 
                            c.Inbound_Email_Address__c 
                          FROM Case c 
                          WHERE Id IN :caseIdSet AND OwnerId NOT IN :junkSpamQueueIDs];
    
    Map<String, CaseAutoResponseRule__c> responseRuleMap = new Map<String, CaseAutoResponseRule__c>();
    Set<String> emailTemplateIDSet = new Set<String>();
    Set<String> emailAddressesToIgnore = new Set<String>(); //byrnes
    Map<String, EmailTemplate> emailTemplateName_IdMap = new Map<String, EmailTemplate>();
    Map<String, Document> brandLogoInfo_Map = new Map<String, Document>();
    Set<String> brandSet = new Set<String>();
    CaseAutoResponseRule__c currentRule;
//  String letterhead;
    String body;
//  String DocumentID;
    
    // Sender email is really the Inbound Email Address from the customer or candidate    
    for (CaseAutoResponseRule__c rr : [SELECT SortOrder__c, SenderName__c, 
                                               SenderEmail__c, ReplyToEmail__c, 
                                               Name, EmailTemplate__c, 
                                               CaseOrigin__c, Enabled__c, 
                                               Brand__c, ID 
                                               FROM CaseAutoResponseRule__c Where Enabled__c = true Order By SortOrder__c] ) {

        if (!responseRuleMap.containsKey(rr.Brand__c + '_' + rr.CaseOrigin__c + '_' + rr.SenderEmail__c)) responseRuleMap.put(rr.Brand__c + '_' + rr.CaseOrigin__c + '_' + rr.SenderEmail__c, rr);
        if (rr.Brand__c <> null) brandSet.add(rr.Brand__c);
        emailTemplateIDSet.add(rr.EmailTemplate__c);
        emailAddressesToIgnore.add(rr.ReplyToEmail__c);
    }
    for (EmailTemplate et : [SELECT ID, DeveloperName, HtmlValue, BrandTemplateId, Subject FROM EmailTemplate WHERE DeveloperName IN: emailTemplateIDSet]) {
        if (!emailTemplateName_IdMap.ContainsKey(et.DeveloperName)) emailTemplateName_IdMap.put(et.DeveloperName, et);
    }
    
    //T-128808
    for (Document doc : [SELECT Name, Id, Folder.Name, FolderId FROM Document WHERE Folder.Name =: Constants.LOGO_FOLDER_DICE order By Name ASC]) {
        for(String brand : brandSet) {
            if (String.valueOf(doc.Name).containsIgnoreCase(brand) && !brandLogoInfo_Map.containsKey(brand)) brandLogoInfo_Map.put(brand, doc);
        }
    }
    
    Messaging.SingleEmailMessage mailObj = new Messaging.SingleEmailMessage();
    
    String brandLogoId = '';
//  String orgUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/';
//  Organization diceOrg = [SELECT Name, Id FROM Organization WHERE Name Like 'Dice%' ORDER BY Lastmodifieddate DESC LIMIT 1];
    
    List<Account> acctCatchList = [select id, BillingCountry from Account where Migration_Id__c = 'EmailTgrHandler' limit 1];
    List<Contact> dcCatchList = [select id, AccountId, email from Contact where Migration_Id__c = 'EmailTgrHandler' limit 1];

    Account acctCatch = null;
    Contact dcCatch = null;

    if (acctCatchList != null && !acctCatchList.isEmpty()) acctCatch = acctCatchList[0];
    if (dcCatchList != null && !dcCatchList.isEmpty()) dcCatch = dcCatchList[0];
    
    for (Case c : newList) {
      if (c.Brand__c <> null && c.Origin <> null && responseRuleMap.containsKey(c.Brand__c + '_' + c.Origin + '_' + c.Inbound_Email_Address__c)) {
        currentRule = responseRuleMap.get(c.Brand__c + '_' + c.Origin + '_' + c.Inbound_Email_Address__c);
        if (currentRule.ID <> null) {
            mailObj = new Messaging.SingleEmailMessage();
            if (brandLogoInfo_Map.containsKey(currentRule.Brand__c)) brandLogoId = brandLogoInfo_Map.get(currentRule.Brand__c).ID;

            //I-48543  (rita)
            //I-49205  (rita)
            if (c.ContactId == null || (c.ContactId != null && c.Contact.Email == null)   ) {
                             
              //I-50215 - Added, New Approah
               Account acct = new Account(Migration_Id__c='EmailTgrHandler',name='EmailTgrHandler',Phone='407-555-1212',BillingStreet='111 Oak Street',BillingCity='Iowa City',BillingState='IA',BillingPostalCode='90210',BillingCountry='Singapore');
              acct.ShippingCountry = acct.BillingCountry;
       

              try {                            
               // Upsert using an external ID field
               upsert acct Migration_Id__c;
             } catch (DmlException e) {
                if (acctCatch != null) acct = acctCatch;
             }
             Contact dc = new Contact(Migration_Id__c='EmailTgrHandler',FirstName='Hello',LastName='World',Email='datatomakeitwork@dice.com',AccountId=acct.id);
             dc.MailingCountry = acct.BillingCountry;

             try {        
                   // Upsert using an external ID field
                   upsert dc Migration_Id__c;
             } catch (DmlException e) {
              if (dcCatch != null) dc = dcCatch;
             }                
              // Pick a dummy Contact
              //Contact dc =  [select id, Email from Contact where email <> null limit 1];
            
              // Construct the list of emails we want to send
              List<Messaging.SingleEmailMessage> lstMsgs = new List<Messaging.SingleEmailMessage>();
            
              Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
              msg.setTemplateId( emailTemplateName_IdMap.get(currentRule.EmailTemplate__c).id );
              msg.setWhatId( dc.AccountId );
              msg.setTargetObjectId(dc.id);
              msg.setToAddresses(new List<String>{c.SuppliedEmail});
                            
              if (c.SuppliedEmail == null) c.SuppliedEmail = 'null';

              String InputString = c.SuppliedEmail;
              String emailRegex = '([a-zA-Z0-9_\\-\\.]+)@((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})';
              Pattern MyPattern = Pattern.compile(emailRegex);
        
              // Then instantiate a new Matcher object "MyMatcher"
              Matcher MyMatcher = MyPattern.matcher(InputString);              
        
              //If the email is valid to the RegEx pattern AND it's not in emailAddressesToIgnore, then we add it...
              if ((MyMatcher.matches()) && (!emailAddressesToIgnore.contains(InputString))) lstMsgs.add(msg);       
            
                  // Send the emails in a transaction, then roll it back
                  Savepoint sp = Database.setSavepoint();
                  PreventRecursiveExecution.dummyEmailCreateInProgress = true;
                  Messaging.sendEmail(lstMsgs);
                  PreventRecursiveExecution.dummyEmailCreateInProgress = false;
                  Database.rollback(sp);
            
              // For each SingleEmailMessage that was just populated by the sendEmail() method, copy its
              // contents to a new SingleEmailMessage. Then send those new messages.
              List<Messaging.SingleEmailMessage> lstMsgsToSend = new List<Messaging.SingleEmailMessage>();
              for (Messaging.SingleEmailMessage email : lstMsgs) {
                 Messaging.SingleEmailMessage emailToSend = new Messaging.SingleEmailMessage();
                 emailToSend.setToAddresses(email.getToAddresses());
                 emailToSend.setPlainTextBody(email.getPlainTextBody());
                 emailToSend.setHTMLBody(email.getHTMLBody());
                 emailToSend.setSubject(email.getSubject());
                 lstMsgsToSend.add(emailToSend);
              }          
             
              //Messaging.sendEmail(lstMsgsToSend);
              if(!lstMsgsToSend.isEmpty()) mailObj = lstMsgsToSend[0]; 
                       
            }  
            else {
                mailObj.setTemplateId(emailTemplateName_IdMap.get(currentRule.EmailTemplate__c).ID);
                mailObj.setTargetObjectId(c.ContactId);
            }
            mailObj.setSenderDisplayName(currentRule.SenderName__c);
            mailObj.setReplyTo(currentRule.ReplyToEmail__c);

            mailObj.setWhatId(c.ID);     
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mailObj });
        }
      }
    }
  }
}