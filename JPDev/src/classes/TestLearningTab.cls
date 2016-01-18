/* (c) 2012 Appirio, Inc.
* 2012/06/06     Cory McIlroy    init
*/
@isTest
private class TestLearningTab {


    static testMethod void TestLearningTabContentController() {
        //Case-1, front page:
        createLearningContent();
        Test.startTest();
        LearningTabContentController testController = new LearningTabContentController();
        testController.myContentType = 'frontPage';
        System.assert(testController.getContentByCategory() != null, 'Fails initial check for contentList');        
        System.assert(testController.getHighlight() != null, 'Fails initial check for highlight');        
        System.assert(testController.getPath() != null, 'Fails initial check for Learning Path');        
        System.assert(testController.getRecentlyUploaded() != null, 'Fails initial check for getRecentlyUploaded');        
        
        Test.stopTest();
        
    }
    
    static testMethod void TestLearningTabContentController_1() {
        //Case-1, Getting Started
        createLearningContent();
        Test.startTest();
        LearningTabContentController testController = new LearningTabContentController();
        testController.myContentType = 'Getting Started';
        System.assert(testController.getPath() != null, 'Fails initial check for Learning Path when Getting Started');        
        System.assert(testController.getHighlight() != null, 'Fails "Getting Started" check for highlight');        
        testController.myContentType = 'Videos';
        System.assert(testController.getRecentlyUploaded() != null, 'Fails initial check for getRecentlyUploaded on Videos tab');        
        System.assert(testController.getName() != null, 'Fails initial check for getRecentlyUploaded on Videos tab');        
        Test.stopTest();
        
    }

    private static void createLearningContent() {
        insert new List<Learning_Content_Listing__c>{
            new Learning_Content_Listing__c(
                    Content_Title__c = 'blah'
                    ,Content_URI__c = 'blah'
                    ,Front_Page__c = true
                    ,Highlight__c = true
                    ,Featured_Item__c = true
                    ,Tab__c = 'Videos'
                    ,Category__c = 'Getting Started'
                    ,Content_Format__c = 'Video'
                    ,Content_Type__c = 'Overview'
                    ,Status__c = 'Published'
            )
            ,new Learning_Content_Listing__c(
                    Content_Title__c = 'blah'
                    ,Content_URI__c = 'blah'
                    ,Front_Page__c = false
                    ,Highlight__c = true
                    ,Featured_Item__c = true
                    ,Tab__c = 'Videos'
                    ,Category__c = 'Getting Started'
                    ,Content_Format__c = 'Video'
                    ,Content_Type__c = 'Overview'
                    ,Status__c = 'Published'
            )
        };
    }
}