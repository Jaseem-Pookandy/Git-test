public class blockconflicts {
    public static void conflictblockmethod(list<session_speaker__c> sessionspeakerin){
        
        list<Session_Speaker__c> session_speakerlist = [select Session__c,speaker__c from session_speaker__c];
        map<id,Set<ID>> mapsessionspeaker = new map<id,Set<ID>>();
        for(session_speaker__c sp : session_speakerlist){
            
            if(mapsessionspeaker.containsKey(sp.session__c))
                mapsessionspeaker.get(sp.session__c).add(sp.speaker__c);
            else{
                Set<ID> speakerlist = new Set<ID>();
                speakerlist.add(sp.speaker__c);
                mapsessionspeaker.put(sp.session__c,speakerlist);
            }
        }
        
        for(session_speaker__c sp:sessionspeakerin){
            
            if(mapsessionspeaker.containsKey(sp.session__c)){
                if(mapsessionspeaker.get(sp.session__c).contains(sp.speaker__c))
                    sp.addError('same speaker added earlier');
                
            }
        }
    }
}