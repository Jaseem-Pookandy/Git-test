////////////////////////////////////////////////////////////////////
//Per Zuora service ticket #61229, this class was created 
//(as linked from here:  https://knowledgecenter.zuora.com/CA_Commerce/E_Development_Resources/C_Component_Library/G_Component_Library_Sample_Code/G_Product_Catalog_On-Demand_Sync)
//in order to facilitate the creation of a 'sync product' button.
////////////////////////////////////////////////////////////////////
//Byrnes - 2015.04.13
////////////////////////////////////////////////////////////////////

global class ProductCatalogManager {	
	
  	WebService static void syncProduct(String productId) {

		Zuora.zapi zapi = new Zuora.zapi();
		if (!test.isRunningTest()) zapi.zlogin();

		List<Zuora.SyncResult> syncResults = new List<Zuora.SyncResult>();

		try {
    		Zuora.OnDemandSyncManager syncManager = new Zuora.OnDemandSyncManager();
    		syncManager.syncZuoraObjectIdSet = new Set<String> { productId };

    		syncManager.syncObjectType = Zuora.OnDemandSyncManager.ObjectType.ZPRODUCT;
    		syncResults = syncManager.sendRequest();
		}
		catch (Zuora.OnDemandSyncManager.OnDemandSyncException e) {
			System.debug('### Error: ' + e);				
		}
  	}
}