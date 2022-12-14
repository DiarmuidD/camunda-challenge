public class BatchablProcessContacts implements Database.Batchable<sObject>{
    public List<sObject> myList;

    public BatchablProcessContacts(List<sObject> contactsToUpsert){
        System.debug('contactsToUpsert: ' + contactsToUpsert);
        myList = contactsToUpsert;
        System.debug('Batchable: ' + myList);
    }

    public List<Contact> start(Database.BatchableContext bc) {
        return myList;
    }
    public void execute(Database.BatchableContext bc, List<Contact> records){
        // process each batch of records
        system.debug('In batch records: ' + records);

        List<Database.upsertResult> uResults = Database.upsert(records,false);
        System.debug('uResults: ' + uResults);
    }
    public void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    }
}
