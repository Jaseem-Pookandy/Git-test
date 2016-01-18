/*    Copyright (c) 2013 Zuora, Inc.
 *
 *   Permission is hereby granted, free of charge, to any person obtaining a copy of 
 *   this software and associated documentation files (the "Software"), to use copy, 
 *   modify, merge, publish the Software and to distribute, and sublicense copies of 
 *   the Software, provided no fee is charged for the Software.  In addition the
 *   rights specified above are conditioned upon the following:
 *
 *   The above copyright notice and this permission notice shall be included in all
 *   copies or substantial portions of the Software.
 *
 *   Zuora, Inc. or any other trademarks of Zuora, Inc.  may not be used to endorse
 *   or promote products derived from this Software without specific prior written
 *   permission from Zuora, Inc.
 *
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL
 *   ZUORA, INC. BE LIABLE FOR ANY DIRECT, INDIRECT OR CONSEQUENTIAL DAMAGES
 *   (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 *   LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 *   ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 *   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.  

 *   IN THE EVENT YOU ARE AN EXISTING ZUORA CUSTOMER, USE OF THIS SOFTWARE IS GOVERNED

 *   BY THIS AGREEMENT AND NOT YOUR MASTER SUBSCRIPTION AGREEMENT WITH ZUORA.
 */

//Shawn Xuereb - Deprecated with the Release 2.
@isTest(SeeAllData=true)
private class PrepareNewQuoteTest {

	
   		//
       //Account create
       //
       public static Account createAccount()
       {

             Account testAcc = new Account();

             testAcc.Name = 'testAccount';
             testAcc.BillingCity = 'Somewhere';
             testAcc.BillingState = 'CA';
             testAcc.BillingCountry = 'US';
             testAcc.BillingPostalCode = '12345';
             testAcc.BillingStreet = '123';

             //testAcc.zd_ID__c = '123';

             insert testAcc;

             return testAcc;
       }
       
       //
       //create opportunity
       //
       public static Opportunity createOpportunity(Account acc)
       {

             Opportunity testOpp = new Opportunity();

             testOpp.Name = 'testopp';

             Date mydate = date.newinstance(2012, 1, 1);

             testOpp.CloseDate = mydate;

             testOpp.StageName = 'Closed Won';

             testOpp.Type = 'New Business';

             List<Account> acclist = [select id, name from Account where name = :acc.Name];

            
             testOpp.AccountId = acclist[0].Id;

             insert testOpp;

             return testOpp;
       }
	
	/*public static testMethod void test3()
	{
		Account testAcc = createAccount();                         
             
             Opportunity testOpp = createOpportunity(testAcc);
            
		Test.startTest();
			ApexPages.StandardController controller = new ApexPages.StandardController(testOpp);
			PrepareNewQuoteController pnqc = new PrepareNewQuoteController(controller);
			pnqc.selectedAccount = 'testAccount';
			pnqc.selectedAmendmentType = 'renew';
			pnqc.selectedAccountType = 'new';
			
			pnqc.onload();
			pnqc.onSelectAccountType();
			pnqc.onSelectAccount();
			pnqc.onSelectSubscriptionType();
			pnqc.goNewQuote();
		
		Test.stopTest();
	}
	
	public static testMethod void test2()
	{
		Account testAcc = createAccount();                         
             
        Opportunity testOpp = createOpportunity(testAcc);
            
		Test.startTest();
		
		ApexPages.StandardController controller = new ApexPages.StandardController(testOpp);
		PrepareNewQuoteController pnqc = new PrepareNewQuoteController(controller);
		pnqc.selectedAccount = 'testAccount';
		pnqc.selectedAmendmentType = 'amend';
		pnqc.selectedAccountType = 'new';
		
		pnqc.onload();
		pnqc.onSelectAccountType();
		pnqc.onSelectAccount();
		pnqc.onSelectSubscriptionType();
		pnqc.goNewQuote();
		
		Test.stopTest();
	}*/
	
	public static testMethod void test()
	{
		Account testAcc = createAccount();                         

        Opportunity testOpp = createOpportunity(testAcc);	
		
		Test.startTest();
		ApexPages.StandardController controller = new ApexPages.StandardController(testOpp);
		PrepareNewQuoteController pnqc = new PrepareNewQuoteController(controller);
		/*pnqc.selectedAccount = 'testAccount';
		
		pnqc.onload();
		pnqc.onSelectAccountType();
		pnqc.onSelectAccount();
		pnqc.onSelectSubscriptionType();
		pnqc.goNewQuote();*/		
		
		Test.stopTest();
	}
}