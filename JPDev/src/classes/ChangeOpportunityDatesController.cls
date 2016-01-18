public with sharing class ChangeOpportunityDatesController {

    public final List<WrapperForOpp> oppList;

    public List<String> infos {get; set;}
    public Opportunity dummyOpp {get; set;}
    public List<String> errors {get; set;}
    public String header {get; set;}        
    public Boolean specificDateMethod {get; set;}  
    public Boolean variableDateMethod {get; set;}  
    public User currentUser {get; set;}
    public String FirstOpp {get; set;}
    public Id OppOwnerToChange {get; set;}
    
    String variableValue = null;

    private PageReference pgReturnPage {get; set;}      

    public ChangeOpportunityDatesController(ApexPages.StandardController con) {
        header = 'Mass Change Close Dates';       
        oppList = new List<WrapperForOpp>();
        for (Opportunity t : [SELECT Name, Net_Amount__c, Account.Name, Contact__r.Name, Contact__r.Id, Owner.Name, Id, Amount, Description, StageName, Account_Brand__c, Account_Name__c, 
                                     CloseDate, Orig_CloseDate__c, Type, Primary_Brand__c, Sold_By_Partner__c, Sold_By_Partner__r.Id, Sold_By_Partner__r.Name
                                FROM Opportunity WHERE Id IN : getIds() AND 
                                IsClosed = false AND
                                (OwnerId = :UserInfo.getUserId() OR OwnerId IN : getSubordinates()) AND 
                                OwnerId = :OppOwnerToChange ORDER BY CloseDate ASC]) {
            WrapperForOpp w = new WrapperForOpp();
            w.opportunity = t;
            w.NewCloseDate = null;
            oppList.add(w);
        }

        header += ' for the Selected ' + oppList.size() + ' Opportunities';

        variableValue = '30';
    }

    public List<WrapperForOpp> getOpps() {
        return this.OppList;
    }

    //on check-change of the specific checkbox, uncheck the variable, ALWAYS
    //even though these are checkboxes, they need to function like radio buttons
    public void specificDateChanged() {
        
        infos = new List<String>();
        errors = new List<String>();
        variableDateMethod = false;        

        //We are using the this temp date field so we have the standard date picker and can get around the page reload issues if the Close Date is left blank.
        if (dummyOpp.Developer_VF_Date__c != null) {
            for (WrapperForOpp wt : OppList) {
                wt.NewCloseDate = dummyOpp.Developer_VF_Date__c;
            }

            CountSpecificDatesOpp(dummyOpp.Developer_VF_Date__c);
        }
    }

    private void CountSpecificDatesOpp(Date dt) {

        infos = new List<String>();
        errors = new List<String>();
        List<AggregateResult> results = [SELECT COUNT(Id) NumOpen FROM Opportunity WHERE CloseDate = :dt AND OwnerId = :OppOwnerToChange AND IsClosed = false];
        Integer iNum;

        for (AggregateResult ar : results) {
            iNum = (Integer)ar.get('NumOpen');
        }

        String s = 'There are currently ' + iNum + ' open Opportunities with a Close Date on ' + dt.format();
        infos.add(s);
    }

    private void CountVariableDatesOpps(Integer offset) {

        infos = new List<String>();
        errors = new List<String>();
        List<Date> dateList = new List<Date>();

        for (WrapperForOpp wt : oppList) {
            if (wt.NewCloseDate != null) dateList.add(wt.NewCloseDate);
        }

        dateList.sort();

        List<AggregateResult> results = [SELECT COUNT(Id) NumOpen, CloseDate FROM Opportunity WHERE CloseDate IN :dateList AND OwnerId = :OppOwnerToChange AND IsClosed = false GROUP BY CloseDate ORDER BY CloseDate];
        Integer iNum;
        String s;

        Set<Date> datesProcessed = new Set<Date>();

        for (Date thisDate : dateList) {

            if (!datesProcessed.contains(thisDate)) {
                Boolean bFound = false;
                
                for (AggregateResult ar : results) {

                    iNum = (Integer)ar.get('NumOpen');
                    
                    if (thisDate == (Date)ar.get('CloseDate')) {
                        s = 'There are currently ' + iNum + ' open Opportunities with a Close Date on ' + thisDate.format();
                        bFound = true;
                    }                
                }

                if (!bFound)  s = 'There are currently 0 open Opportunities with a Close Date on ' + thisDate.format();
                
                infos.add(s);

                datesProcessed.add(thisDate);
            }
        }
    }

    //on check-change of the specific checkbox, uncheck the specific, ALWAYS
    //even though these are checkboxes, they need to function like radio buttons
    public void variableDateChanged() {

        infos = new List<String>();
        errors = new List<String>();
        specificDateMethod = false;        

        List<SelectOption> options = getVariableOptions();

        if (variableValue == null) variableValue = options[0].getLabel();

        if (variableValue != null) {
            for (WrapperForOpp wt : oppList) {
                if ((wt.opportunity != null) && (wt.opportunity.CloseDate != null)) wt.NewCloseDate = wt.opportunity.CloseDate.addDays(Integer.valueOf(variableValue));
            }
            CountVariableDatesOpps(Integer.valueOf(variableValue));
        }        
    }                

    public void setVariableValue(String varVal) {
        this.variableValue = varVal;
    }

    public String getVariableValue() {
        return variableValue;
    }

    public List<SelectOption> getVariableOptions() {
        List<SelectOption> options = new List<SelectOption>(); 

        for (Integer i=60; i>=-60; i--) {
            options.add(new SelectOption(String.valueOf(i),String.valueOf(i)));
        }

        return options; 
    }

    public Set<Id> getIds() {
    
        Boolean firstTime = true;
        
        Set<Id> IdSet = new Set<Id>();
        string[] strArr = ApexPages.currentPage().getParameters().get('Ids').split(',');
        //This function can only be used for one user at time, so we will get the first Task Id and store it in a Variable to use later 
        //to determine the user that is being processed now.
        
        for(string s : strArr) {
            if (firstTime == true) {
                FirstOpp = s;
                firstTime = false;
            }
            
            IdSet.add(s);
        }       
        //Now get the Id of the Owner that is being processed, only one can be processed at a time
        OppOwnerToChange  = [Select OwnerId from Opportunity where Id = :FirstOpp].OwnerId;

        return IdSet;
    }

    public Set<Id> getSubordinates() {
         Set<Id> IdSet = new Set<Id>();
         idSet = RoleUtils.getRoleSubordinateUsers( UserInfo.getUserId() );
         return IdSet;
    }
    public PageReference PrepPage() {

        currentUser = [SELECT Username, Id, State, Country, DefaultBrand__c, Default_BrandTag__c, FirstName, Name, LastName, Title, UserType, CurrencyIsoCode FROM User WHERE Id = :Userinfo.getUserID()];

        infos = new List<String>();
        errors = new List<String>();
        dummyOpp = new Opportunity();

        pgReturnPage = new PageReference(ApexPages.currentPage().getParameters().get('retURL'));

        return null;
    }

    public PageReference Cancel() {
        return pgReturnPage;
    }    

    public PageReference Save() {
    
      //save all the pieces
      Boolean GoodToGo = Validate();
      
      //validate if the record is ok to save, do not run edits if Contact is no longer with the company (CC-2489)
      if (GoodToGo)  {   
        //commit the change to the opportunities and return the user back to their retURL...

        List<Opportunity> oppsToUpdate = new List<Opportunity>();

        for (WrapperForOpp wt : oppList) {
            Opportunity t = wt.opportunity;
            t.CloseDate = wt.NewCloseDate;
            oppsToUpdate.add(t);
        }

        if (oppsToUpdate.size() > 0) update oppsToUpdate;

        return pgReturnPage;
      } else return null;
    }

    //Wrapper class for holding the new due date around the existing task object
    public class WrapperForOpp
    {
        public Opportunity opportunity {get;set;}
        public Date NewCloseDate {get; set;}

        public String PrettyNewCloseDate {
            get {
                if (NewCloseDate != null) return NewCloseDate.format();       
                else return null;
            }
        }
    }
    
    private Boolean Validate() {
        //reset the error collection...
        errors = new List<String>();         
        integer iTypeCnt = 0;
        
        if (infos.size() == 0) errors.add('There is nothing to process.  Please select a Specific Date or Variable Date before Saving.');
        if (errors.size() > 0) return false;
        return true;
    }            
            
}