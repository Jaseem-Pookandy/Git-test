public class SandboxPostDeploymentController {

    public Boolean isSandbox{get;set;}

    public Organization myOrg{get;set;}
    public String inputEmailMask{get;set;} // input value from vf
    public String inputLeadEmailMask{get;set;}
    public String inputAltEmailMask{get;set;}

    public Boolean ContactEmailComplete{get{

        return PDSMap.get('Contact Email Mask').Complete__c;

    }set;}    

    public Boolean LeadEmailComplete{get{

        return PDSMap.get('Lead Email Mask').Complete__c;

    }set;}  

    public Boolean AltEmailComplete{get{

        return PDSMap.get('Alternate Email Mask').Complete__c;

    }set;}  

    public PostDeploymentSteps__c pds {get; set;}
    public Map<String, PostDeploymentSteps__c> PDSMap {get; set;}
    
    //Contructor
    public SandboxPostDeploymentController() {
        PDSMap = PostDeploymentSteps__c.getAll();
   
        myOrg = [Select o.OrganizationType, o.Name, o.Id From Organization o LIMIT 1];
        system.debug('$$$$$$$$$$' + myOrg.Name); 
        isSandbox = isSandbox();
    }
    
     

     public PageReference runMaskContactEmail()
	   {
      batchMaskContactEmail batch = new batchMaskContactEmail(); 
      batch.appendText = inputEmailMask;
      if(!Test.isRunningTest()) Database.executeBatch(batch);

      //now update hte Custom Setting to indicate that this is done
      PostDeploymentSteps__c pds = PostDeploymentSteps__c.getValues('Contact Email Mask');
      pds.Complete__c = true;
      update pds;

      PDSMap = PostDeploymentSteps__c.getAll();
      return null;

	   }
    

    public PageReference runMaskLeadEmail()
    {
      batchMaskLeadEmail batch = new batchMaskLeadEmail(); 
      batch.appendText = inputLeadEmailMask;
      if(!Test.isRunningTest()) Database.executeBatch(batch);

      //now update hte Custom Setting to indicate that this is done
      PostDeploymentSteps__c pds = PostDeploymentSteps__c.getValues('Lead Email Mask');
      pds.Complete__c = true;
      update pds;

      PDSMap = PostDeploymentSteps__c.getAll();
      return null;

     }

     public PageReference runMaskAltEmail()
     {
      batchMaskAltEmail batch = new batchMaskAltEmail(); 
      batch.appendText = inputAltEmailMask;
      if(!Test.isRunningTest()) Database.executeBatch(batch);

      //now update hte Custom Setting to indicate that this is done
      PostDeploymentSteps__c pds = PostDeploymentSteps__c.getValues('Alternate Email Mask');
      pds.Complete__c = true;
      update pds;

      PDSMap = PostDeploymentSteps__c.getAll();
      return null;

     }

         public Static Boolean isSandbox(){

        String host = URL.getSalesforceBaseUrl().getHost();
        String server = host.substring(0,host.indexOf('.'));
 

        //check for cs in the host meaning it is a sandbox
        if(host.contains('.cs'))
            return true;
 
        // tapp0 is a unique "non-cs" server so we check it now
        if(server == 'tapp0')
            return true;
 
        // If server is 'cs' followed by a number it's a sandbox
        if(server.length()>2){
            if(server.substring(0,2)=='cs'){
                try{
                    Integer.valueOf(server.substring(2,server.length()));
                }
                catch(exception e){
                    //started with cs, but not followed by a number
                    return false;
                }
 
                //cs followed by a number, that's a hit
                return true;
            }
        }
 
        // If we made it here it's a production box
        return false;
    }
}