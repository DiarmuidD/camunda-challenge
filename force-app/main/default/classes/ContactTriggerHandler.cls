public with sharing class ContactTriggerHandler implements ISobjectTrigger{
    public ContactTriggerHandler() {}

    public void beforeOperation() {}

    public void afterOperation() {}

    public void beforeInsert(List<Sobject> newObjs) {}

    public void beforeUpdate(List<Sobject> newObjs, Map<Id, Sobject> newObjsMap, List<Sobject> oldObjs, Map<Id, Sobject> oldObjsMap) {}

    public void beforeDelete(List<Sobject> oldObjs, Map<Id, Sobject> oldObjsMap) {}

    public void afterInsert(List<Sobject> newObjs, Map<Id, Sobject> newObjsMap) {
        Map<Contact, List<String>> contactToTrainingMap = new Map<Contact, List<String>>();
        List<CampaignMember> memberList = new List<CampaignMember>();

        //Use this
        for(Sobject obj : newObjs) {
            Contact contact = (Contact) obj;
            if(!String.isBlank(contact.TrainingName__c) && contact.TrainingDate__c != null) {
                List<String> trainingDetails = new List<String>{contact.TrainingName__c, String.valueOf(contact.TrainingDate__c)};
                contactToTrainingMap.put(contact, trainingDetails);
            }
        }

        if(!contactToTrainingMap.isEmpty()) {
            Set<String> trainingNames = new Set<String>();
            List<List<String>> trainingDetails = contactToTrainingMap.values();

            for(Integer i = 0; i < trainingDetails.size(); i++) {
                trainingNames.add(trainingDetails[i][0]);
            }

            Map<String, Id> campaignNameToIdMap = new Map<String, Id>();

            for(Campaign campaign : [SELECT Id, Name FROM Campaign WHERE Name IN :trainingNames]) {
                campaignNameToIdMap.put(campaign.Name, campaign.Id);
            }

            for(Contact con : contactToTrainingMap.keySet()) {
                CampaignMember member = new CampaignMember();
                List<String> contactCampaignDetails = contactToTrainingMap.get(con);
                member.CampaignId = campaignNameToIdMap.get(contactCampaignDetails[0]);
                member.ContactId = con.Id;
                memberList.add(member);
            }
        }

        if(!memberList.isEmpty()) {
            List<Database.upsertResult> uResults = Database.upsert(memberList,false);
        }
    }

    public void afterUpdate(List<Sobject> newObjs, Map<Id, Sobject> newObjsMap, List<Sobject> oldObjs, Map<Id, Sobject> oldObjsMap) {
        Map<Contact, List<String>> contactToTrainingMap = new Map<Contact, List<String>>();
        List<CampaignMember> memberList = new List<CampaignMember>();

        //Use this
        for(Sobject obj : newObjs) {
            Contact contact = (Contact) obj;
            Contact oldContact = (Contact)oldObjsMap.get(contact.Id);

            if(contact.TrainingName__c != oldContact.TrainingName__c && !(String.isBlank(contact.TrainingName__c))) {
                List<String> trainingDetails = new List<String>{contact.TrainingName__c, String.valueOf(contact.TrainingDate__c)};
                contactToTrainingMap.put(contact, trainingDetails);
            }
        }

        if(!contactToTrainingMap.isEmpty()) {
            Set<String> trainingNames = new Set<String>();
            List<List<String>> trainingDetails = contactToTrainingMap.values();

            for(Integer i = 0; i < trainingDetails.size(); i++) {
                trainingNames.add(trainingDetails[i][0]);
            }

            Map<String, Id> campaignNameToIdMap = new Map<String, Id>();

            for(Campaign campaign : [SELECT Id, Name FROM Campaign WHERE Name IN :trainingNames]) {
                campaignNameToIdMap.put(campaign.Name, campaign.Id);
            }

            for(Contact con : contactToTrainingMap.keySet()) {
                CampaignMember member = new CampaignMember();
                List<String> contactCampaignDetails = contactToTrainingMap.get(con);
                member.CampaignId = campaignNameToIdMap.get(contactCampaignDetails[0]);
                member.ContactId = con.Id;
                memberList.add(member);
            }
        }

        if(!memberList.isEmpty()) {
            List<Database.upsertResult> uResults = Database.upsert(memberList,false);
        }
    }

    public void afterDelete(List<Sobject> oldObjs, Map<Id, Sobject> oldObjsMap) {}

    public void andFinally() {}
}
