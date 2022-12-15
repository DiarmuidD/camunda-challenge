public class BatchablProcessContacts implements Database.Batchable<sObject>{
    public List<sObject> myList;

    public BatchablProcessContacts(List<sObject> contactsToUpsert){
        myList = contactsToUpsert;
    }

    public List<Contact> start(Database.BatchableContext bc) {
        return myList;
    }
    public void execute(Database.BatchableContext bc, List<Contact> records){
        List<Database.upsertResult> uResults = Database.upsert(records,false);
    }
    public void finish(Database.BatchableContext bc){
    }
}