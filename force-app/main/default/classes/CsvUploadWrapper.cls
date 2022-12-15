public class CsvUploadWrapper{
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
    public String sObjName;
    @AuraEnabled
    public String recordId;

    public CsvUploadWrapper(){
        this.firstName = '-';
        this.lastName = '-';
        this.trainingDate = '-';
        this.trainingName = '-';
        this.email = '-';
        this.status = '-';
        this.sObjName = '-';
        this.recordId = '-';
    }
}