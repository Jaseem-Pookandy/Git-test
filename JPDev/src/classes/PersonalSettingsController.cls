public class PersonalSettingsController {

    public List<String> infos {get; set;}
	public List<String> errors {get; set;}
	public User currentUser {get; set;}
    public String header {get; set;}

	private PageReference pgReturnPage {get; set;}

    public PersonalSettingsController(ApexPages.StandardController controller) {

    }

    public PageReference PrepPage() {

		errors = new List<String>();
        infos = new List<String>();
        header = 'Your Stuff';

		currentUser = new User();
    	List<User> users = [SELECT Id, Name, DefaultCurrencyIsoCode FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

    	if ((users != null) && (users.size() == 1)) currentUser = users[0];
    	else errors.add('Well that\'s odd.  I was unable to find yourself.  Why don\'t you try that again...');

        if (currentUser != null) header = currentUser.Name + ' - Personal Information';

        return null;
    }

    public PageReference Save() {

        errors = new List<String>();
        infos = new List<String>();

    	update currentUser;

        //update the info list
        infos.add('These settings have been successfully saved.');

    	return null;
    }

    public PageReference Cancel() {
    	return new PageReference('/home/home.jsp');
    }
}