/*********************************************************
 * Modified by  : Naresh Kr Ojha (Appirio Off)
 * Modified On  : March 20th, 2013 for Task: T-125607
 *                Currency mapping for quote's currency
 ********************************************************/
public with sharing class zCC_PrimaryController {

    public String iframeSrc { get; set; }
    public String quoteID{get;set;}
    public String OppID{get;set;}
    public String refId{get;set;}
    public static String HPM_CUSTOM_SETTING{get;set;}
    public zqu__Quote__c currentQuote;
    private String errorMessage;
    private String errorCode;
    
    public boolean hasConfigError { get; set; }
    
    private String pageId;
    private String apiSecurityKey;
    private String appUrl; 
    private String tenantId; 
    
    
    public void onload(){
        quoteID = ApexPages.currentPage().getParameters().get('QID');
        //refId = ApexPages.currentPage().getParameters().get('refId');
        HPM_CUSTOM_SETTING = 'Zuora HPM Setting - USD';
        if(quoteID <> null || quoteID <> '') {
            currentQuote = [SELECT zqu__Currency__c, zqu__PaymentMethod__c, Id, IS_Verified__c FROM zqu__Quote__c WHERE ID =: quoteID];
            if (currentQuote <> null && currentQuote.zqu__Currency__c <> null) HPM_CUSTOM_SETTING = 'Zuora HPM Setting - '+currentQuote.zqu__Currency__c;
        }
        try {
            validateConfiguration(); 
        }
        catch( zCC_ConfigException e ) {
            hasConfigError = true;
            ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR, ErrorCodeMapping.VALUES.get( 'Sfdc.ErrorLoadingFrame' ) + e.getMessage() ) );
        }
        
        
      quoteID = ApexPages.currentPage().getParameters().get('QID');
      refId = null;   
      String token = EncodingUtil.convertToHex(Crypto.generateAesKey(128));
      String timestamp = String.valueOf(System.currentTimeMillis());
        
      String queryString = 'id=' + pageId + '&' +
          'tenantId=' + tenantId + '&' +
          'timestamp=' + timestamp + '&' +
          'token=' + token;
          
      String queryHashString = queryString + apiSecurityKey;
      String signature = EncodingUtil.base64Encode(Blob.valueOf(EncodingUtil.convertToHex(Crypto.generateDigest('MD5', Blob.valueOf(queryHashString)))));
      
      iframeSrc = appUrl + '/PublicHostedPage.do?method=requestPage&id=' + pageId + '&tenantId=' + tenantId + '&timestamp=' +timestamp + '&token=' + token
                  + '&signature=' + signature; 
                  
      Map<String, String> extraParameters = getExtraParameters(); 
      for ( String param : extraParameters.keySet() ) {
        iframeSrc += '&' + param + '=' + extraParameters.get( param ); 
      }
                    
      addCallBackfailure();
    }
    
    public String getExtraParamString() {
      String extraParam = ''; 
      Map<String, String> extraParameters = getExtraParameters(); 
      for ( String param : extraParameters.keySet() ) {
        extraParam += '&' + param + '=' + extraParameters.get( param ); 
      }
      return extraParam;
    } 
    
    /**
     * Specify extra HPM parameters that can be used to (1) Preload field values (2) Override default HPM properties.  Please see 
     * HPM Implementation Guide for a complete list of HPM parameters.
     */
    public Map<String, String> getExtraParameters() {
        return new Map<String, String> {
            'field_maxConsecutivePaymentFailures' => '1', 
            'field_maxConsecutivePaymentFailures' => '1', 
            'field_creditCardType' => 'Visa'
        }; 
    }
    
    private void validateRequiredFields(){
    
        quoteID = ApexPages.currentPage().getParameters().get('QID');
        
        if (quoteID == null || quoteId == '') throw new zCC_ConfigException('The Opportunity must have a Quote before a Credit Card Payment can be processed');
    }
    
    //I-49629  (rita)
    //Byrnes - commenting this entire sub out as it's not called.
    //private void validatePreviouslyProcessed(){
    //    zqu__Quote__c quote = [SELECT zqu__Opportunity__c, Id, zqu__Opportunity__r.ZuoraPaymentID__c, IS_Verified__c 
    //                           FROM zqu__Quote__c 
    //                           WHERE ID =: quoteID];
    //    
    //    if (quote.IS_Verified__c == true) throw new zCC_ConfigException('Not able to apply a new billing method to your Opportunity at this time as it’s already been processed. Please contact Customer Support');
    //}
    
    private void validateConfiguration(){
        validateRequiredFields(); 
        //validatePreviouslyProcessed();

        String PAYMENTMETHOD_CC = 'Credit Card';
        this.hasConfigError = false;
        HPM_Setting__c hpmSetting = HPM_Setting__c.getInstance( HPM_CUSTOM_SETTING );
        if ( hpmSetting == null ) throw new zCC_ConfigException( ErrorCodeMapping.VALUES.get( 'Sfdc.NoConfiguration' ) ); 
        
        String missingFields = ''; 
        this.pageId = hpmSetting.HPM_Page_Id__c; 
        if ( this.pageId == null || this.pageId.trim().length() == 0 ) missingFields += ' Page ID,';
        
        this.tenantId = hpmSetting.HPM_Tenant_Id__c; 
        if ( this.tenantId == null || this.tenantId.trim().length() == 0 ) missingFields += ' Tenant ID,';
        
        this.apiSecurityKey = hpmSetting.HPM_Security_Token__c; 
        if ( this.apiSecurityKey == null || this.apiSecurityKey.trim().length() == 0 ) missingFields += ' Security Token,';
        
        this.appUrl = hpmSetting.HPM_App_Url__c; 
        if ( this.appUrl == null || this.appUrl.trim().length() == 0 ) missingFields += ' App URL,'; 
        
        if ( missingFields.length() > 0 ) {
            missingFields = missingFields.substring( 0, missingFields.length() - 1 );
            throw new zCC_ConfigException( ErrorCodeMapping.VALUES.get( 'Sfdc.InvalidConfiguration' ) + missingFields );
        }
        
        if (quoteID <> null && String.valueOf(quoteID).length() > 0 && currentQuote <> null && currentQuote.ID <> null) {
          if (currentQuote <> null && currentQuote.zqu__PaymentMethod__c <> PAYMENTMETHOD_CC) throw new zCC_ConfigException(  'We’re unable to process your request at this time. Please contact your Account Representative to modify your billing method. The current billing method indicated is '+currentQuote.zqu__PaymentMethod__c );
          if (currentQuote <> null && currentQuote.IS_Verified__c == true) throw new zCC_ConfigException(  'We’re not able to apply a new billing method to you order at this time as it’s already been processed. Please contact Customer Support.' );
        }

        
      Map<String, String> paramMap = ApexPages.currentPage().getParameters(); 
      String errorCode = paramMap.get( 'errorCode' ); 
      if ( errorCode == 'Invalid_Security' || errorCode == 'InvalidCallbackSecurity' ) this.hasConfigError = true; 
    }
    
    private void addCallBackfailure(){
        errorMessage = '';
        errorCode = '';
        
        PageReference curPage = System.currentPageReference();
        
        errorMessage = curPage.getParameters().get('errorMessage');
        errorCode = curPage.getParameters().get('errorCode');
        
        final String DefaultErrorPrefix = 'An error has occurred'; 
        String error = ''; 
        
        if ( errorCode != null && errorCode != '' ) {
            boolean unknownErrorCode = false; 
            error = ErrorCodeMapping.VALUES.get( errorCode ); 
            if ( error == null ) { 
                error = DefaultErrorPrefix; 
                unknownErrorCode = true;
            }
          if ( errorMessage != null  && errorMessage != '' ) error += ( ': ' + errorMessage );   
          else if ( unknownErrorCode ) error += ( ': ' + errorCode ); 

          ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR, error ) );   
          iframeSrc += '&retainValues=true';        
          if ( errorCode == 'InvalidCallbackSecurity' ) return; 
        }
        
        List<String> validationErrors = new List<String>();
        for ( String errorField : ErrorCodeMapping.ERROR_FIELD_MAPPING.keySet() ) {
            String errorFieldValue = curPage.getParameters().get( errorField ); 
            if ( errorFieldValue != null && errorFieldValue.trim().length() > 0 ) validationErrors.add( ErrorCodeMapping.ERROR_FIELD_MAPPING.get( errorField ) + ': ' + ErrorCodeMapping.VALUES.get( errorFieldValue ) ); 
        }
        if ( validationErrors.size() > 0 ) {
            validationErrors.sort(); 
            for ( String validationError : validationErrors ) {
              ApexPages.addMessage( New ApexPages.Message( ApexPages.Severity.ERROR, validationError ) );
            }
        }
    }
}