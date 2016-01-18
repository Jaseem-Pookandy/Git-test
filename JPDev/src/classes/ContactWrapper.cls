public with sharing class ContactWrapper {

	public Contact contact {get; set;}
	public List<ContactBrandDetails> listCBD {get; set;}	

	private final string checkboxChecked = 'img/checkbox_checked.gif';
	private final string checkboxUnchecked = 'img/checkbox_unchecked.gif';

	public ContactWrapper() {
		contact = new Contact();
		listCBD = new List<ContactBrandDetails>();
	}
	
	public String Tooltip {
		get { 

			String tableStructure = '<table>';
			tableStructure += '<tr>';
			tableStructure += '<th style="font-size: 80%;">&nbsp;</th>';
			tableStructure += '<th style="font-size: 80%;">Brand</th>';
			tableStructure += '<th style="font-size: 80%;">Title</th>';
			tableStructure += '<th style="font-size: 80%; text-align:center;">Last Sold Date</th>';
			tableStructure += '<th style="font-size: 80%; text-align:right;">Last Sold Amount</th>';
			tableStructure += '<th style="font-size: 80%; text-align:center;" title="Account Brand Primary Recipient?"><img src="https://dice.my.salesforce.com/servlet/servlet.ImageServer?id=015U0000001wU2C&oid=00Dd0000000c1oz" /></th>';
			tableStructure += '</tr>';
			tableStructure += '<col width="70"><col width="125"><col width="175"><col width="90"><col width="110"><col width="50">';

			String result = tableStructure;
			
			Integer cbdNum = 0;

			for (ContactBrandDetails cbd : listCBD) {
				cbdNum++;
				result += '<tr>';
				// Only execute the next line on the first iteration because it includes 'rowspan'.				
				// color to match the tooltip background is:  #ffedb2
				if (cbdNum == 1) result += '<td style="font-size: 80%; color:#000; text-align:center; background-color:#fff7dc; border:solid 1px #000;" rowspan="' + listCBD.size() + '">' + contact.FirstName + '<br/>' + contact.LastName + '</td>';
				result += '<td style="font-size: 80%;">' + cbd.Brand + '</td>';
				result += '<td style="font-size: 80%;">' + cbd.PrettyTitle + '</td>';
				result += '<td style="font-size: 80%; text-align:center;">' + cbd.PrettyOppDate + '</td>';
				result += '<td style="font-size: 80%; text-align:right;">' + cbd.PrettyAmount + '</td>';

				if (cbd.contactIsPrimaryRecipient) result += '<td style="font-size: 80%; text-align:center"><a href="#" title="Click once to clear" onclick="SetABPrimaryRecipient(\'clear\', \'' + contact.Id + '\', \'' + cbd.Brand + '\', \'' + contact.AccountId + '\');"><img src="/' + checkboxChecked + '"/></a></td>';			
				else result += '<td style="font-size: 80%; text-align:center"><a href="#" title="Click once to set" onclick="SetABPrimaryRecipient(\'set\', \'' + contact.Id + '\', \'' + cbd.Brand + '\', \'' + contact.AccountId + '\');"><img src="/' + checkboxUnchecked + '"/></a></td>';			

				result += '</tr>';
			}
			
			if (result != tableStructure) result += '</table>';
			else result = '';
			
			return result;
		}
	}
}