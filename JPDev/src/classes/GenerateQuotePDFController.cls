public with sharing class GenerateQuotePDFController {
    
    //public stuff - referenced on the .page file
    public zqu__Quote__c thisQuote {get; set;}
    public List<String> errors {get; set;}  
    public List<SelectOption> soldByOptions {get; set;}
    public List<SelectOption> detailLevelOptions {get; set;}
    public List<SelectOption> languageOptions {get; set;}
    public String soldByValue {get; set;}
    public String detailLevelValue {get; set;}  
    public String languageValue {get; set;}  
    public List<QuoteTemplateWrapper> foundTemplatesWrapped {get; set;}
    public Boolean showPreview {get; set;}
    public Boolean closeWindow {get; set;}

    public String attachmentId {get; set;}          //Zuora will set this...
    public String previewAttachmentURL {get; set;}
    public String selectedTemplateId {get; set;}

    //private stuff
    private Id quoteId {get; set;}
    private List<zqu__Quote_Template__c> foundTemplates {get; set;}
    //TBD...

    public GenerateQuotePDFController(ApexPages.StandardController controller) {

        PrepPage();
    }

    private void PrepPage() {

        attachmentId = null;
        showPreview = false;
        closeWindow = false;
	
        previewAttachmentURL = null;
		
		foundTemplatesWrapped = new List<QuoteTemplateWrapper>();
        detailLevelValue = '*';
        errors = new List<String>();
        foundTemplates = new List<zqu__Quote_Template__c>();
		map<string,BrandTag_EfC_Intl__c> BrandTaG_Intl = BrandTag_EfC_Intl__c.getAll();//brand tags that needs region on the quote
		
        quoteId = ApexPages.currentPage().getParameters().get('QID');
        if (quoteId == null) {
            errors.add('Missing querystring parameter QID.  Close this window, refresh the Quote page you came from and give it another shot.');
            return;
        }

        List<zqu__Quote__c> quotes = [SELECT Id, Name, BrandTag__c, zqu__SoldToContact__c, zqu__SoldToContact__r.Language__c, Quote_Template_Region__c, zqu__Opportunity__c, zqu__Opportunity__r.Sold_By_Partner__c FROM zqu__Quote__c WHERE Id = :quoteId LIMIT 1];

        if (quotes != null && quotes.size() == 1) {

            thisQuote = quotes[0];

            //SoldBy value...
            if (thisQuote.zqu__Opportunity__r.Sold_By_Partner__c == null) soldByValue = 'Direct Sale';
            else soldByValue = 'Agency Sale';

            //Language
            if (thisQuote.zqu__SoldToContact__c != null && thisQuote.zqu__SoldToContact__r.Language__c != null) languageValue = thisQuote.zqu__SoldToContact__r.Language__c;
            else languageValue = 'English';
            
            if(BrandTaG_Intl.containskey(thisQuote.BrandTag__c) && thisQuote.Quote_Template_Region__c == null){
	            	errors.add('Missing Region field on Quote; Return to the Quote and select one of the available region names in the list');
            	return;
            }
            

        }
        else {
            errors.add('Unable to find the source Quote.  Close this window, refresh the Quote page you came from and give it another shot.');
            return; 
        }

        SetSoldByOptions();
        SetDetailLevelOptions();
        SetLanguageOptions();

        RefreshTemplates();
    }

    public PageReference SearchQuoteTemplates() {

        //Reset this to false to eliminate unrequested previews...
        showPreview = false;

        //Reset the errors list...
        errors = new List<String>();

        DeletePreviouslyPreviewedFile();

        RefreshTemplates();

        return null;
    }

    //Redo this to purge off of Zuora's cloud storage???
    private void DeletePreviouslyPreviewedFile() {

        //If there is a previously previewed file, kill it...
        if (attachmentId != null) {
            Attachment a = new Attachment(Id = attachmentId);
            delete a;
            attachmentId = null;
            previewAttachmentURL = null;
        }
    }

    private List<SelectOption> SetSoldByOptions() {
        soldByOptions = new List<SelectOption>();

        for (AggregateResult ar : [SELECT Sold_By__c FROM zqu__Quote_Template__c WHERE Sold_By__c != null AND Sold_By__c != 'Invalid Format' GROUP BY Sold_By__c]) {

            if ((String)ar.get('Sold_By__c') != 'Unexpected Value') soldByOptions.add(new SelectOption((String)ar.get('Sold_By__c'), (String)ar.get('Sold_By__c')));
        }       

        //Add the '*' only if it's empty
        if (soldbyOptions.isEmpty()) soldByOptions.add(new SelectOption('*', '*'));        

        return soldByOptions;
    }

    private List<SelectOption> SetLanguageOptions() {
        languageOptions = new List<SelectOption>();
        Boolean bAdded = false;

        for (AggregateResult ar : [SELECT Language__c FROM zqu__Quote_Template__c WHERE Language__c != null AND Language__c != 'Invalid Format' GROUP BY Language__c]) {

            if ((String)ar.get('Language__c') != 'Unexpected Value') languageOptions.add(new SelectOption((String)ar.get('Language__c'), (String)ar.get('Language__c')));
            if (ar.get('Language__c') == languageValue) bAdded = true;
        }       

        //Add the contact's default value only if the default language was not in the list
        if (bAdded == false) languageOptions.add(new SelectOption(languageValue, languageValue));

        return languageOptions;
    }       

    private List<SelectOption> SetDetailLevelOptions() {
        detailLevelOptions = new List<SelectOption>();

        //First, add the '*'
        detailLevelOptions.add(new SelectOption('*', '*'));

        for (AggregateResult ar : [SELECT Detail_Level__c FROM zqu__Quote_Template__c WHERE Detail_Level__c != null AND Detail_Level__c != 'Invalid Format' GROUP BY Detail_Level__c]) {

            if ((String)ar.get('Detail_Level__c') != 'Unexpected Value') detailLevelOptions.add(new SelectOption((String)ar.get('Detail_Level__c'), (String)ar.get('Detail_Level__c')));
        }       

        return detailLevelOptions;
    }

    private void RefreshTemplates() {
        foundTemplates = new List<zqu__Quote_Template__c>();
        foundTemplatesWrapped = new List<QuoteTemplateWrapper>();		
		String BrandValue; // brand tag string value based on the quote template region logic
		if(thisQuote.Quote_Template_Region__c == null)
			BrandValue =thisQuote.BrandTag__c; // region is null, means brand tag is not any of the eFC intl, go ahead with quote brand tag
		else {
			list<string>Brandtagsplit= thisQuote.BrandTag__c.split('-');
			BrandValue =Brandtagsplit[0]; //if this is a eFC intl scneario, then default this to just eFC as the quote templates are no longer one to one for these brand tags
		}
        String soql = 'SELECT Id, Name, Language__c, BrandTag__c, Detail_Level__c, Sold_By__c, Display_Name__c, zqu__Template_Id__c FROM zqu__Quote_Template__c WHERE Sold_By__c = \'' + soldByValue + '\' AND Language__c = \'' + languageValue + '\' AND BrandTag__c = \'' + BrandValue + '\'';

        if (detailLevelValue != '*') soql += ' AND Detail_Level__c = \'' + detailLevelValue + '\'';

        soql += ' ORDER BY Name';

        foundTemplates = Database.query(soql);

        for (zqu__Quote_Template__c qt : foundTemplates) {
            QuoteTemplateWrapper qtw = new QuoteTemplateWrapper();
            qtw.IsSelected = false;
            qtw.QuoteTemplate = qt;
            foundTemplatesWrapped.add(qtw);
        }
    }

    public void SelectQT() {

        //Reset this to false to eliminate unrequested previews...
        showPreview = false;
        //Reset the errors list...
        errors = new List<String>();

        DeletePreviouslyPreviewedFile();

        String selectedTemplateId = System.currentPagereference().getParameters().get('QTID');

        for (QuoteTemplateWrapper qtw : foundTemplatesWrapped) {
            if (qtw.QuoteTemplate.zqu__Template_Id__c == selectedTemplateId) qtw.IsSelected = true;
            else qtw.IsSelected = false;
        }
    }

    public PageReference PreviewTemplate() {

        //Reset this to false to eliminate unrequested previews...
        showPreview = false;

        //Reset the errors list...
        errors = new List<String>();

        if (previewAttachmentURL != null) showPreview = true;
        else CreateThePDF(true);    
        
        return null;    
    }

    public PageReference ConfirmTemplate() {

        //Reset this to false to eliminate unrequested previews...
        showPreview = false;

        //Reset the errors list...
        errors = new List<String>();

        if (previewAttachmentURL == null) CreateThePDF(false);

        if (!errors.isEmpty()) return null;
        
        closeWindow = true;
        return null;
    }

    public PageReference Cancel() {

        showPreview = false;
        closeWindow = true;

        DeletePreviouslyPreviewedFile();
        return null;
    }    

    private void CreateThePDF(Boolean fromPreview) {

        if (PageIsValid() || (test.isRunningTest())) {

            //wipe out any previous value
            previewAttachmentURL = null;

            Map<String,Object> zuoraConfigInfo = zqu.zQuoteUtil.getZuoraConfigInformation();

            Zuora.ZApi zApi = new Zuora.ZApi();
            Zuora.ZApi.LoginResult loginResult = new Zuora.ZApi.LoginResult();

            if (!Test.isRunningTest()) {
                try {
                    loginResult = zApi.zLogin();
                }   
                catch (Exception e) {
                    errors.add('Error attempting the callout to Zuora.  ' + e.getMessage());
                    return;
                }
            }
            //else loginResult.serverUrl = 'services46';
            else loginResult.serverUrl = Label.ZuoraSandboxForSFDC_Full;

            String quoteServletUrl = null;

            if (loginResult.serverUrl.containsIgnoreCase('sandbox')) quoteServletUrl = 'https://' + Label.ZuoraSandboxForSFDC_Full + '.zuora.com/rest/v1/quotes/document';

            //this is for services
            else if (loginResult.serverUrl.containsIgnoreCase('services123')) quoteServletUrl = 'https://' + Label.ZuoraSandboxForSFDC_Full + '.zuora.com/apps/v1/quotes/document';

            //production
            else quoteServletUrl = 'https://api.zuora.com/rest/v1/quotes/document';

            if (quoteServletUrl == null) return;

            String sessionId = UserInfo.getSessionId();
            String sfdcUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/services/Soap/u/10.0/' + UserInfo.getOrganizationId();

            Http http = new Http();
            HttpRequest req = new HttpRequest();
            HttpResponse res = new HttpResponse();

            req.setEndpoint(quoteServletUrl);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Accept', 'application/json');

            Blob headerValue = Blob.valueOf(Label.RemittanceLinkZuoraUser + ':' + Label.RemittanceLinkZuoraPass);
            String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
            req.setHeader('Authorization', authorizationHeader);

            String body = '{';
            body += '"documentType":"pdf",';
            body += '"quoteId":"'       + quoteId + '",';
            body += '"serverUrl":"'     + sfdcUrl + '",';
            body += '"templateId":"'    + selectedTemplateId + '",';
            body += '"sessionId":"'     + sessionId + '",';
            body += '"useSFDCLocale":"1",';
            body += '"locale":"'        + UserInfo.getLocale() + '"';
            body += '}';

            req.setBody(body);

            req.setTimeout(80000);
            
            if (!Test.isRunningTest()) res = http.send(req);
            else res.setStatusCode(200);

            if (res.getStatusCode() != 200) {
                errors.add('Error contacting Zuora.  ' + ' Status Code: ' + res.getStatusCode() + '   Status: ' + res.getStatus());
                return;
            }

            String zuoraResponse = res.getBody();

            //example of false response:
            //    { "success" : false, "processId" : "3E753A467A2F9C98", "reasons" : [ { "code" : 57030722, "message" : "'templateId' may not be null" } ] }

            //example of a true response:
            //    { "file" : "https://services123.zuora.com/apps/v1/file/8a80815d4e044a7f014e6a800e5d4135", "success" : true }                        
            if (Test.isRunningTest()) zuoraResponse = '{ "file" : "https://services123.zuora.com/apps/v1/file/8a80815d4e044a7f014e6a800e5d4135", "success" : true }';
            
            //check if success is true or false now, start by parsing the repsonse:
            Map<String, Object> zuoraParsedResponse = (Map<String, Object>) JSON.deserializeUntyped(zuoraResponse);

            if (!zuoraParsedResponse.containsKey('success') || zuoraParsedResponse.get('success') != true) {
                errors.add('Error generating PDF in Zuora.  ' + zuoraResponse);
                return;
            }

            //If we're here, then 'success' was true in Zuora's response so the 'file' key should exist and be ready to grab:
            previewAttachmentURL = String.valueOf(zuoraParsedResponse.get('file'));
            showPreview = fromPreview;

            http = new Http();
            req = new HttpRequest();

            //same authorization we set up earlier, we can reuse it
            req.setHeader('Authorization', authorizationHeader);

            req.setEndpoint(previewAttachmentURL);
            req.setMethod('GET');
            req.setHeader('Content-Type', 'application/pdf');
            req.setTimeout(80000);
            req.setCompressed(false);

            Blob zuorasPDF = null;
                             
            if (!Test.isRunningTest()) {

                res = http.send(req);
                zuorasPDF = res.getBodyAsBlob();       //44KB, doesn't work in SFDC, but works offline great.
            }
            else zuorasPDF = [SELECT Body FROM Attachment WHERE ContentType = 'application/pdf' LIMIT 1].Body;

            Attachment zPDF = new Attachment();
            zPDF.Name = thisQuote.Name + '.pdf';
            zPDF.ContentType = 'application/pdf';
            zPDF.IsPrivate = false;
            zPDF.ParentId = thisQuote.zqu__Opportunity__c;
            zPDF.Body = zuorasPDF;

            insert zPDF;

            attachmentId = zPDF.Id;

            if (showPreview) previewAttachmentURL = URL.getSalesforceBaseUrl().toExternalForm() + '/servlet/servlet.FileDownload?file=' + attachmentId;
            else previewAttachmentURL = null;

            return;
        }
    }

    private Boolean PageIsValid() {
        errors = new List<String>();

        Boolean recordIsSelected = false;

        for (QuoteTemplateWrapper qtw : foundTemplatesWrapped) {
            if (qtw.IsSelected) {
                recordIsSelected = true;
                selectedTemplateId = qtw.QuoteTemplate.zqu__Template_Id__c;
            }
        }

        if (!recordIsSelected) errors.add('You must select a template before proceeding.');

        return recordIsSelected;
    }

    //Wrapper class for holding the Quote templates along with a boolean indicating whether or not it is selected
    public class QuoteTemplateWrapper {
        public zqu__Quote_Template__c QuoteTemplate {get; set;}
        public Boolean IsSelected {get; set;}
    }
}