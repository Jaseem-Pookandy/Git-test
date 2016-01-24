@isTest
global class ParkServiceMock implements webservicemock{
    global void doinvoke( Object spot,Object request,Map<string,Object> response,string endpoint,string soapaction, string requestName,string responseNS,string responseName,string responsetype){
         parkService.byCountryResponse response_x = new  parkService.byCountryResponse();
        list<string> strinlist = new list<string>();
        strinlist.add('balgotti');
        response_x.return_x = strinlist;
        response.put('response_x',response_x); 
    }

}