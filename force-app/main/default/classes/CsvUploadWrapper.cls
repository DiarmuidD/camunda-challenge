public class CsvUploadWrapper{
    /* { label: 'Training Date', fieldName: 'TrainingDate__c' },
    { label: 'Training Name', fieldName: 'TrainingName__c' },*/

    @AuraEnabled
    public String recordId;
    @AuraEnabled
    public String firstName;
    @AuraEnabled
    public String lastName;
    @AuraEnabled
    public String trainingDate;
    @AuraEnabled
    public String trainingName;
    @AuraEnabled
    public String email;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public String sObjName; //change to type - Contact, Lead, CSV Row
    //include type of record??
    //Include status - process; not processed
    //Add an attribute to store duplicate email set

    public CsvUploadWrapper(){
        this.recordId = '';
        this.firstName = '-';
        this.lastName = '-';
        this.trainingDate = '-';
        this.trainingName = '-';
        this.email = '-';
        this.status = '-';
        this.sObjName = '-';
        this.duplicates = '-';
    }
}