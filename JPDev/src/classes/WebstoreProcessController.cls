public with sharing class WebstoreProcessController 
{  
    private ApexPages.StandardController standardController;
 
    public WebstoreProcessController(ApexPages.StandardController standardController)
    {
        this.standardController = standardController;
    }

    // the variable being set from the commandbutton
    public String theWebstoreId {
        get;
        // *** setter is NOT being called ***
        set {
            theWebstoreId = value;
        }
    }
}