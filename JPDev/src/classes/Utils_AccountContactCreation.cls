/****
*Class            Utils_AccountContactCreation
*Author           @GMwamsoyo
*Story            CCBOB-88
*Date             11/04/2015
*Description      Find an existing account based on Duplicate Match Rule or create a new one when no match 
-----------------------------Modifications Updates ------------------------------

***/
global with sharing class Utils_AccountContactCreation
{   
    global class ReturnClass {
      public string Id { get; set; }
      public string MatchType { get; set; }
      public string Remark { get; set; }
      public Account MatchedAccount {get; Set; }
      public double Confidence {get; Set; }
    }
        
    global class ReturnContact {
      public string Id { get; set; }
      public string MatchType { get; set; }
      public string Remark { get; set; }
      public Contact MatchedContact {get; Set; }
      public double Confidence {get; Set; }
    }
        
    global static ReturnClass fetchDuplicateAccounts(Account account) 
    {
       Database.SaveResult sr = Database.insert(account, false);
       if (!sr.isSuccess()) 
       {                   
           for (Database.Error error : sr.getErrors()) 
           {                
              if (error instanceof Database.DuplicateError) 
              {
                Database.DuplicateError duplicateError = (Database.DuplicateError)error;
                Datacloud.DuplicateResult duplicateResult = duplicateError.getDuplicateResult();                                               
                Datacloud.MatchResult[] matchResults = duplicateResult.getMatchResults();
                Datacloud.MatchResult matchResult = matchResults[0];
                Datacloud.MatchRecord[] matchRecords = matchResult.getMatchRecords();

                // Add matched record to the duplicate records variable
                for (Datacloud.MatchRecord matchRecord : matchRecords) 
                {                  
                   ReturnClass existingAccount = new ReturnClass();
                   existingAccount.Id = String.valueOf(matchRecord.getRecord().Id);
                   existingAccount.MatchType = 'Existing Account';
                   existingAccount.Remark = 'Successful';
                   existingAccount.MatchedAccount = (Account)matchRecord.getRecord();
                   existingAccount.Confidence = matchRecord.getMatchConfidence();
                   return existingAccount;
                }                
              }        
              else
              {
                // Creation failed return error                    
                ReturnClass errorAccount = new ReturnClass();
                errorAccount.MatchType = 'Error Encountered';
                errorAccount.Remark = error.getStatusCode() + ': ' + error.getMessage() + ': ' + error.getFields();
                return errorAccount;
              }           
           }
       }
       else
       {
          ReturnClass newAccount = new ReturnClass();
          newAccount.Id = String.valueOf(sr.getId());
          newAccount.MatchType = 'New Account';
          newAccount.Remark = 'Successful';
          return newAccount;
       }
       return null;
    }  
   global static ReturnContact fetchDuplicateContacts(Contact Contact) 
    {
       Database.SaveResult sr = Database.insert(Contact, false);
       if (!sr.isSuccess()) 
       {                   
           for (Database.Error error : sr.getErrors()) 
           {                
              if (error instanceof Database.DuplicateError) 
              {
                Database.DuplicateError duplicateError = (Database.DuplicateError)error;
                Datacloud.DuplicateResult duplicateResult = duplicateError.getDuplicateResult();                                               
                Datacloud.MatchResult[] matchResults = duplicateResult.getMatchResults();
                Datacloud.MatchResult matchResult = matchResults[0];
                Datacloud.MatchRecord[] matchRecords = matchResult.getMatchRecords();

                // Add matched record to the duplicate records variable
                for (Datacloud.MatchRecord matchRecord : matchRecords) 
                {                  
                   ReturnContact existingContact = new ReturnContact();
                   existingContact.Id = String.valueOf(matchRecord.getRecord().Id);
                   existingContact.MatchType = 'Existing Contact';
                   existingContact.Remark = 'Successful';
                   existingContact.MatchedContact = (Contact)matchRecord.getRecord();
                   existingContact.Confidence = matchRecord.getMatchConfidence();
                   return existingContact;
                }                
              }        
              else
              {
                // Creation failed return error                    
                ReturnContact errorContact = new ReturnContact();
                errorContact.MatchType = 'Error Encountered';
                errorContact.Remark = error.getStatusCode() + ': ' + error.getMessage() + ': ' + error.getFields();
                return errorContact;
              }           
           }
       }
       else
       {
          ReturnContact newContact = new ReturnContact();
          newContact.Id = String.valueOf(sr.getId());
          newContact.MatchType = 'New Contact';
          newContact.Remark = 'Successful';
          return newContact;
       }
       return null;
    }       
}