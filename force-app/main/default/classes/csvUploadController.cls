public class csvUploadController {
    @AuraEnabled
    public static List<CsvUploadWrapper> uploadParticipants(String base64Data, String accountId) {
        set<string> trainingNames = new Set<String>{'BPMN Training', 'DMN Training'};
        //Check that the lead or contact does not exist already
        //Create a map
        Map<String, List<sObject>> emailTosObjectsMap = new Map<String, List<sObject>>();
        Set<String> emailsToInsert = new Set<String>(); //'Diarmuid Dunne', 'Test Dunne'};
        List<CsvUploadWrapper> wrapperList = new List<CsvUploadWrapper>();
        Set<Id> leadIdSet = new Set<Id>();
        Map<Lead, List<String>> leadToStringsMap = new Map<Lead, List<String>>();
        String data = JSON.deserializeUntyped(base64Data).toString();

        //Map string to contact to be upserted
        Map<String, Contact> mapStringToContactsToUpsert = new Map<String, Contact>();
        List<String> lstCSVLines = data.split('\n');
        List<Contact> validFilerows = new List<Contact>();

        //NEWLY ADDED
        /*for(Integer i = 1; i < lstCSVLines.size(); i++) {
            String csvLine = lstCSVLines[i];
            String prevLine = csvLine;
            Integer startIndex;
            Integer endIndex;

            while(csvLine.indexOf('"') > -1){
                System.debug('WHILE LOOP');
                if(startIndex == null){
                    System.debug('IF ONE LOOP');
                    startIndex = csvLine.indexOf('"');
                    csvLine = csvLine.substring(0, startIndex) + ':quotes:' + csvLine.substring(startIndex+1, csvLine.length());
                }else{
                    System.debug('ELSE ONE LOOP');
                    if(endIndex == null){
                        System.debug('IF TWO LOOP');
                        endIndex = csvLine.indexOf('"');
                        csvLine = csvLine.substring(0, endIndex) + ':quotes:' + csvLine.substring(endIndex+1, csvLine.length());
                    }
                }
                if(startIndex != null && endIndex != null){
                    System.debug('IF THREE LOOP');
                    String sub = csvLine.substring(startIndex, endIndex);
                    sub = sub.replaceAll(',', ':comma:');
                    csvLine = csvLine.substring(0, startIndex) + sub + csvLine.substring(endIndex, csvLine.length());
                    startIndex = null;
                    endIndex = null;
                }
            }
            List<String> csvRowData = new List<String>();
            for(String column : csvLine.split(',')){
                column = column.replaceAll(':quotes:', '').replaceAll(':comma:', ',');
                csvRowData.add(column);
                System.debug(csvRowData);
            }
        }*/

        for(Integer i = 1; i < lstCSVLines.size(); i++) {
            //Loop through the CSV and pick only the rows that has last name as well as email
            //Assumption the training name always exists
            //If last name or training name is empty put them into a separate list (not processed)
            string[] csvRowData = lstCSVLines[i].split(',');
            if(csvRowData.size() > 0) {
                //namesToInsert.add(csvRowData[0] + ' ' + csvRowData[1]);
                System.debug('Name trim: ' + (csvRowData[1]).trim());
                String lastName = (csvRowData[1]).trim();
                String email = (csvRowData[4]).trim();
                String trainingName = (csvRowData[3]).trim();
                System.debug('trainingName: ' + trainingName);
                System.debug('trainingName == BPMN Training: ' + trainingName == 'BPMN Training');
                System.debug('trainingName == DMN Training: ' + trainingName == 'DMN Training');

                if(!String.isBlank(lastName) && !String.isBlank(email) && !String.isBlank(trainingName) && (trainingName == 'BPMN Training' || trainingName == 'DMN Training')) {
                    /*Contact con = new Contact();
                    con.FirstName = csvRowData[0];
                    con.LastName = csvRowData[1];
                    con.TrainingDate__c = date.parse(csvRowData[2]);
                    con.TrainingName__c = csvRowData[3];
                    con.Email = csvRowData[4];
                    con.AccountId = accountId;
                    contactsToUpsert.add(con);*/

                    //Add the emails to a set to see if the record exists already
                    emailsToInsert.add(((csvRowData[4]).trim()).toLowerCase());
                    //Add these rows to a list to process only the rows with all fields that are required
                    //csvLineListToUpsert.add((List<String>)csvRowData);
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
                    System.debug('Required fields are missing for this row');
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
                    else if(!(trainingName == 'BPMN Training') || !(trainingName == 'DMN Training')) {
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

        System.debug('validFilerows: ' + validFilerows);
        System.debug('Number of contacts to try to insert: ' + validFilerows.size());

        for(Contact con : [SELECT Id, FirstName, LastName, TrainingDate__c, TrainingName__c, Email FROM Contact WHERE Email IN :emailsToInsert AND AccountId = :accountId]) {
            List<Contact> contactList = emailTosObjectsMap.containskey(con.Email) ? emailTosObjectsMap.get(con.Email) : new List<sObject>();
            contactList.add(con);
            emailTosObjectsMap.put(con.Email, contactList);
        }

        for(Lead lead : [SELECT Id, FirstName, LastName, Email FROM Lead WHERE Email IN :emailsToInsert]) {
            //nameTosObjectsMap.put(lead.Name, lead);
            List<Lead> leadList = emailTosObjectsMap.containskey(lead.Email) ? emailTosObjectsMap.get(lead.Email) : new List<sObject>();
            leadList.add(lead);
            emailTosObjectsMap.put(lead.Email, leadList);
        }

        System.debug('emailTosObjectsMap: ' + emailTosObjectsMap);
        System.debug('emailsToInsert: ' + emailsToInsert);
        //insert contactsToUpsert;

        if(!validFilerows.isEmpty()) {
            for(Contact con : validFilerows) {
                System.debug('con.Email: ' + (con.Email).toLowerCase());
                String email = (con.Email).toLowerCase();
                if(emailTosObjectsMap.containsKey(email)) {
                    System.debug('Map Contains this record');
                    //The map contains this record
                    List<SObject> objList = emailTosObjectsMap.get(email);
                    System.debug('objList: ' + objList);

                    for(SObject obj : objList) {
                        //Record is a contact
                        if(obj.Id.getSobjectType().getDescribe().getName() == 'Contact') {
                            //Check if the contact is already in contactsToUpsert
                            //Maybe contactsToUpsert should be a map
                            Contact existingCon = (Contact)obj;

                            if(mapStringToContactsToUpsert.containskey(existingCon.Email)) {
                                System.debug('It looks like this is a duplicate in your CSV file: ' + existingCon.TrainingName__c);
                                //Add the duplicate email
                                CsvUploadWrapper wrapper = new CsvUploadWrapper();
                                wrapper.email = existingCon.Email;
                                wrapper.status = 'duplicate';
                                wrapperList.add(wrapper);
                            }
                            else {
                                System.debug('Add existing contact record to update');
                                System.debug('Before existingCon: ' + existingCon);
                                existingCon.TrainingDate__c = con.TrainingDate__c;
                                existingCon.TrainingName__c = con.TrainingName__c;
                                System.debug('After existingCon: ' + existingCon);
                                mapStringToContactsToUpsert.put(existingCon.Email, existingCon);
                            }
                        }
                        //Record is a lead
                        else if(obj.Id.getSobjectType().getDescribe().getName() == 'Lead') {
                            System.debug('Record exists as a lead: ' + obj);
                            Lead lead = (Lead)obj;
                            CsvUploadWrapper wrapper = new CsvUploadWrapper();
                            wrapper.recordId = lead.Id;
                            wrapper.firstName = lead.FirstName;
                            wrapper.lastName = lead.LastName;
                            wrapper.email = lead.Email;
                            wrapper.sObjName = 'Lead';
                            wrapper.status = 'Already Exists. This Lead will be added as a participant to the ' + con.TrainingName__c;
                            wrapperList.add(wrapper);

                            //Adding Lead Id to set to add this as a campaign member
                            //leadIdSet.add(lead.Id);
                            List<String> trainingDetails = new List<String>{con.TrainingName__c, String.valueOf(con.TrainingDate__c)};
                            leadToStringsMap.put(lead, trainingDetails);
                        }
                    }
                }
                else {
                    mapStringToContactsToUpsert.put(con.Email, con);
                }
            }
        }

        if(!mapStringToContactsToUpsert.isEmpty()) {
            List<Contact> contactsToUpsert = mapStringToContactsToUpsert.values();
            System.debug('contactsToUpsert: ' + contactsToUpsert);

            ID jobID = System.enqueueJob(new AsyncProcessContacts (contactsToUpsert));
            System.debug('jobID: ' + jobID);

            /*Database.UpsertResult[] csvUpsertResults = Database.upsert(contactsToUpsert, false);
            System.debug(csvUpsertResults);

            for(Integer i = 0; i < csvUpsertResults.size(); i++ ) {
                System.debug('Contact & Corresponding upsertResult');
                CsvUploadWrapper wrapper = new CsvUploadWrapper();
                Contact con = contactsToUpsert[i];
                System.debug(con);
                Database.UpsertResult upsertResult = csvUpsertResults[i];
                System.debug(upsertResult);

                if(upsertResult.isCreated()) {
                    System.debug('isCreated: ' + con.Email);
                    wrapper.recordId = con.Id;
                    wrapper.firstName = con.FirstName;
                    wrapper.lastName = con.LastName;
                    wrapper.trainingDate = (con.TrainingDate__c).format();
                    wrapper.trainingName = con.TrainingName__c;
                    wrapper.email = con.Email;
                    wrapper.sObjName = 'Contact';
                    wrapper.status = 'Inserted Successfully';
                    wrapperList.add(wrapper);
                }
                else if(upsertResult.isSuccess()) {
                    System.debug('isSuccess: ' + con.Email);
                    wrapper.recordId = con.Id;
                    wrapper.firstName = con.FirstName;
                    wrapper.lastName = con.LastName;
                    wrapper.trainingDate = (con.TrainingDate__c).format();
                    wrapper.trainingName = con.TrainingName__c;
                    wrapper.email = con.Email;
                    wrapper.sObjName = 'Contact';
                    wrapper.status = 'Updated Successfully';
                    wrapperList.add(wrapper);
                }
                else {
                    System.debug('Else');
                    wrapper.firstName = con.FirstName;
                    wrapper.lastName = con.LastName;
                    wrapper.trainingDate = (con.TrainingDate__c).format();
                    wrapper.trainingName = con.TrainingName__c;
                    wrapper.email = con.Email;
                    wrapper.sObjName = 'Contact';
                    for(Database.Error error : upsertResult.getErrors()) {
                        //Handle error
                        System.debug(error.getStatusCode() + ': ' + error.getMessage() +
                                    ' Fields that affected the error: ' + error.getFields());
                        // WHAT IF THERE ARE MORE THAN ONE ERRORS????
                        wrapper.status = error.getStatusCode() + ': ' + error.getMessage() +
                        ' Fields that affected the error: ' + error.getFields();
                    }
                    wrapperList.add(wrapper);
                }
                System.debug('Attempts to insert: ' + wrapper);
            }
            System.debug('wrapperList: ' + wrapperList);*/

            /*for(Database.SaveResult saveResult : csvSaveResults) {
                if(!saveResult.isSuccess()) {
                    System.debug(saveResult);

                    for(Database.Error error : saveResult.getErrors()) {
                        //Handle error
                         System.debug(error.getStatusCode() + ': ' + error.getMessage() +
                                      ' Fields that affected the error: ' + error.getFields());
                    }
                }
                else {
                    System.debug(saveResult);
                    System.debug('Contact Successfully inserted, Contact Id is: ' + saveResult.getId());
                }
            }*/
        }

        if(!leadToStringsMap.isEmpty()) {
            //Call the queueable to create the campaign members for the Leads
            System.debug('leadToStringsMap: ' + leadToStringsMap);

            ID jobID = System.enqueueJob(new AsyncProcessLeads (leadToStringsMap));
            System.debug('jobID: ' + jobID);
        }

        return wrapperList;
    }
}