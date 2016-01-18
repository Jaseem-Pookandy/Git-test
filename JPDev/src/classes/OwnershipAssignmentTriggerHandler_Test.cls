@isTest
private class OwnershipAssignmentTriggerHandler_Test {
    
    public static testMethod void scenario1() {

        CreateData();

        List<User> userList = [SELECT Id FROM User WHERE Email Like 'email%'];

        List<pw_ccpro__CountryObject__c> countryList = [SELECT Id FROM pw_ccpro__CountryObject__c WHERE pw_ccpro__IsoCode_3__c = 'XXX'];

        List<Brand__c> brandList = [SELECT Id, Name FROM Brand__c];

        //Insert a couple ownership Assignment records:
        List<Ownership_Assignment__c> ownershipList = new List<Ownership_Assignment__c>();

        Ownership_Assignment__c oa = new Ownership_Assignment__c();
        oa.Country__c = countryList[0].Id;
        oa.Brand__c = brandList[0].Id;
        oa.Primary_Owner__c = userList[0].Id;
        oa.Support_Owner__c = userList[1].Id;

        ownershipList.add(oa);

        insert ownershipList;

        String origKey = [SELECT Unique_Key__c from Ownership_Assignment__c WHERE Id = :ownershipList[0].Id].Unique_Key__c;
        system.assertNotEquals(null, origKey);

        ownershipList[0].Brand__c = brandList[1].Id;
        update ownershipList;

        String updatedKey = [SELECT Unique_Key__c from Ownership_Assignment__c WHERE Id = :ownershipList[0].Id].Unique_Key__c;
        system.assertNotEquals(origKey, updatedKey);

        delete ownershipList;
    }

    private static void CreateData() {

        //Insert a user
        List<User> userList = new List<User>();

        Profile sysAdmin = TestUtils.usrProfile('System Administrator');

        User newUser1 = TestUtils.createUser('lname','firstName1', 'email1@c.com', 'tests1@b0.com', 'test1', 'nickName1', sysAdmin.Id, 'testUser_adName1');
        newUser1.IsActive = true;
        userList.add(newUser1);

        User newUser2 = TestUtils.createUser('lname','firstName2', 'email2@c.com', 'tests2@b0.com', 'test2', 'nickName2', sysAdmin.Id, 'testUser_adName2');
        newUser2.IsActive = false;
        userList.add(newUser2);

        insert userList;

        //Insert brands...
        List<Brand__c> brandList = new List<Brand__c>();
        Brand__c brand = new Brand__c(isActive__c = true, Name = 'Dice', External_Id__c = 'Dice');
        brandList.add(brand);
        brand = new Brand__c(isActive__c = true, Name = 'Rigzone', External_Id__c = 'RZ');
        brandList.add(brand);
        insert brandList;

        //Insert a country
        pw_ccpro__CountryObject__c newCountry = new pw_ccpro__CountryObject__c();
        newCountry.pw_ccpro__IsoCode_2__c = 'XX';
        newCountry.pw_ccpro__IsoCode_3__c = 'XXX';
        newCountry.Name = 'Valhalla';
        newCountry.pw_ccpro__Enabled__c = true;
        insert newCountry;
    }
}