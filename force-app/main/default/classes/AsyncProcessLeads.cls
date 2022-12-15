public with sharing class AsyncProcessLeads implements Queueable{
    Map<Lead, List<String>> recordToTrainingDetails = new Map<Lead, List<String>>();

    public AsyncProcessLeads(Map<Lead, List<String>> leadToStringsMap) {
        recordToTrainingDetails = leadToStringsMap;
    }
    public void execute(QueueableContext context) {
        Set<Lead> leadSet = recordToTrainingDetails.keySet();
        List<CampaignMember> campaignMemberList = new List<CampaignMember>();
        Set<String> trainingNames = new Set<String>();
        List<List<String>> trainingDetails = recordToTrainingDetails.values();

        for(Integer i = 0; i < trainingDetails.size(); i++) {
            trainingNames.add(trainingDetails[i][0]);
        }

        Map<String, Id> campaignNameToIdMap = new Map<String, Id>();

        for(Campaign campaign : [SELECT Id, Name FROM Campaign WHERE Name IN :trainingNames]) {
            campaignNameToIdMap.put(campaign.Name, campaign.Id);
        }

        for(Lead lead : leadSet) {
            CampaignMember member = new CampaignMember();
            List<String> leadCampaignDetails = recordToTrainingDetails.get(lead);
            member.CampaignId = campaignNameToIdMap.get(leadCampaignDetails[0]);
            member.LeadId = lead.Id;
            campaignMemberList.add(member);
        }

        if(!campaignMemberList.isEmpty()) {
            Database.executeBatch(new BatchableProcessCampaignMembers(campaignMemberList));
        }
    }
}
