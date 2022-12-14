public class BatchablProcessLeads implements Database.Batchable<sObject>{
    public Map<Id, List<String>> myMap;

    public BatchablProcessLeads(Map<Id, List<String>> recordIdToTrainingDetails){
        System.debug('recordIdToTrainingDetails: ' + recordIdToTrainingDetails);
        myMap = recordIdToTrainingDetails;
        System.debug('Lead Batchable: ' + mySet);
    }

    public Map<Id, List<String>> start(Database.BatchableContext bc) {
        return myMap;
    }

    public void execute(Database.BatchableContext bc, Map<Id, List<String>> recordIdsToTrainingDetails){
        // process each batch of records
        system.debug('In batch recordIdsToTrainingDetails: ' + recordIdsToTrainingDetails);

        /*List<Database.upsertResult> uResults = Database.upsert(records,false);
        System.debug('uResults: ' + uResults);*/
    }

    public void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    }
}