public class Utils_OpportunityProvision {


  @future (callout=false)
    public static void OpptyCreateTasks(Set<Id> oppIDs) {
            
      //CC-3136 - we don't need this list of rules becasue we will get the value from the product to determine if a logo upload case should be created
      //List<UploadLogoRules__c> LogoRulesList = UploadLogoRules__c.getall().values();
      Set<Id> taskoppIDs = new Set<Id>();    
      Map<Id, Account> soldByPartners = new Map<Id, Account>();
      Set<Id> soldByPartnerIDs = new Set<Id>();
      Set<Id> accountIDs = new Set<Id>();
      Map<Id, Opportunity> mapOpportunities = new Map<Id, Opportunity>();
      //Map<Id, List<zqu__QuoteCharge__c>> mapQuoteProducts = new Map<Id, List<zqu__QuoteCharge__c>>();
      Map<String, List<zqu__QuoteCharge__c>> mapQuoteProductsBrand = new Map<String, List<zqu__QuoteCharge__c>>();
      Map<String, Account_Brand__c> mapAccountBrands = new Map<String, Account_Brand__c>();
      Map<String, User_Group__c> mapUserGroups = new Map<String, User_Group__c>();
      
      List<Task> tasksToInsert = new List<Task>();

      Map<Id, zqu__Quote__c> oppQuoteMap = new Map<Id, zqu__Quote__c>();
      for (zqu__Quote__c q : [SELECT 
                  zqu__Opportunity__c,
                  Id,
                  (SELECT Id, 
                    zqu__ProductRatePlanCharge__r.Id, 
                    zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Id, 
                    zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.CSNotificationofOrderTask__c
                  FROM zqu__QuoteCharge__r) 
                  FROM zqu__Quote__c 
                  WHERE IsSyncing__c = true AND zqu__Opportunity__c IN : oppIDs]) {
        if (!oppQuoteMap.containsKey(q.zqu__Opportunity__c)) oppQuoteMap.put(q.zqu__Opportunity__c, q);
      }            

      //Get all opportunity details
      for (Opportunity o : [SELECT Id, Account_Name__c, AccountId, Provisioning_Completed_Date__c, Account_Number__c, Account_URL__c, Sold_By_Partner__c FROM Opportunity WHERE Id IN :oppIDs]) {
          if (Utils_OpportunityProvision.CSTasksShouldBeCreated(oppQuoteMap.get(o.Id))) {  
              taskoppIDs.add(o.id);             
              if(!mapOpportunities.containsKey(o.Id)) mapOpportunities.put(o.Id, o);         
              if (o.Sold_By_Partner__c != null) soldByPartnerIDs.add(o.Sold_By_Partner__c);
          
              accountIDs.add(o.AccountId);
          }
      }
      
      //Set the backup owner...
      List<Training_Backup_User__c> fallBackList = Training_Backup_User__c.getall().values();     
      String fallBackOwnerID;
      if (fallBackList.size() > 0) fallBackOwnerID = fallBackList[0].UserID__c;
      else fallBackOwnerID = null;
     
      //Get all soldbypartners...
      for (Account a : [SELECT Id, Name, Channel_Partner__c FROM Account WHERE Id IN :soldByPartnerIDs]) {
          if (!soldByPartners.containsKey(a.Id)) soldByPartners.put(a.Id, a);
      }
      
      //Get all quote charges, mapped by opportunity & brand
      for (zqu__QuoteCharge__c qc : [SELECT zqu__Quote__r.zqu__Opportunity__r.Id, Name, Id, zqu__Quantity__c, zqu__Description__c, zqu__UOM__c, zqu__Total__c, zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c, zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductGroup__c, zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductSubCategory__c, zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.UploadLogo__c FROM zqu__QuoteCharge__c WHERE zqu__Quote__r.zqu__Opportunity__r.Id IN :taskoppIDs AND zqu__Quote__r.IsSyncing__c = true]) {
          if (!mapQuoteProductsBrand.containsKey(qc.zqu__Quote__r.zqu__Opportunity__r.Id + '~~' + qc.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c)) mapQuoteProductsBrand.put(qc.zqu__Quote__r.zqu__Opportunity__r.Id + '~~' + qc.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c, new List<zqu__QuoteCharge__c>());
          mapQuoteProductsBrand.get(qc.zqu__Quote__r.zqu__Opportunity__r.Id + '~~' + qc.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c).add(qc);
      }
      
      //Get all account brands by account ID & brand picklist     
      for (Account_Brand__c ab : [SELECT Account__c, Brand_Picklist__c, CS__c, Support_Owner_Inactive__c FROM Account_Brand__c WHERE Account__c IN :accountIDs]) {
          if (!mapAccountBrands.containsKey(ab.Account__c)) mapAccountBrands.put(ab.Account__c + '~~' + ab.Brand_Picklist__c, ab);
      }            
              
      //We now have all the data collected, organized and ready...
      for (List<zqu__QuoteCharge__c> listCharges : mapQuoteProductsBrand.values()) {
          
          if (listCharges.size() > 0) {
          
              boolean QuoteHasLineItems = false;
              Opportunity o = mapOpportunities.get(listCharges[0].zqu__Quote__r.zqu__Opportunity__r.Id);
              Account_Brand__c ab = mapAccountBrands.get(o.AccountId + '~~' + listCharges[0].zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c);
              Account soldByPartner;
                  
              if ((o.Sold_By_Partner__c != null) && (soldByPartners.containsKey(o.Sold_By_Partner__c))) soldByPartner = soldByPartners.get(o.Sold_By_Partner__c);
              else soldByPartner = new Account(Channel_Partner__c = false);
      
              Task t = new Task();
              
              t.Subject = 'Notification of Order';
              t.Type__c = 'Note';
              t.Brand__c = listCharges[0].zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c;
              
              //t.Due_Date__c = date.newInstance(o.Provisioning_Completed_Date__c.year(), o.Provisioning_Completed_Date__c.month(), o.Provisioning_Completed_Date__c.day());
              t.ActivityDate = system.today();
              
              if ((ab != null) && (ab.CS__c != null) && (ab.Support_Owner_Inactive__c == false)) t.OwnerId = ab.CS__c;
              else t.OwnerId = fallBackOwnerID;
              
              t.WhatId = o.Id;
              t.Status = 'Not Started';
              t.Priority = 'Normal';
              
              String notesField = 'Account: ' + o.Account_Name__c + '\r\n';
              notesField += 'Account Number: ' + o.Account_Number__c + '\r\n';
              
              if (soldByPartner.Channel_Partner__c == true) notesField += 'Agency Involved in Sale: Yes \r\n';
              else notesField += 'Agency Involved in Sale: No \r\n';
              
              notesField += '\r\n';
              
              notesField += 'Products:\r\n';
              for (zqu__QuoteCharge__c qc : listCharges) {    
                  if (qc.zqu__Quantity__c != null) {
                      QuoteHasLineItems = true;
                      notesField += qc.zqu__Description__c + ', ' + qc.zqu__UOM__c + '  (' + qc.zqu__Quantity__c + ')  -  ' + qc.zqu__Total__c + '\r\n';
                  }
              }
              
             
              t.Description = notesField;
              
              if (QuoteHasLineItems) tasksToInsert.add(t);
          }
      }   //end for

      Database.DMLOptions notifyOption = new Database.DMLOptions();
      notifyOption.EmailHeader.triggerUserEmail = true;

      //if (!tasksToInsert.isEmpty()) insert tasksToInsert;
      if (!tasksToInsert.isEmpty()) database.insert(tasksToInsert, notifyOption);
    } //end method

    public static Boolean CSTasksShouldBeCreated(Zqu__Quote__c oppsQuote) {
 
    
        Integer numValid = 0;
     
  
        if (oppsQuote!= null && oppsQuote.zqu__QuoteCharge__r != null) {
   

            for (zqu__QuoteCharge__c thisQC : oppsQuote.zqu__QuoteCharge__r) {
                
                if (thisQC.zqu__ProductRatePlanCharge__r != null 
                     && thisQC.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r != null 
                     && thisQC.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r != null 
                     && thisQC.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.CSNotificationofOrderTask__c != null) {

                     if (thisQC.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.CSNotificationofOrderTask__c.tolowercase() == 'y' ) {
                        numValid++;
                     }
                }
            }
        }

        if (numValid > 0) return true;
        else return false;
    }

    public static Boolean ShouldWebstoreTaskBeCreated(Zqu__Quote__c oppsQuote) {
 
    
        Integer numValid = 0;
     
  
        if (oppsQuote!= null && oppsQuote.zqu__QuoteCharge__r != null) {
   

            for (zqu__QuoteCharge__c thisQC : oppsQuote.zqu__QuoteCharge__r) {
                
                if (thisQC.zqu__ProductRatePlanCharge__r != null 
                     && thisQC.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r != null 
                     && thisQC.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r != null 
                     && thisQC.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.CSNotificationofOrderTask__c != null) {

                     if (thisQC.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.CSNotificationofOrderTask__c.tolowercase() == 'y' ) {
                        numValid++;
                     }
                }
            }
        }

        if (numValid > 0) return true;
        else return false;
    }

    //CC-590
    @future (callout=false)
    public static void OpptyCreateCases(Set<Id> oppIDs) {
            
        //CC-3136 - we don't need this list of rules becasue we will get the value from the product to determine if a logo upload case should be created
        //List<UploadLogoRules__c> LogoRulesList = UploadLogoRules__c.getall().values();
        Set<Id> caseOppIds = new Set<Id>();    
        Map<Id, Account> soldByPartners = new Map<Id, Account>();
        Set<Id> soldByPartnerIDs = new Set<Id>();
        Set<Id> accountIDs = new Set<Id>();
        Map<Id, Opportunity> mapOpportunities = new Map<Id, Opportunity>();
        //Map<Id, List<zqu__QuoteCharge__c>> mapQuoteProducts = new Map<Id, List<zqu__QuoteCharge__c>>();
        Map<String, List<zqu__QuoteCharge__c>> mapQuoteProductsBrand = new Map<String, List<zqu__QuoteCharge__c>>();
        Map<String, Account_Brand__c> mapAccountBrands = new Map<String, Account_Brand__c>();
        Map<String, User_Group__c> mapUserGroups = new Map<String, User_Group__c>();    
        Map<Id, zqu__Quote__c> oppQuoteMap = new Map<Id, zqu__Quote__c>();

        for (zqu__Quote__c q : [SELECT 
                    zqu__Opportunity__c,
                    Id,
                    (SELECT Id, 
                      zqu__ProductRatePlanCharge__r.Id, 
                      zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Id, 
                      zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.UploadLogo__c
                    FROM zqu__QuoteCharge__r) 
                    FROM zqu__Quote__c 
                    WHERE IsSyncing__c = true AND zqu__Opportunity__c IN : oppIDs]) {
          if (!oppQuoteMap.containsKey(q.zqu__Opportunity__c)) oppQuoteMap.put(q.zqu__Opportunity__c, q);
        }        
        

        //Get all opportunity details
        for (Opportunity o : [SELECT Id, Account_Name__c, AccountId, Provisioning_Completed_Date__c, Account_Number__c, Account_URL__c, Sold_By_Partner__c FROM Opportunity WHERE Id IN :oppIDs]) {
            if (EvaluateLogoRules(oppQuoteMap.get(o.Id))) {  
                caseOppIds.add(o.id);             
                if(!mapOpportunities.containsKey(o.Id)) mapOpportunities.put(o.Id, o);         
                if (o.Sold_By_Partner__c != null) soldByPartnerIDs.add(o.Sold_By_Partner__c);
            
                accountIDs.add(o.AccountId);
            }
        }
                
        //Get all soldbypartners...
        for (Account a : [SELECT Id, Name, Channel_Partner__c FROM Account WHERE Id IN :soldByPartnerIDs]) {
            if (!soldByPartners.containsKey(a.Id)) soldByPartners.put(a.Id, a);
        }
        
        //Get all quote charges, mapped by opportunity & brand
        for (zqu__QuoteCharge__c qc : [SELECT zqu__Quote__r.zqu__Opportunity__r.Id, Name, Id, zqu__Quantity__c, zqu__Description__c, zqu__UOM__c, zqu__Total__c, zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c, zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductGroup__c, zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductSubCategory__c, zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.UploadLogo__c FROM zqu__QuoteCharge__c WHERE zqu__Quote__r.zqu__Opportunity__r.Id IN :caseOppIds AND zqu__Quote__r.IsSyncing__c = true]) {
            if (!mapQuoteProductsBrand.containsKey(qc.zqu__Quote__r.zqu__Opportunity__r.Id + '~~' + qc.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c)) mapQuoteProductsBrand.put(qc.zqu__Quote__r.zqu__Opportunity__r.Id + '~~' + qc.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c, new List<zqu__QuoteCharge__c>());
            mapQuoteProductsBrand.get(qc.zqu__Quote__r.zqu__Opportunity__r.Id + '~~' + qc.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c).add(qc);
        }
        
        //Get all account brands by account ID & brand picklist     
        //for (Account_Brand__c ab : [SELECT Account__c, Brand_Picklist__c, CS__c, Support_Owner_Inactive__c FROM Account_Brand__c WHERE Account__c IN :accountIDs]) {
            //if (!mapAccountBrands.containsKey(ab.Account__c)) mapAccountBrands.put(ab.Account__c + '~~' + ab.Brand_Picklist__c, ab);
        //}               
        //We now have all the data collected, organized and ready...

        List<Case> casesToInsert = new List<Case>();

        for (List<zqu__QuoteCharge__c> listCharges : mapQuoteProductsBrand.values()) {
            
            if (listCharges.size() > 0) {
            
                boolean QuoteHasLineItems = false;

                Opportunity o = mapOpportunities.get(listCharges[0].zqu__Quote__r.zqu__Opportunity__r.Id);
                //Account_Brand__c ab = mapAccountBrands.get(o.AccountId + '~~' + listCharges[0].zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c);
                Account soldByPartner;
                    
                if ((o.Sold_By_Partner__c != null) && (soldByPartners.containsKey(o.Sold_By_Partner__c))) soldByPartner = soldByPartners.get(o.Sold_By_Partner__c);
                else soldByPartner = new Account(Channel_Partner__c = false);
             
                //Now add the 'Upload Customer Logo' Task - need to put in logic to only do this if this meets criteria
                //Does the collection of quote charges meet criteria to create an Upload Logo task?

                AssignmentRule AR = new AssignmentRule();
                AR = [select id from AssignmentRule where sobjecttype = 'Case' and Active = true limit 1];
                Database.DMLOptions dmlopts = new Database.DMLOptions();
                dmlopts.assignmentRuleHeader.assignmentRuleId = AR.id;
                
                Case lc = new Case();                
                
                lc.Reason = 'Customer Support';
                lc.Subject = 'Upload Customer Logo';
                lc.Type__c = 'Logo Processing';
                lc.Brand__c = listCharges[0].zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Brand__c;
                
                //t.Due_Date__c = date.newInstance(o.Provisioning_Completed_Date__c.year(), o.Provisioning_Completed_Date__c.month(), o.Provisioning_Completed_Date__c.day());
                //mb lc.ActivityDate = system.today();
                
                //The Upload Logo task should always be assigned to the Dice Holdings User
                //mb lc.OwnerId = fallBackOwnerID;
                //The case will be assigned using Case Assignment rules
                
                lc.AccountId = o.AccountId;
                lc.Opportunity__c = o.Id;
                lc.Status = 'New';
                lc.Priority = 'Medium';
                lc.Assign_to_CSR__c = false;
                
                String notesField2 = 'Please Visit the Customer Website for Closed Opportunity and Upload a Logo to the Back Office System' + '\r\n';
                notesField2 += 'Account: ' + o.Account_Name__c + '\r\n';
                notesField2 += 'Account Number: ' + o.Account_Number__c + '\r\n';
                notesField2 += 'Account Website: ' + o.Account_URL__c + '\r\n';
                
                if (soldByPartner.Channel_Partner__c == true) notesField2 += 'Agency Involved in Sale: Yes \r\n';
                else notesField2 += 'Agency Involved in Sale: No \r\n';
                
                notesField2 += '\r\n';                    
                notesField2 += 'Products:\r\n';

                for (zqu__QuoteCharge__c qc : listCharges) {    
                    if (qc.zqu__Quantity__c != null) {
                        QuoteHasLineItems = true;
                        notesField2 += qc.Name + '  (' + qc.zqu__Quantity__c + ')  -  ' + qc.zqu__Total__c + '\r\n';
                        //do these need to be added to the notes? - zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductGroup__c, zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductSubCategory__c
                    }
                }

                notesField2 += '\r\n';                            
                notesField2 += 'User Group(s) associated to this Account:\r\n';

                //Get All User Groups by Account ID and Group ID     
                for (User_Group__c ug : [SELECT Account__c, Name, Active_Usage__c, Inactive_Usage__c FROM User_Group__c WHERE Account__c IN :accountIDs]) {
                  if (ug.Name != null) notesField2 += 'Group ID: ' + ug.Name + ', ' + ' Active Brand(s): ' + ug.Active_Usage__c;
                }                        

                lc.Description = notesField2;
                lc.setOptions(dmlopts);  

                casesToInsert.add(lc);
            } //end if                          
        } //end for loop
        
        if (casesToInsert.size() > 0) insert casesToInsert;     

      } //end method

      static boolean EvaluateLogoRules(zqu__Quote__c oppsQuote) {

        Integer numValid = 0;
  
        if (oppsQuote!= null && oppsQuote.zqu__QuoteCharge__r != null) {   

            for (zqu__QuoteCharge__c thisQC : oppsQuote.zqu__QuoteCharge__r) {
                
                if (thisQC.zqu__ProductRatePlanCharge__r != null 
                    && thisQC.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r != null 
                    && thisQC.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r != null 
                    && thisQC.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.UploadLogo__c != null) {

                    if (thisQC.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.UploadLogo__c.tolowercase() == 'y' ) numValid++;
                }
            }
        }

        if (numValid > 0) return true;
        else return false;
      }

}