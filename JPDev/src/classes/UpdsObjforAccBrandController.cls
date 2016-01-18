/***
*Class          ---- UpdsObjforAccBrandController
*Author         ---- Jaseem Pookandy
*Story          ---- CCBOB-192
*Created Date   ---- 2015.12.11
*Description    ---- This is the controller class for the UpdsObjforAccBrand.page 
----------------------------- Modifications & Updates -----------------------------
*Modified By    ---- Pookandy
*Story          ---- CCBOB-193
*Modified Date  ---- 2015.12.11
*Description    ----  added method to call customer feedback batch

*Modified By    ---- Pookandy
*Story          ---- CCBOB-194
*Modified Date  ---- 2015.12.14
*Description    ----  added method to call zContract Line Item batch

*Modified By    ---- Pookandy
*Story          ---- CCBOB-195
*Modified Date  ---- 2015.12.21
*Description    ----  added method to call Open activity batch
***/
public class UpdsObjforAccBrandController {
    // input from page for the batch size 
    public string totalcasebatchsize{get;set;} 
    public string totalcfbatchsize{get;set;}
    public string totalzlineitembatchsize{get;set;}
    public string totalactivitiesopenbatchsize{get;set;}
    public string totalactivitiesclosedbatchsize{get;set;}
    //variable that store the total records with no account brand
    public string totalcases{get;set;}
    public string totalcustomerfeedback{get;set;}
    public string totalzlineitem{get;set;}
    public string totalactivitiesopen{get;set;}
    public string totalactivitiesclosed{get;set;}
    //flag that controls the findout! button on the page
    public boolean casecountflag{get;set;}
    public boolean customerfeedbackflag{get;set;}
    public boolean zlineitemflag{get;set;}
    public boolean activitiesopenflag {get;set;}
    public boolean activitiesclosedflag {get;set;}
    
    public boolean isrecurrence {get;set;} //the boolean which controls the isrecurrence flag in the batch query. This was done because apex activity trigger doesn't handle batch of records if there are recurring activity.
    //Constructor
    public UpdsObjforAccBrandController(){
        //flag is true to show the findout! button
        casecountflag = true; 
        customerfeedbackflag = true;
        zlineitemflag = true;
        activitiesopenflag = true;
        activitiesclosedflag = true;
    }
    //Method that calls the case batch to update cases for account brand 
    public void runbatchupdforcases(){
        
        BatchUpdCasesforAccBrand batch = new BatchUpdCasesforAccBrand();
        batch.totalbatchsize = totalcasebatchsize;
        Database.executebatch(batch);
        
    }
    //Method that calls the customer feedback batch to update CF records for account brand
    public void runbatchupdforcustomerfeedback(){
        BatchUpdCustFBforAccBrand batch = new BatchUpdCustFBforAccBrand();
        batch.totalbatchsize = totalcfbatchsize;
        Database.executebatch(batch);
       
    }
    //Method that calls the zContract Line Item batch to update for account brand
    public void runbatchupdforzlineitem(){
        BatchUpdzCLineItemforAccBrand batch = new BatchUpdzCLineItemforAccBrand();
        batch.totalbatchsize = totalzlineitembatchsize;
        Database.executebatch(batch);
    }
    //Method that calls the open activity - task(not started, in progress) and event - batches to update account brand
    public void runbatchupdforopenactivities(){
        BatchUpdEventsforAccBrand batchevents = new BatchUpdEventsforAccBrand();
        batchevents.totalbatchsize = totalactivitiesopenbatchsize; // The input from the page is assigned to the batchsize 
        batchevents.isrecurrence = isrecurrence; //if it is true, then batch will execute with 1 record at a time because of apex limitation
        
        BatchUpdTasksforAccBrand batchtasks = new BatchUpdTasksforAccBrand('Open',totalactivitiesopenbatchsize,isrecurrence); // the same input from the page is passed as a parameter to the constructor to the batch
        if(isrecurrence == true){
            Database.executebatch(batchevents,1);
            Database.executebatch(batchtasks,1);
            system.debug('###### recurring block ');
        }else {
            Database.executebatch(batchevents);
            Database.executebatch(batchtasks);
            system.debug('######## non recurring block');
        }
        
        
    }
    //Method that calls the closed activity batch to update for account brand
    public void runbatchupdforclosedactivities(){
        BatchUpdTasksforAccBrand batchtasks = new BatchUpdTasksforAccBrand('Closed',totalactivitiesclosedbatchsize,isrecurrence);
        if(isrecurrence == true)
            Database.executebatch(batchtasks,1);
        else Database.executebatch(batchtasks);
    }
    //action method for findout! button - Case
    public void countcase(){
        casecountflag = false;
        list<Case> casecount;
        
        casecount = [select id from Case where account_brand__c =null and  brand__c !=null and (accountid!=null or Contactid!=null) LIMIT 50000]; //governor limit caution
        if(casecount.size() ==limits.getlimitqueryrows()) // if the total available records equal to the governor limit
            totalcases = '50000 or more records';
        else totalcases = string.valueof(casecount.size());
        
    }
    //action method for findout! button - customer feedback
    public void countcustomerfeedback(){
        customerfeedbackflag = false;
        list<customer_feedback__c> cfcount =  [select id from customer_feedback__c where account_brand__c =null and primary_brand__c !=null and (account__c!=null or Contact__c!=null) LIMIT 50000];
        if(cfcount.size() ==limits.getlimitqueryrows())
            totalcustomerfeedback = '50000 or more records';
        else totalcustomerfeedback = string.valueof(cfcount.size());
   }   
   //action method for findout! button - zContract Line Item
   public void countzlineitem(){
        zlineitemflag = false;
        list<Zuora__SubscriptionProductCharge__c> zlineitemcount = [Select id,Brand__c from Zuora__SubscriptionProductCharge__c where Zuora__Account__c!=null and brand__c !=null and Zuora__RatePlanName__c!=null and Zuora__ProductName__c!=null and account_brand__c =null LIMIT 50000];
        if(zlineitemcount.size()==limits.getlimitqueryrows())
            totalzlineitem = '50000 or more records';
        else totalzlineitem = string.valueof(zlineitemcount.size());
   } 
   //action method for findout! button - open activity
   public void countopenactivity(){
        activitiesopenflag = false;
        integer openactivitylimit;
        list<Task> tasklist= [Select id from Task where account_brand__c =null and (whatid!=null or whoid!=null) and brand__c !=null and (status= 'Not Started' OR status = 'In Progress') LIMIT 50000 ALL ROWS];
        if(limits.getqueryrows()==limits.getlimitqueryrows())
            openactivitylimit = 0; // if task count has already reached the limit
        else openactivitylimit = limits.getlimitqueryrows() - limits.getqueryrows(); // else set the limit for event with what is left to reach the governor limit
        
        system.debug('######### activity limit '+openactivitylimit);
        list<Event> eventlist = [Select id from Event where account_brand__c =null and (whatid!=null or whoid!=null) and brand__c !=null LIMIT :openactivitylimit ALL ROWS];
        if(limits.getqueryrows() == limits.getlimitqueryrows())
            totalactivitiesopen = '50000 or more records'; // if the total query rows has already hit the governor limit
        else totalactivitiesopen = string.valueof(limits.getqueryrows());
   } 
    //action method for findout! button - zContract Line Item
   public void countclosedactivity(){
        activitiesclosedflag = false;
        list<Task> tasklist = [Select id from Task where account_brand__c =null and (whatid!=null or whoid!=null) and brand__c !=null and (status= 'Completed' OR status = 'Cancelled') LIMIT 50000 ALL ROWS];
        if(tasklist.size()==limits.getlimitqueryrows())
            totalactivitiesclosed = '50000 or more records';
        else totalactivitiesclosed = string.valueof(tasklist.size());
   } 
}