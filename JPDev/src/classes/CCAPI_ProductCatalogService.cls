@RestResource(UrlMapping='/ccapi/productcatalog/*')
global with sharing class CCAPI_ProductCatalogService {
    
    @HttpGet
    global static ProductCatalog getProductCatalog()
    {
        String brandTag = RestContext.request.params.get('brandTag');

        if(brandTag == '' || brandTag == null)
        {
            return getProductCatalogData('eFC-Amer');            
        }
        
        return getProductCatalogData(brandTag);
    }
    
    private static ProductCatalog getProductCatalogData(string brandTag)
    {
        List<CCAPI_ZuoraProductSkuQuery.ZuoraProduct> zproducts = CCAPI_ZuoraProductSkuQuery.GetEFCWebstoreZuoraProducts(brandTag);
    	ProductCatalog pc = new ProductCatalog();
    	pc.numberOfItems = zproducts.size();
    	pc.queryInfo = 'Using Brand Tag: ' + brandTag + ' SubCategory: ' + CCAPI_ZuoraProductSkuQuery.WEBSTORE_SUBCATEGORY;
    	pc.products = buildProductList(zproducts);
    	
    	return pc;
    }
    
    private static List<Product> buildProductList(List<CCAPI_ZuoraProductSkuQuery.ZuoraProduct> zuoraProducts)
    {
    	List<Product> productList = new List<Product>();
    	for(CCAPI_ZuoraProductSkuQuery.ZuoraProduct p : zuoraProducts)
    	{
    		Product productItem = new Product();
    		productItem.ProductSku = p.sku;
    		productItem.RatePlanChargeID = p.productRatePlanChargeID;
    		
    		productList.add(productItem);
    	}
    	return productList;
    }
    global class ProductCatalog {
        public Integer  numberOfItems{ get; set; }
        public string queryInfo{get; set;}
        public List<Product> products { get; set; }
    }
    
    global class Product {
        public string ProductSku { get; set; }
        public string RatePlanChargeID { get; set; }
    }
}