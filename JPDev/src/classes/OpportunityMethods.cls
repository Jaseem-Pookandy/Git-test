/***
*Class          ---- OpportunityMethods
*Author         ---- Sravya Mogili
*Story          ---- CCBOB-95
*Created Date   ---- 2015.12.12
*Description    ---- Upon Close-Win of an Opportunity, if the synced quote’s ‘Sold To’ address 
                     is in either UK, Australia or Eurozone,VAT/GST Tax id field required 
                     for defined set of customers
                     
----------------------------- Modifications & Updates -----------------------------
*Modified By    ---- 
*Story          ---- 
*Modified Date  ---- 
*Description    ---- 
***/
public without sharing class OpportunityMethods {

    public static void createFeedCommentOnOpportunity(Map<ID,Boolean>MapOpps){
        List<Opportunity> OpportunityList = new List<Opportunity>();
        String ChatterPostText;
        OpportunityList = [select Id,OwnerId from Opportunity where Id IN:MapOpps.keyset()];
        
        for(Opportunity OppObj:OpportunityList){
           try{
           
             if(MapOpps.get(OppObj.id)== true)
                ChatterPostText = System.Label.Chatter_Post_VAT_Required; 
             else 
                ChatterPostText = System.Label.Chatter_Post_VAT_Suggested; 
            ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
            messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();


            ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
            mentionSegment.id = OppObj.OwnerId; // The ID of the user to mention.
            messageInput.messageSegments.add(mentionSegment);

            ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
            textSegment.text = ChatterPostText ;
            messageInput.messageSegments.add(textSegment);

            ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
            input.body = messageInput;
            input.subjectId = OppObj.id;

            ConnectApi.FeedElement fi = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), input, null);          
           
           
           }Catch(Exception e){
           }
          
        }
        
    } 
}