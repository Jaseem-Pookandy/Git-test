public with sharing class ChangeActivityDatesController {

    public final List<WrapperForTask> tskList;

    public List<String> infos {get; set;}
    public Task dummyTask {get; set;}
    public List<String> errors {get; set;}
    public String header {get; set;}        
    public Boolean specificDateMethod {get; set;}  
    public Boolean variableDateMethod {get; set;}  
    public User currentUser {get; set;}
    public String FirstTask {get; set;}
    public Id TaskOwnerToChange {get; set;}
    
    String variableValue = null;

    private PageReference pgReturnPage {get; set;}      

    public ChangeActivityDatesController(ApexPages.StandardController con) {
        header = 'Mass Change Due Dates';       
        tskList = new List<WrapperForTask>();
        for (Task t : [SELECT Owner.Name, Id, What.Name, WhatId, WhoId, Who.Name, Subject, ActivityDate, Type, Brand__c, Priority FROM Task WHERE Id IN : getIds() AND (OwnerId = :UserInfo.getUserId() OR OwnerId IN : getSubordinates()) AND OwnerId = :TaskOwnerToChange ORDER BY ActivityDate ASC]) {
            WrapperForTask w = new WrapperForTask();
            w.task = t;
            w.NewDueDate = null;
            tskList.add(w);
        }

        header += ' for the Selected ' + tskList.size() + ' Tasks';

        variableValue = '7';
    }

    public List<WrapperForTask> getTasks() {
        return this.tskList;
    }

    //on check-change of the specific checkbox, uncheck the variable, ALWAYS
    //even though these are checkboxes, they need to function like radio buttons
    public void specificDateChanged() {
        
        infos = new List<String>();
        errors = new List<String>();

        variableDateMethod = false;        

        if (dummyTask.ActivityDate != null && specificDateMethod) {
            for (WrapperForTask wt : tskList) {
                wt.NewDueDate = dummyTask.ActivityDate;
            }

            CountSpecificDatesTasks(dummyTask.ActivityDate);
        }
        else {
            //Clear out the new due dates
            for (WrapperForTask wt : tskList) {
                wt.NewDueDate = null;
            }   
        }
    }

    private void CountSpecificDatesTasks(Date dt) {

        infos = new List<String>();
        errors = new List<String>();
        
        List<AggregateResult> results = [SELECT COUNT(Id) NumOpen FROM Task WHERE ActivityDate = :dt AND OwnerId = :TaskOwnerToChange AND IsClosed = false];
        Integer iNum;

        for (AggregateResult ar : results) {
            iNum = (Integer)ar.get('NumOpen');
        }

        String s = 'There are currently ' + iNum + ' open Tasks with a Due Date on ' + dt.format();
        infos.add(s);
    }

    private void CountVariableDatesTasks(Integer offset) {

        //infos = new List<String>();
        errors = new List<String>();

        List<Date> dateList = new List<Date>();

        for (WrapperForTask wt : tskList) {
            if (wt.NewDueDate != null) dateList.add(wt.NewDueDate);
        }

        dateList.sort();

        List<AggregateResult> results = [SELECT COUNT(Id) NumOpen, ActivityDate FROM Task WHERE ActivityDate IN :dateList AND OwnerId = :TaskOwnerToChange AND IsClosed = false GROUP BY ActivityDate ORDER BY ActivityDate];
        Integer iNum;
        String s;

        Set<Date> datesProcessed = new Set<Date>();

        for (Date thisDate : dateList) {

            if (!datesProcessed.contains(thisDate)) {
                Boolean bFound = false;
                
                for (AggregateResult ar : results) {

                    iNum = (Integer)ar.get('NumOpen');
                    
                    if (thisDate == (Date)ar.get('ActivityDate')) {
                        s = 'There are currently ' + iNum + ' open Tasks with a Due Date on ' + thisDate.format();
                        bFound = true;
                    }                
                }

                if (!bFound)  s = 'There are currently 0 open Tasks with a Due Date on ' + thisDate.format();
                
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

        Integer iNullDates = 0;

        if (variableValue == null) variableValue = options[0].getLabel();

        if (variableValue != null && variableDateMethod) {
            for (WrapperForTask wt : tskList) {
                if ((wt.task != null) && (wt.task.ActivityDate != null)) wt.NewDueDate = wt.task.ActivityDate.addDays(Integer.valueOf(variableValue));
                else {
                    iNullDates++;
                    wt.NewDueDate = null;
                }
            }            

            infos.add('Note that the variable date method will have no effect on ' + iNullDates + ' tasks as they currently have no due date.');

            CountVariableDatesTasks(Integer.valueOf(variableValue));
        }   
        else {
            //Clear out the new due dates
            for (WrapperForTask wt : tskList) {
                wt.NewDueDate = null;
            }                
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
                FirstTask = s;
                firstTime = false;
            }
            
            IdSet.add(s);
        }       
        //Now get the Id of the Owner that is being processed, only one can be processed at a time
        TaskOwnerToChange  = [Select OwnerId from Task where Id = :FirstTask].OwnerId;

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
        dummyTask = new Task();

        pgReturnPage = new PageReference(ApexPages.currentPage().getParameters().get('retURL'));

        return null;
    }

    public PageReference Cancel() {
        return pgReturnPage;
    }    

    public PageReference Save() {
        //commit the change to the tasks and return the user back to their retURL...

        errors = new List<String>();
        List<Task> tasksToUpdate = new List<Task>();

        if (!specificDateMethod && !variableDateMethod) errors.add('Select one operation before proceeding.');

        //If specific date, validate that has a value:
        if (specificDateMethod && !variableDateMethod && dummyTask.ActivityDate == null) errors.add('Specific Date is required.');

        //Else if variable, validate that has a value:
        else if (!specificDateMethod && variableDateMethod && variableValue == null) errors.add('Variable Date offset is required.');

        if (!errors.isEmpty()) return null;

        for (WrapperForTask wt : tskList) {
            if (wt.NewDueDate != null) {
                Task t = wt.task;
                t.ActivityDate = wt.NewDueDate;
                tasksToUpdate.add(t);
            }
        }

        if (tasksToUpdate.size() > 0) update tasksToUpdate;

        return pgReturnPage;
    }

    //Wrapper class for holding the new due date around the existing task object
    public class WrapperForTask
    {
        public Task task {get;set;}
        public Date NewDueDate {get; set;}

        public String PrettyNewDueDate {
            get {
                if (NewDueDate != null) return NewDueDate.format();       
                else return null;
            }
        }
    }
}