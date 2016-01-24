public class ParkLocator {
    public static list<string> country(String country){
        parkService.ParksImplPort parksbycountry = new parkService.ParksImplPort ();
        String[] parklist = parksbycountry.byCountry(country);
        return parklist;
    }
}