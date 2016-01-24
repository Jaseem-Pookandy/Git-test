public class StringArrayTest{
    public static list<String> generateStringArray(Integer n){
        list<String> string_list = new list<String>();
        
        for(integer i=0;i<n;i++){
            string_list.add('Test '+string.valueof(i));
        }
        system.debug('#####'+string_list);
        
        return string_list;
    }

}