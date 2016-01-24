@isTEst
global class AnimalsHttpCalloutMock implements httpcalloutmock{
    global Httpresponse respond(Httprequest request){
        
        Httpresponse response = new Httpresponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"animals": ["majestic badger", "fluffy bunny", "scary bear", "chicken", "mighty moose"]}');
        response.setStatusCode(200);
        return response;
    }
}