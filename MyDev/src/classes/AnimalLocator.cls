public class AnimalLocator {
    public static void getAnimalNameById(Integer ID){
        Http http = new Http();
        Httprequest request = new Httprequest();
        request.setEndpoint('https://th-apex-http-callout.herokuapp.com/animals/:id');
        request.setMethod('GET');
        
        //mapin.put('id', ID);
        //request.setbody(JSON.serialize(mapin));
        HTTPresponse response = http.send(request);
        Map<string,Object>mapin=(Map<string,Object>)JSON.deserializeUntyped(response.getBody());
        Map<string,Object> mapf= (map<string,Object>)mapin.get('animal');
        system.debug('ggggggggg '+mapf.get('id'));
        
        //system.debug(JSON.deserializeUntyped(response.getBody()));
       
    }
}