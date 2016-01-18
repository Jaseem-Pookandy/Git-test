public with sharing class LearningTabContentController {

    private String contentAtIndexId;
    //public String str{get; set;}
    //public String strRecent{get; set;}
    public String myContentType{get;set;}
    public String myContentQueryType{get;set;}
    //public String contentListJson {get; set;}

    public String publisherId{get;set;}
    //public String userName{get;set;}
    public List<User> getUserName { get; set; }
    public Integer sIndex{ get; set; }
    public Learning_Content_Listing__c contentAtIndex{get;set;}
    //public List<Learning_Content_Listing__c> contentList{get;set;}
    public LearningTabContentController(){
        contentAtIndex = new Learning_Content_Listing__c();
        getUserName = [select FullPhotoUrl from User where Id = '005E0000000dTVhIAM'];
        
    }
    
    /* Used for Recommended Sidebar. Sorry about the unfortunate choice of name for the method. will fix someday. */
    //TODO, see mark's note above
    public String getName() {
        String myStr = JSON.serialize([SELECT Id, Publisher_User_Name__c, CreatedDate, Category__c,Version__c , Preview_URL__c, Content_Format__c, Content_Length__c, Name, Content_Title__c, Content_Type__c, Content_URI__c, Date_Published__c, Description__c, Display_order__c, Featured_Item__c FROM Learning_Content_Listing__c  WHERE (Tab__c = :myContentType AND Featured_Item__c = true) ORDER by Display_order__c]);
        System.debug('Serialized content List: ' + myStr);
        return myStr;
        //return 'MyController';
    }
   
       
    /* Used for Main content on tab 2, 3.  */
    public String getContentByCategory() {
        String myStr = JSON.serialize([SELECT Id, Publisher_User_Name__c, CreatedDate, Category__c,Version__c , Preview_URL__c, Content_Format__c, Content_Length__c, Name, Content_Title__c, Content_Type__c, Content_URI__c, Date_Published__c, Description__c, Display_order__c, Featured_Item__c FROM Learning_Content_Listing__c  WHERE Tab__c = :myContentType Order by Category__c,Display_order__c]);
        //System.debug('Serialized content List: ' + myStr);
        return myStr;
        //return 'MyController';
    }
   
    /* Get highlight video(s).  */
    public String getHighlight() {
        String myStr;
        if (myContentType == 'frontPage') { //look for front-page flag in content. 
            myStr = JSON.serialize([SELECT Id, Publisher_User_Name__c, CreatedDate, Category__c,Version__c , Preview_URL__c, Content_Format__c, Content_Length__c, Name, Content_Title__c, Content_Type__c, Content_URI__c, Date_Published__c, Description__c, Display_order__c, Highlight__c FROM Learning_Content_Listing__c  WHERE (Front_Page__c = true) LIMIT 1 ]);
        }
        else {
            myStr = JSON.serialize([SELECT Id, Publisher_User_Name__c, CreatedDate, Category__c,Version__c , Preview_URL__c, Content_Format__c, Content_Length__c, Name, Content_Title__c, Content_Type__c, Content_URI__c, Date_Published__c, Description__c, Display_order__c, Highlight__c FROM Learning_Content_Listing__c  WHERE (Tab__c = :myContentType AND Highlight__c = true) Order by Display_order__c ]);
        }
        return myStr;
        //return 'MyController';
    }
   
    /* Get learning path.  */
    public String getPath() {
        String myStr;
        if (myContentType == 'Getting Started') { //if learning path on first page...
            myStr = JSON.serialize([SELECT Id, Publisher_User_Name__c, CreatedDate, Category__c,Version__c , Preview_URL__c, Content_Format__c, Content_Length__c, Name, Content_Title__c, Content_Type__c, Content_URI__c, Date_Published__c, Description__c, Display_order__c, Featured_Item__c FROM Learning_Content_Listing__c  WHERE Category__c = :myContentType Order by Display_order__c]);
        } 
        else myStr = JSON.serialize([SELECT Id, Publisher_User_Name__c, CreatedDate, Category__c,Version__c , Preview_URL__c, Content_Format__c, Content_Length__c, Name, Content_Title__c, Content_Type__c, Content_URI__c, Date_Published__c, Description__c, Display_order__c, Featured_Item__c FROM Learning_Content_Listing__c  WHERE (Tab__c = :myContentType AND Featured_Item__c = true) ORDER by Display_order__c]);

        return myStr;
    }
    
    /* Used for Recently Uploaded Component Sidebar.*/
    public String getRecentlyUploaded() {
        String myStr;
        if ((myContentType =='Guides') || (myContentType == 'Videos')) { //return only videos or guides
                         myStr = JSON.serialize([SELECT Id, Publisher_User_Name__c, CreatedDate, Category__c,Version__c , Content_Format__c, Content_Length__c, Name, Content_Title__c, Content_Type__c,Content_URI__c, Date_Published__c, Description__c, Display_order__c, Preview_URL__c, Featured_Item__c FROM Learning_Content_Listing__c WHERE Tab__c = :myContentType Order by Date_Published__c desc LIMIT 4]);
        }
        else { //return everything new
            myStr = JSON.serialize([SELECT Id, Publisher_User_Name__c, CreatedDate, Category__c,Version__c , Content_Format__c, Content_Length__c, Name, Content_Title__c, Content_Type__c,Content_URI__c, Date_Published__c, Description__c, Display_order__c, Preview_URL__c, Featured_Item__c FROM Learning_Content_Listing__c Order by Date_Published__c desc LIMIT 4]);
        }
        return myStr;
    }
   
}