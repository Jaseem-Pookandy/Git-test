@isTest(SeeAllData=true)
private class DailyProductivityExt_Test {

    static testMethod void testMethod1(){
     
    	ApexPages.Standardcontroller sc;
    	CreateData();
    
    	PageReference pageRef = Page.DailyProductivity;
    	pageRef.getParameters().put('retURL', '%2Fhome%2Fhome.jsp');
    
    	Test.setCurrentPage(pageRef);
          
    	DailyProductivityExt controller = new DailyProductivityExt(sc); 
    
        pageRef = controller.Cancel();
    
    	PageReference pageRefCancel = new PageReference('/home/home.jsp');
    
    	
    }

    static testMethod void testMethod2(){

        CreateData();
         
        Id dayID = [SELECT Id FROM Daily_Productivity__c LIMIT 1].Id;
        
        ApexPages.Standardcontroller sc;
        
        PageReference pageRef = Page.DailyProductivity;
        pageRef.getParameters().put('retURL', '/home/home.jsp');
        pageRef.getParameters().put('Id', dayID);
        
        Test.setCurrentPage(pageRef);
              
        DailyProductivityExt controller = new DailyProductivityExt(sc);    
        
        controller.theDay.Dials_Completed__c = 100;
        controller.theDay.Entry_Date__c = System.today();   
        controller.theDay.Number_of_Demos__c = 4;
        controller.theDay.Total_Dollars_Sold__c = 5;
        controller.RecalcScore();

        controller.Save();    	    

        
    }
    
    static testMethod void testMethod3(){
        ApexPages.Standardcontroller sc;
        
        PageReference pageRef = Page.DailyProductivity;
        pageRef.getParameters().put('retURL', '/home/home.jsp');
        
        Test.setCurrentPage(pageRef);
              
        DailyProductivityExt controller = new DailyProductivityExt(sc);          
        controller.theDay.Dials_Completed__c = 100;
        controller.theDay.Entry_Date__c = System.today();   
        controller.theDay.Number_of_Demos__c = 4;
        controller.theDay.Total_Dollars_Sold__c = 5;
        controller.theDay.Total_Talk_Time__c = 500;
        controller.RecalcScore();
        
        //controller.Save(); 
        
    } 
    static testMethod void testMethod4(){

        CreateData();
         
        Id dayID = [SELECT Id FROM Daily_Productivity__c LIMIT 1].Id;
        
        ApexPages.Standardcontroller sc;
        
        PageReference pageRef = Page.DailyProductivity;
        pageRef.getParameters().put('retURL', '/home/home.jsp');
        pageRef.getParameters().put('Id', dayID);
        
        Test.setCurrentPage(pageRef);
              
        DailyProductivityExt controller = new DailyProductivityExt(sc);    
        
        controller.theDay.Dials_Completed__c = -1;
        controller.theDay.Entry_Date__c = System.today();   
        controller.theDay.Number_of_Demos__c = -1;
        controller.theDay.Total_Dollars_Sold__c = -1;
        controller.theDay.Total_Talk_Time__c = -1;
        controller.RecalcScore();
        controller.theDay.Dials_Completed__c = 0;
        controller.theDay.Entry_Date__c = System.today();   
        controller.theDay.Number_of_Demos__c = 0;
        controller.theDay.Total_Dollars_Sold__c = 0;
        controller.theDay.Total_Talk_Time__c = 0;
        controller.RecalcScore();

        controller.Save();    	    

        
    }    
  static void CreateData() {
          
  }
    
}