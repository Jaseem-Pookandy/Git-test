/*
// 
// (c) 2012 Appirio, Inc.
//
// ObjectHierarchyAccessor_Test
//
//
// 30 Nov 2012   gescandon@appirio.com  Original
// 
//
*/ 
@isTest
private class ObjectHierarchyAccessor_Test {

  static testMethod void testHierarchyAccessor() {

    createTestHierarchy();

    Account[] accountList = [ Select id, parentID, name from account where name like 'HierarchyTest_%' ];
    System.assert(accountList.size() > 2);  
    Id oid = accountList[1].Id;
    test.startTest();
    ObjectHierarchyAccessor hm = new ObjectHierarchyAccessor();
    hm.setCurrentObjId(oid);
    hm.parentFieldName = 'ParentId';
    
    String topElementId = hm.getTopElementId();
    System.assert(topElementId != null, 'expecting a top element id');
    test.stopTest();
    
    // get object name
    String oname = hm.getObjectName(accountList[1].Id);
    System.assert(oname == accountList[1].getsObjectType().getDescribe().getName());
    
    List<ObjectHierarchyAccessor.ObjectWrapper> owList = hm.getObjectStructure();
    System.assert(owList.size() == accountList.size());
    
    // improve coverage
    owList[0].getlevelFlag();
    owList[0].getcloseFlag();
    owList[0].getnodeType();
    owList[0].getcurrentNode();
    owList[0].getObjectName();
    owList[0].getNodeId(); 
    owList[0].setnodeId('string'); 
    owList[0].setlevelFlag(true);
    owList[0].setlcloseFlag(true);  
    owList[0].setnodeType('string');
    owList[0].setcurrentNode(true);
    owList[0].getNodeLabel();
    
  }
  
  static void createTestHierarchy() {

    List<Account> auxList = new List<Account>();
    Integer accountToCreate = 4;
    String parentId;
    for( Integer i = 1; i <= accountToCreate; i++ ){
      Account accAux = new Account();
      accAux.Name = 'HierarchyTest_' + parentId;
      accAux.ShippingStreet = '1 Main St.';
      accAux.ShippingState = 'VA';
      accAux.ShippingPostalCode = '12345';
      accAux.ShippingCountry = 'USA';
      accAux.ShippingCity = 'Anytown';
      accAux.Description = 'This is a test account';
      accAux.BillingStreet = '1 Main St.';
      accAux.BillingState = 'VA';
      accAux.BillingPostalCode = '12345';
      accAux.BillingCountry = 'USA';
      accAux.BillingCity = 'Anytown';
      accAux.AnnualRevenue = 10000;
      accAux.ParentId = parentId;
      insert accAux;
      parentId = accAux.Id;
    }
    insert auxList;  
  }
}