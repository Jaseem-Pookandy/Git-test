public with sharing class DailyProductivityExt {

    public Daily_Productivity__c theDay {get; set;}
    public List<String> errors {get; set;}    
    public List<String> savemessage {get; set;}
    private PageReference pgReturnPage {get; set;}

    public String pgContext {get;set;}

    public Decimal theScore {get; set;}

    public User currentUser {get; set;}

    //public DPDials__c dials {get; set;}
    //public DPDemos__c demos {get; set;}


    public DailyProductivityExt(ApexPages.StandardController con)
    {
        pgContext = ApexPages.currentPage().getParameters().get('Id');
        if (pgContext == null) PrepPageForNewDay();    
        else PrepPageForEdit();  
    }   


    public void PrepPageForEdit(){
        theDay = getDay();

        if (theDay.Quotes_Built_Score__c == null) theDay.Quotes_Built_Score__c = 0;
        if (theDay.Total_Dollars_Sold_Score__c == null) theDay.Total_Dollars_Sold_Score__c = 0;
        if (theDay.Total_Talk_Time_Score__c == null) theDay.Total_Talk_Time_Score__c = 0;
        if (theDay.Number_of_Demos_Score__c == null) theDay.Number_of_Demos_Score__c = 0;
        if (theDay.Dials_Completed_Score__c == null) theDay.Dials_Completed_Score__c = 0;

        theScore = theDay.Dials_Completed_Score__c + theDay.Number_of_Demos_Score__c + theDay.Total_Talk_Time_Score__c + theDay.Total_Dollars_Sold_Score__c + theDay.Quotes_Built_Score__c;
        currentUser = [SELECT Username, Id, DefaultBrand__c, ManagerId FROM User WHERE Id = :theDay.OwnerId];
    }
    
    public Daily_Productivity__c getDay(){

        savemessage = new List<String>();
        pgReturnPage = new PageReference(ApexPages.currentPage().getParameters().get('retURL'));
        errors = new List<String>();

        String query = 'SELECT Id, Name, OwnerId, Notes__c, Sales_Manager__c, Default_Brand__c, Level__c, Dials_Completed__c, Dials_Completed_Score__c, Entry_Date__c, I_worked_on_this_date__c, Locked__c, Number_of_Demos__c, Number_of_Demos_Score__c, Total_Dollars_Sold__c, Total_Dollars_Sold_Score__c, Sales_Executive_Entry_Date__c, Total_Score__c, Total_Talk_Time__c, Total_Talk_Time_Score__c, Sales_Manager_Id__c, Quotes_Built__c, Quotes_Built_Score__c  FROM Daily_Productivity__c WHERE Id = \'' + pgContext + '\'';

        return Database.query(query); 

    }

    private void PrepPageForNewDay(){

        pgReturnPage = new PageReference(ApexPages.currentPage().getParameters().get('retURL'));
        savemessage = new List<String>();
        theDay = new Daily_Productivity__c();

        theDay.OwnerId = Userinfo.getUserId();

        currentUser = [SELECT Username, Id, DefaultBrand__c, ManagerId FROM User WHERE Id = :theDay.OwnerId];

        theDay.Dials_Completed_Score__c = 0;
        theDay.Number_of_Demos_Score__c = 0;
        theDay.Total_Talk_Time_Score__c = 0;
        theDay.Total_Dollars_Sold_Score__c = 0;
        theDay.Quotes_Built_Score__c = 0;

        theScore = 0;

        errors = new List<String>();


    }       

    public PageReference Save()
    {

        savemessage = new List<String>();
        errors = new List<String>();

        try { upsert theDay; }
        catch (DMLException e ) {
            errors.add('Your change could not be saved.  You may already have a daily productivity entry for this date.  The folowing message can be provided to a system administer.');
            errors.add(e.GetMessage());
            return null;
        }
        String retURL = ApexPages.currentPage().getParameters().get('retURL');
        String CurrentId = ApexPages.currentPage().getParameters().get('id');
        PageReference redirectPG;
        if(retURL != null)
            redirectPG = new PageReference('/' + retURL);
        else if(CurrentId != null)
            redirectPG = new PageReference('/' + CurrentId);
            
        savemessage.add('Your change has been saved.  You may navigate away from this page or continue to make changes');
        
        return redirectPG;
    } 
     
    public PageReference Cancel() {
      return pgReturnPage;
    }

    public PageReference RecalcScore() {

        if (theDay.OwnerId != null) currentUser = [SELECT Username, Id, DefaultBrand__c, ManagerId FROM User WHERE Id = :theDay.OwnerId];
        
        if(theDay.Dials_Completed__c != null && theDay.Dials_Completed__c >= 0) {
            Daily_Productivity_Setup__c[] PDS = [SELECT Score__c from Daily_Productivity_Setup__c where Min__c <= :theDay.Dials_Completed__c AND Max__c >= :theDay.Dials_Completed__c AND Metrics_Type__c = 'Dials Completed' AND Brand__c = :currentUser.DefaultBrand__c LIMIT 1];
            if (PDS.size() > 0) theDay.Dials_Completed_Score__c = PDS[0].Score__c;
            else theDay.Dials_Completed_Score__c = 0;
        }
        else theDay.Dials_Completed_Score__c = 0;

        //if(theDay.Dials_Completed__c != null && theDay.Dials_Completed__c >= 0) theDay.Dials_Completed_Score__c = [SELECT Score__c from Daily_Productivity_Setup__c where Min__c <= :theDay.Dials_Completed__c AND Max__c >= :theDay.Dials_Completed__c AND Metrics_Type__c = 'Dials Completed' AND Brand__c = :theDay.Default_Brand__c LIMIT 1].Score__c;
        //else theDay.Dials_Completed_Score__c = 0;

        if(theDay.Number_of_Demos__c != null && theDay.Number_of_Demos__c >= 0) {
            Daily_Productivity_Setup__c[] PDS = [SELECT Score__c from Daily_Productivity_Setup__c where Min__c <= :theDay.Number_of_Demos__c AND Max__c >= :theDay.Number_of_Demos__c AND Metrics_Type__c = 'Number of Demos' AND Brand__c = :currentUser.DefaultBrand__c LIMIT 1];
            if (PDS.size() > 0) theDay.Number_of_Demos_Score__c = PDS[0].Score__c;
            else theDay.Number_of_Demos_Score__c = 0;
        }
        else theDay.Number_of_Demos_Score__c = 0;

        //if(theDay.Number_of_Demos__c != null && theDay.Number_of_Demos__c >= 0) theDay.Number_of_Demos_Score__c = [SELECT Score__c from Daily_Productivity_Setup__c where Min__c <= :theDay.Number_of_Demos__c AND Max__c >= :theDay.Number_of_Demos__c AND Metrics_Type__c = 'Number of Demos' AND Brand__c = :theDay.Default_Brand__c LIMIT 1].Score__c;
        //else theDay.Number_of_Demos_Score__c = 0;

        if(theDay.Total_Talk_Time__c != null && theDay.Total_Talk_Time__c >= 0) {
            Daily_Productivity_Setup__c[] PDS = [SELECT Score__c from Daily_Productivity_Setup__c where Min__c <= :theDay.Total_Talk_Time__c AND Max__c >= :theDay.Total_Talk_Time__c AND Metrics_Type__c = 'Total Talk Time' AND Brand__c = :currentUser.DefaultBrand__c LIMIT 1];
            if (PDS.size() > 0) theDay.Total_Talk_Time_Score__c = PDS[0].Score__c;
            else theDay.Total_Talk_Time_Score__c = 0;
        }
        else theDay.Total_Talk_Time_Score__c = 0;

        //if(theDay.Total_Talk_Time__c != null && theDay.Total_Talk_Time__c >= 0) theDay.Total_Talk_Time_Score__c = [SELECT Score__c from Daily_Productivity_Setup__c where Min__c <= :theDay.Total_Talk_Time__c AND Max__c >= :theDay.Total_Talk_Time__c AND Metrics_Type__c = 'Total Talk Time' AND Brand__c = :theDay.Default_Brand__c LIMIT 1].Score__c;
        //else theDay.Total_Talk_Time_Score__c = 0;

        if(theDay.Total_Dollars_Sold__c != null && theDay.Total_Dollars_Sold__c >= 0) {
            Daily_Productivity_Setup__c[] PDS = [SELECT Score__c from Daily_Productivity_Setup__c where Min__c <= :theDay.Total_Dollars_Sold__c AND Max__c >= :theDay.Total_Dollars_Sold__c AND Metrics_Type__c = 'Opportunities Built' AND Brand__c = :currentUser.DefaultBrand__c LIMIT 1];
            if (PDS.size() > 0) theDay.Total_Dollars_Sold_Score__c = PDS[0].Score__c;
            else theDay.Total_Dollars_Sold_Score__c = 0;
        }   
        else theDay.Total_Dollars_Sold_Score__c = 0;

        //if(theDay.Total_Dollars_Sold__c != null && theDay.Total_Dollars_Sold__c >= 0) theDay.Total_Dollars_Sold_Score__c = [SELECT Score__c from Daily_Productivity_Setup__c where Min__c <= :theDay.Total_Dollars_Sold__c AND Max__c >= :theDay.Total_Dollars_Sold__c AND Metrics_Type__c = 'Opportunities Built' AND Brand__c = :theDay.Default_Brand__c LIMIT 1].Score__c;
        //else theDay.Total_Dollars_Sold_Score__c = 0;
        
        if(theDay.Quotes_Built__c != null && theDay.Quotes_Built__c >= 0) {
            Daily_Productivity_Setup__c[] PDS = [SELECT Score__c from Daily_Productivity_Setup__c where Min__c <= :theDay.Quotes_Built__c AND Max__c >= :theDay.Quotes_Built__c AND Metrics_Type__c = 'Quotes Built' AND Brand__c = :currentUser.DefaultBrand__c LIMIT 1];
            if (PDS.size() > 0) theDay.Quotes_Built_Score__c = PDS[0].Score__c;
            else theDay.Quotes_Built_Score__c = 0;
        }   
        else theDay.Quotes_Built_Score__c = 0;

        theScore = theDay.Dials_Completed_Score__c + theDay.Number_of_Demos_Score__c + theDay.Total_Talk_Time_Score__c + theDay.Total_Dollars_Sold_Score__c + theDay.Quotes_Built_Score__c;

        return null;
    }

}