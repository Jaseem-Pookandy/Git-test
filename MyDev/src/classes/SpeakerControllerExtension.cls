public with sharing class SpeakerControllerExtension {
   
    private final Speaker__c speaker;
    public blob picture {get;set;}
    Public string errormessage {get;set;}
    public speakercontrollerExtension(Apexpages.StandardController stdcontroller){
        this.speaker = (Speaker__c)stdController.getRecord();

    }
    
    Public pagereference save(){
        errormessage = '';
        try{
            upsert Speaker;
            if(picture!=null){
                Attachment attachment = new attachment();
                attachment.Body= picture;
                attachment.name = 'speaker_' + speaker.id + '.jpg';
				attachment.parentid = speaker.id;
				attachment.ContentType = 'application/jpg';
				insert attachment;
				speaker.Picture_Path__c = '/servlet/servlet.FileDownload?file='
				+ attachment.id;
				update speaker;
            }
            return new ApexPages.StandardController(speaker).view();
        }catch(System.Exception ex) {
            errorMessage = ex.getMessage();
			return null;
        }
    }
}