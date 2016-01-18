global without sharing class ResultController {

	public String messageToUser {get; set;}
	public List<String> errors {get; set;}	
	public String authTokenURLEncoded {get; set;}

	private String code {get; set;}	
	private String authToken {get; set;}

    public ResultController() {

 		errors = new List<String>();
 		messageToUser = '';

 		code = ApexPages.currentPage().getParameters().get('code');
 		authToken = ApexPages.currentPage().getParameters().get('auth');

 		//The response is sent from Zuora, but they are just regurgitating the merchant's response
 		String responseFromMerchant = ApexPages.currentPage().getParameters().get('msg');		

 		if (authToken != null) authTokenURLEncoded = EncodingUtil.urlEncode(authToken, 'UTF-8');

 		if (code == 'SUCCESS') messageToUser = '<br/>Thank you!<br/><br/>Your credit card has been successfully submitted.<br/><br/>You may now close this browser.<br/><br/>';

 		else if (code == '52000000') errors.add('<br/><strong>Error</strong> submitting your card because this environment has no Merchant Id set.<br/><br/>');

 		else if (code == '52000320') errors.add('<br/><strong>Error</strong> submitting your card as the number was invalid.<br/><br/>Please click the button below to try again.<br/><br/>');

 		else if (code == '90000011') errors.add('<br/><strong>Error</strong> submitting your card as your personal authorization token was already used.<br/><br/>Please click the button below to return to the payment page try again with a new token.<br/><br/>');

 		else if (code == 'UNTRAPPED_ERROR') errors.add('<br/><strong>Error</strong> submitting your card due to an untrapped error.<br/><br/>Please click the button below to return to the payment page try again.<br/><br/>');

 		else if (code == 'NO_RESPONSE') errors.add('<br/><strong>Error</strong> submitting your card due to network congestion.<br/><br/>Please click the button below to return to the payment page try again.<br/><br/>');

 		else if (code == 'ERROR_MAKING_REQUEST') errors.add('<br/><strong>Error</strong> submitting your card due to a programmatic error.<br/><br/>Please click the button below to return to the payment page try again.  If this message is seen again, please use a different web browser.<br/><br/>');

 		else if (code == 'ERROR_PROCESSING_REQUEST') errors.add('<br/><strong>Error</strong> submitting your card due to a CORS error.<br/><br/>Please click the button below to return to the payment page try again.  If this message is seen again, please use a different web browser.<br/><br/>');

 		else if (code == 'JR_ERROR') messageToUser = '<br/><strong>Error</strong> processing the Javascript remoting statement into Salesforce.<br/><br/>However, your card was still submitted successfully, thank you.<br/><br/>';

 		else if (code == 'NC') messageToUser = '<br/><strong>Error</strong> processing the Javascript remoting statement into Salesforce.<br/><br/>However, your card was still submitted successfully, thank you.<br/><br/>';

 		else {

 			if (responseFromMerchant != null) {

				errors.add('<br/>');
 				List<String> splits = responseFromMerchant.split(' - ');

 				errors.add('<strong>The data you supplied was not accepted by the payment gateway and it has responded with the following message:</strong><br/>');

 				if (splits.size() > 1) errors.add(splits[1]);
 				else errors.add(splits[0]);
 			}
 			else errors.add('<br/>Error <strong>' + code + '</strong> discovered while submitting your card.<br/><br/>');	

 			errors.add('Please click the button below to return to the payment page and try again with adjusted values.<br/><br/>');
 		} 
    }
}