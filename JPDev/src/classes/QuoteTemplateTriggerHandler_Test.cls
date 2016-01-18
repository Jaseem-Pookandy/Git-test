/*******************************************************************************
Name        : QuoteTemplateTriggerHandler_Test
Description : Test Class for QuoteTemplateTriggerHandler.
Author      : Byrnes
Date        : 2014.10.02
*******************************************************************************/

@isTest
private class QuoteTemplateTriggerHandler_Test {

	public static testMethod void myUnitTest() {
		//First, success...

		zqu__Quote_Template__c newQT = new zqu__Quote_Template__c();
		newQT.Name = 'Dice English Super Awesome Template';
		newQT.zqu__Quote_Type__c = 'New Subscription';
		newQT.zqu__Template_Id__c = 'e20b074746024ea301462a07440d59gg';

		insert newQT;

		newQT = [SELECT Id, Name, zqu__Quote_Type__c, zqu__Template_Id__c, BrandTag__c, Language__c FROM zqu__Quote_Template__c WHERE Id = :newQT.Id];

		System.assertEquals('Dice', newQT.BrandTag__c);
		System.assertEquals('English', newQT.Language__c);

		//Now, failure...

		newQT.Name = 'Dice AwesomeTemplate';
		update newQT;

		newQT = [SELECT Id, Name, zqu__Quote_Type__c, zqu__Template_Id__c, BrandTag__c, Language__c FROM zqu__Quote_Template__c WHERE Id = :newQT.Id];

		System.assertEquals('Invalid Format', newQT.BrandTag__c);
		System.assertEquals('Invalid Format', newQT.Language__c);

		delete newQT;
	}
}