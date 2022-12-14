public class AsyncProcessContacts implements Queueable{
    List<Contact> records = new List<Contact>();

    public AsyncProcessContacts(List<Contact> contactsToUpsert) {
        records = contactsToUpsert;
        System.debug('Queueable: ' + records);
    }
    public void execute(QueueableContext context) {
        Database.executeBatch(new BatchablProcessContacts(records));
        System.debug('batch started with: ' + records);
    }
}
