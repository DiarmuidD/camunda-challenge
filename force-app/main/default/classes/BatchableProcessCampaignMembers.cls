public class BatchableProcessCampaignMembers  implements Database.Batchable<sObject>{
    List<CampaignMember> memberList = new List<CampaignMember>();

    public BatchableProcessCampaignMembers(List<CampaignMember> campaignMemberList){
        memberList = campaignMemberList;
    }

    public List<CampaignMember> start(Database.BatchableContext bc) {
        return memberList;
    }
    public void execute(Database.BatchableContext bc, List<CampaignMember> records){
        List<Database.upsertResult> uResults = Database.upsert(records,false);
    }
    public void finish(Database.BatchableContext bc){
    }
}