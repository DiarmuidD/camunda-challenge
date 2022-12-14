public class BatchableProcessCampaignMembers  implements Database.Batchable<sObject>{
    List<CampaignMember> memberList = new List<CampaignMember>();

    public BatchableProcessCampaignMembers(List<CampaignMember> campaignMemberList){
        System.debug('campaignMemberList: ' + campaignMemberList);
        memberList = campaignMemberList;
        System.debug('Campaign Members Batchable: ' + memberList);
    }

    public List<CampaignMember> start(Database.BatchableContext bc) {
        return memberList;
    }
    public void execute(Database.BatchableContext bc, List<CampaignMember> records){
        // process each batch of records
        system.debug('In batch records: ' + records);

        List<Database.upsertResult> uResults = Database.upsert(records,false);
        System.debug('uResults: ' + uResults);
    }
    public void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    }
}