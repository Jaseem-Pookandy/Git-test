global with sharing class CCAPI_ZuoraProductSkuQuery {
    public static string WEBSTORE_SUBCATEGORY = 'Webstore';
    
    //The only brand tag that will have any data is eFC-EMEA.  This should be what is coming from the client connect api request.
    public static ZuoraProduct GetEFCWebstoreZuoraProduct(string sku, string brandTag) {    
    
    	//Retrieve the ProductRatePlanCharge using the parent relationships to limit the items returned.
    	//Product has a subcategory of WebStore 
    	//Product Rate plan has a BrandTage of eFC-EMEA    	
	    List<zqu__ProductRatePlanCharge__c> zouraRatePlanCharges = [
	            SELECT zCharge.zqu__ProductRatePlan__r.zqu__ZProduct__r.zqu__ZuoraId__c, 
	            zCharge.zqu__ProductRatePlan__r.zqu__ZProduct__r.zqu__SKU__c,
	            zCharge.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductSubCategory__c,
	            zCharge.zqu__ProductRatePlan__r.BrandTag__c,
	            zCharge.zqu__ProductRatePlan__r.zqu__ZuoraId__c,
	            zCharge.zqu__ProductRatePlan__r.zqu__EffectiveStartDate__c,
	            zCharge.zqu__ProductRatePlan__r.zqu__EffectiveEndDate__c,
	            zCharge.zqu__ZuoraId__c
	            FROM zqu__ProductRatePlanCharge__c zCharge
	            WHERE zCharge.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductSubCategory__c = :WEBSTORE_SUBCATEGORY
	            AND zCharge.zqu__ProductRatePlan__r.BrandTag__c = :brandTag
            	AND zCharge.zqu__Deleted__c = false AND zCharge.zqu__ProductRatePlan__r.zqu__Deleted__c = false AND zCharge.zqu__ProductRatePlan__r.zqu__ZProduct__r.zqu__Deleted__c = false
	            AND zCharge.zqu__ProductRatePlan__r.zqu__EffectiveStartDate__c <= :date.today()
	            AND zCharge.zqu__ProductRatePlan__r.zqu__EffectiveEndDate__c >= :date.today()
	            AND zCharge.zqu__ProductRatePlan__r.zqu__ZProduct__r.zqu__SKU__c = :sku
	        ];
        
        //There must be EXACTLY one charge.  If there are more than one, we have no idea which one to pick and have found ourselves in an exceptional situation
        if(zouraRatePlanCharges.size() > 1)
        {
        	throw new QueryException('Multiple rate plan charges found for sku:' + sku + ' brand tag:' + brandTag + ' ProductSubCategory:' + WEBSTORE_SUBCATEGORY);
        }
        
        //If we didn't find any results for the given tag and sku, we will return null
        if(zouraRatePlanCharges.size() == 0)
        {
        	
        	return null;
        }
        zqu__ProductRatePlanCharge__c targetProductRatePlanCharge = zouraRatePlanCharges.get(0);
        
        ZuoraProduct zp = BuildZuoraProduct(targetProductRatePlanCharge);
       
       system.debug('ProductZouraID' + zp.productID);
       system.debug('Sku' + zp.sku);
       system.debug('ProductSubCategory' + zp.productSubCategory);
       system.debug('RatePlanID' + zp.productRatePlanID);
       system.debug('EffectiveSTartDate' + zp.effectiveStartDate);
       system.debug('EffectiveEndDate' + zp.effectiveEndDate);
       system.debug('BrandTag' + zp.brandTag);
       system.debug('RatePlanChargeID' + zp.productRatePlanChargeID);     
               
        return zp;        
    }
    
      public static List<ZuoraProduct> GetEFCWebstoreZuoraProducts(string brandTag) {    
    
    	//Retrieve the ProductRatePlanCharge using the parent relationships to limit the items returned.
    	//Product has a subcategory of WebStore 
    	//Product Rate plan has a BrandTage of eFC-EMEA    	
	    List<zqu__ProductRatePlanCharge__c> zouraRatePlanCharges = [
	            SELECT zCharge.zqu__ProductRatePlan__r.zqu__ZProduct__r.zqu__ZuoraId__c, 
	            zCharge.zqu__ProductRatePlan__r.zqu__ZProduct__r.zqu__SKU__c,
	            zCharge.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductSubCategory__c,
	            zCharge.zqu__ProductRatePlan__r.BrandTag__c,
	            zCharge.zqu__ProductRatePlan__r.zqu__ZuoraId__c,
	            zCharge.zqu__ProductRatePlan__r.zqu__EffectiveStartDate__c,
	            zCharge.zqu__ProductRatePlan__r.zqu__EffectiveEndDate__c,
	            zCharge.zqu__ZuoraId__c
	            FROM zqu__ProductRatePlanCharge__c zCharge
	            WHERE zCharge.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductSubCategory__c = :WEBSTORE_SUBCATEGORY
	            AND zCharge.zqu__ProductRatePlan__r.BrandTag__c = :brandTag
	            AND zCharge.zqu__ProductRatePlan__r.zqu__EffectiveStartDate__c <= :date.today()
            	AND zCharge.zqu__Deleted__c = false AND zCharge.zqu__ProductRatePlan__r.zqu__Deleted__c = false AND zCharge.zqu__ProductRatePlan__r.zqu__ZProduct__r.zqu__Deleted__c = false
	            AND zCharge.zqu__ProductRatePlan__r.zqu__EffectiveEndDate__c >= :date.today()
	        ];
        
        
        List<ZuoraProduct> productList = new List<ZuoraProduct>();
        for(zqu__ProductRatePlanCharge__c rpc : zouraRatePlanCharges)
        {
        	productList.add(BuildZuoraProduct(rpc));
        }           
               
        return productList;        
    }
    private static ZuoraProduct BuildZuoraProduct(zqu__ProductRatePlanCharge__c ratePlanCharge)
    {
	    ZuoraProduct zp = new ZuoraProduct();
	        //product fields
	        zp.productID = ratePlanCharge.zqu__ProductRatePlan__r.zqu__ZProduct__r.zqu__ZuoraId__c;
	        zp.productSubCategory = ratePlanCharge.zqu__ProductRatePlan__r.zqu__ZProduct__r.ProductSubCategory__c;
	        zp.sku = ratePlanCharge.zqu__ProductRatePlan__r.zqu__ZProduct__r.zqu__SKU__c;
	        
	        //rate plan fields        
	        zp.effectiveStartDate = ratePlanCharge.zqu__ProductRatePlan__r.zqu__EffectiveStartDate__c;
	        zp.effectiveEndDate = ratePlanCharge.zqu__ProductRatePlan__r.zqu__EffectiveEndDate__c;
			zp.brandTag = ratePlanCharge.zqu__ProductRatePlan__r.BrandTag__c;
			zp.productRatePlanID = ratePlanCharge.zqu__ProductRatePlan__r.zqu__ZuoraId__c;
			
			//rate plan charge fields
			zp.productRatePlanChargeID = ratePlanCharge.zqu__ZuoraId__c;
			
			return zp;
	  }
    
	global class ZuoraProduct {
        public string sku { get; set; }
        public date effectiveStartDate { get; set; }
        public date effectiveEndDate { get; set; }
        public string brandTag {get; set;}
        public string productSubCategory {get; set;}
        public string productID { get; set; }
        public string productRatePlanID { get; set; }
        public string productRatePlanChargeID { get; set; }
    }
}