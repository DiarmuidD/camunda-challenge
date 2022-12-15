public class csvUploadController {
    @AuraEnabled
    public static List<CsvUploadWrapper> uploadParticipants(String base64Data, String accountId) {
        set<string> trainingNames = new Set<String>();
        Map<String, Campaign> nameToCampaignMap = new Map<String, Campaign>();
        Map<String, List<sObject>> emailTosObjectsMap = new Map<String, List<sObject>>();
        Set<String> emailsToInsert = new Set<String>();
        List<CsvUploadWrapper> wrapperList = new List<CsvUploadWrapper>();
        Map<Lead, List<String>> leadToStringsMap = new Map<Lead, List<String>>();
        String data = JSON.deserializeUntyped(base64Data).toString();
        Map<String, Contact> mapEmailToContactsToUpsert = new Map<String, Contact>();
        List<String> lstCSVLines = data.split('\n');
        List<Contact> validFilerows = new List<Contact>();

        for(Integer i = 1; i < lstCSVLines.size(); i++) {
            string[] csvRowData = lstCSVLines[i].split(',');
            if(csvRowData.size() > 0) {
                trainingNames.add((csvRowData[3]).trim());
            }
        }

        //Query for campagins with the name that was provided in the CSV
        for(Campaign campaign : [SELECT Id, Name FROM Campaign WHERE Name IN :trainingNames]) {
            nameToCampaignMap.put(campaign.Name, campaign);
        }

        for(Integer i = 1; i < lstCSVLines.size(); i++) {
            //Loop through the CSV and pick only the rows that have last name, email as well as a valid training name
            //If last name, email or training name is empty put them into a separate list (not processed)
            string[] csvRowData = lstCSVLines[i].split(',');

            if(csvRowData.size() > 0) {
                String lastName = (csvRowData[1]).trim();
                String email = (csvRowData[4]).trim();
                String trainingName = (csvRowData[3]).trim();

                if(!String.isBlank(lastName) && !String.isBlank(email) && !String.isBlank(trainingName) && nameToCampaignMap.containsKey(trainingName)) {
                    emailsToInsert.add(((csvRowData[4]).trim()).toLowerCase());
                    Contact con = new Contact();
                    con.FirstName = (csvRowData[0]).trim();
                    con.LastName = (csvRowData[1]).trim();
                    con.TrainingDate__c = date.parse((csvRowData[2]).trim());
                    con.TrainingName__c = (csvRowData[3]).trim();
                    con.Email = (csvRowData[4]).trim();
                    con.AccountId = accountId;
                    validFilerows.add(con);
                }
                else {
                    //Required fields are missing
                    CsvUploadWrapper wrapper = new CsvUploadWrapper();
                    String missingFields = '';

                    wrapper.firstName = (csvRowData[0]).trim();
                    if(String.isBlank(lastName)) {
                        missingFields = missingFields + ' Last Name;';
                    }
                    else {
                        wrapper.lastName = lastName;
                    }
                    wrapper.trainingDate = (csvRowData[2]).trim();
                    if(String.isBlank(trainingName)) {
                        missingFields = missingFields + ' Training Name;';
                    }
                    else if(!(nameToCampaignMap.containsKey(trainingName))) {
                        missingFields = missingFields + ' Training Name (did not match any training in the system);';
                        wrapper.trainingName = (csvRowData[3]).trim();
                    }
                    else {
                        wrapper.trainingName = (csvRowData[3]).trim();
                    }
                    if(String.isBlank(email)) {
                        missingFields = missingFields + ' Email';
                    }
                    else {
                        wrapper.email = email;
                    }
                    wrapper.sObjName = 'Contact';
                    wrapper.status = 'Required Field Issues:' + missingFields;
                    wrapperList.add(wrapper);
                }
            }
        }

        for(Contact con : [SELECT Id, FirstName, LastName, TrainingDate__c, TrainingName__c, Email FROM Contact WHERE Email IN :emailsToInsert AND AccountId = :accountId]) {
            List<Contact> contactList = emailTosObjectsMap.containskey(con.Email) ? emailTosObjectsMap.get(con.Email) : new List<sObject>();
            contactList.add(con);
            emailTosObjectsMap.put(con.Email, contactList);
        }

        for(Lead lead : [SELECT Id, FirstName, LastName, Email FROM Lead WHERE Email IN :emailsToInsert]) {
            List<Lead> leadList = emailTosObjectsMap.containskey(lead.Email) ? emailTosObjectsMap.get(lead.Email) : new List<sObject>();
            leadList.add(lead);
            emailTosObjectsMap.put(lead.Email, leadList);
        }

        if(!validFilerows.isEmpty()) {
            for(Contact con : validFilerows) {
                String email = (con.Email).toLowerCase();

                if(emailTosObjectsMap.containsKey(email)) {
                    List<SObject> objList = emailTosObjectsMap.get(email);

                    for(SObject obj : objList) {
                        //Record is a contact
                        if(obj.Id.getSobjectType().getDescribe().getName() == 'Contact') {
                            Contact existingCon = (Contact)obj;

                            if(mapEmailToContactsToUpsert.containskey(existingCon.Email)) {
                                //Duplicate rows found in the CSV file
                                CsvUploadWrapper wrapper = new CsvUploadWrapper();
                                wrapper.email = existingCon.Email;
                                wrapper.status = 'duplicate';
                                wrapperList.add(wrapper);
                            }
                            else {
                                //Existing contact record to be updated
                                existingCon.TrainingDate__c = con.TrainingDate__c;
                                existingCon.TrainingName__c = con.TrainingName__c;
                                mapEmailToContactsToUpsert.put(existingCon.Email, existingCon);
                            }
                        }
                        else if(obj.Id.getSobjectType().getDescribe().getName() == 'Lead') {
                            //Existing lead record
                            Lead lead = (Lead)obj;
                            CsvUploadWrapper wrapper = new CsvUploadWrapper();
                            wrapper.recordId = lead.Id;
                            wrapper.firstName = lead.FirstName;
                            wrapper.lastName = lead.LastName;
                            wrapper.email = lead.Email;
                            wrapper.sObjName = 'Lead';
                            wrapper.status = 'Already Exists. This Lead will be added as a participant to the ' + con.TrainingName__c;
                            wrapperList.add(wrapper);

                            List<String> trainingDetails = new List<String>{con.TrainingName__c, String.valueOf(con.TrainingDate__c)};
                            leadToStringsMap.put(lead, trainingDetails);
                        }
                    }
                }
                else {
                    //New contact to be inserted
                    mapEmailToContactsToUpsert.put(con.Email, con);
                }
            }
        }
        else{
            if(wrapperList.isEmpty()) {
                throw new AuraHandledException('Oops. It looks like your CSV file is empty. Please correct your CSV file and try again.');
            }
        }

        if(!mapEmailToContactsToUpsert.isEmpty()) {
            List<Contact> contactsToUpsert = mapEmailToContactsToUpsert.values();
            //Call the queueable to create/update the contacts
            ID jobID = System.enqueueJob(new AsyncProcessContacts (contactsToUpsert));
        }

        if(!leadToStringsMap.isEmpty()) {
            //Call the queueable to create the campaign members for the Leads
            ID jobID = System.enqueueJob(new AsyncProcessLeads (leadToStringsMap));
        }
        return wrapperList;
    }
}