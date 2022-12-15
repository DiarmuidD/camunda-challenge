import { LightningElement, track, api } from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import uploadParticipants from '@salesforce/apex/csvUploadController.uploadParticipants';

const columns = [
    { label: 'First Name', fieldName: 'firstName' },
    { label: 'Last Name', fieldName: 'lastName' },
    {
        label: "View Record",
        type: "button-icon",
        typeAttributes: { iconName: 'utility:open', name: "viewRecord" }
    },
    { label: 'Training Date', fieldName: 'trainingDate' },
    { label: 'Training Name', fieldName: 'trainingName' },
    { label: 'Email', fieldName: 'email' },
    { label: 'Object', fieldName: 'sObjName' },
    { label: 'Status', fieldName: 'status', wrapText: true }
];

export default class AccountTrainingParticipants extends LightningElement {
    @api recordId;
    @track columns = columns;
    @track fileName = '';
    @track UploadFile = 'Upload CSV File';
    @track showLoadingSpinner = false;
    @track buttonDisabled = true;
    @track error;
    //Notifications
    @track title;
    @track message;
    @track variant;
    @track mode;
    filesUploaded = [];
    file;
    fileContents;
    fileReader;
    content;
    MAX_FILE_SIZE = 1500000;

    //Pagination
    // All existing rows
    allData = [];
    // All selected Id values
    allSelectedRows = new Set();
    // Current page index
    pageNumber = 0;
    // Current page selected Id values
    selectedRows = [];
    // Current page data rows
    pageData = [];

    get acceptedFormats() {
        return ['.csv'];
    }

    handleFilesChange(event) {
        if(event.target.files.length > 0) {
            this.closeWarning();
            this.allData = [];
            this.filesUploaded = event.target.files;
            this.fileName = event.target.files[0].name;
            this.buttonDisabled = false;
        }
    }

    handleSave() {
        if(this.filesUploaded.length > 0) {
            this.uploadHelper();
        }

        else {
            this.fileName = 'Please select a CSV file to upload!!';
        }
    }

    uploadHelper() {
        this.file = this.filesUploaded[0];
        if (this.file.size > this.MAX_FILE_SIZE) {
                return;
            }

            this.showLoadingSpinner = true;
            this.fileReader= new FileReader();
            this.fileReader.onloadend = (() => {
                this.fileContents = this.fileReader.result;
                this.saveToFile();
            });
            this.fileReader.readAsText(this.file);
    }

    saveToFile() {
        uploadParticipants({ base64Data: JSON.stringify(this.fileContents), accountId: this.recordId})
        .then(result => {
            this.allData = result;
            this.buttonDisabled = true;
            this.showLoadingSpinner = false;

            //Getting total number of rows
            var lines = this.fileContents.split('\n');
            var linesLength = lines.length - 1;;

            //All CSV rows processed
            if(this.allData.length == 0) {
                this.fileName = this.fileName + ' - Uploaded Successfully';
                this.title = 'CSV file Uploaded Successfully';
                this.message = 'All CSV rows will be processed in a queueable method. This may take some time to process if you uploaded a large CSV file.';
                this.variant = 'success';
                this.mode = 'pester';
                this.showNotification();
            }
            //No CSV rows processed
            else if(this.allData.length == linesLength){
                console.log(this.allData);
                var sObjNames = new Set();

                for(let i=0; i < this.allData.length; i++){
                    sObjNames.add(this.allData[i].sObjName);
                }
                console.log('sObjNames: ', sObjNames);
                console.log('sObjNames.has lead: ', sObjNames.has('Lead'));
                console.log('sObjNames size: ', sObjNames.size);

                if(sObjNames.has('Lead') && sObjNames.size == 1) {
                    this.fileName = this.fileName + ' - Uploaded Successfully';
                    this.title = 'Rows Processed';
                    this.message = 'Existing leads have been found for your CSV rows. These will be added to their corresponding Campaign.';
                    this.variant = 'success';
                    this.mode = 'pester';
                    this.showNotification();
                    this.updatePage();
                }
                else {
                    this.fileName = this.fileName + ' - Not Uploaded';
                    this.title = 'No Rows Processed';
                    this.message = 'Please review the table below to see the row failure reason.';
                    this.variant = 'error';
                    this.mode = 'pester';
                    this.showNotification();
                    this.updatePage();
                }
            }
            //Some CSV rows processed
            else {
                this.fileName = this.fileName + ' - Uploaded Successfully';
                this.title = 'Some Rows Processed';
                this.message = 'The successful CSV rows will be processed in a queueable method. The rows with issues are detailed in the table below.';
                this.variant = 'warning';
                this.mode = 'pester';
                this.showNotification();
                this.updatePage();
            }
        })
        .catch(error => {
            this.showLoadingSpinner = false;
            this.fileName = '';
            this.error = error.body.message;
            this.numberOfRecords = 0;
            this.buttonDisabled = true;

            this.title = 'Error while uploading File';
            this.message = 'Your CSV file has not been processed.';
            this.variant = 'error';
            this.mode = 'pester';
            this.showNotification();
        });
    }

    closeWarning() {
        this.error = '';
    }

    // Set current page state
    updatePage() {
        this.pageData = this.allData.slice(this.pageNumber*10, this.pageNumber*10+10);
        this.selectedRows = this.pageData.map(row => row.id).filter(pageId => this.allSelectedRows.has(pageId));
    }
    // Back a page
    previous() {
        this.pageNumber = Math.max(0, this.pageNumber - 1);
        this.updatePage();
    }
    // Back to the beginning
    first() {
        this.pageNumber = 0;
        this.updatePage();
    }
    // Forward a page
    next() {
        this.pageNumber = Math.min(Math.floor((this.allData.length)/10), this.pageNumber + 1);
        this.updatePage();
    }
    // Forward to the end
    last() {
        this.pageNumber = Math.floor((this.allData.length)/10);
        this.updatePage();
    }

    get showDatatable() {
        if(this.allData.length > 0) {
            return true;
        }
        else {
            return false;
        }
    }

    get showPagination() {
        if(this.allData.length > 10) {
            return true;
        }
        else {
            return false;
        }
    }

    showNotification() {
        const evt = new ShowToastEvent({
            title: this.title,
            message: this.message,
            variant: this.variant,
            mode: this.mode
        });
        this.dispatchEvent(evt);
    }

    handleRowAction(event) {
        if (event.detail.action.name === "viewRecord") {
            if(event.detail.row.sObjName === 'Lead') {
                var id = event.detail.row.recordId;

                window.open(
                '/lightning/r/Lead/' + id + '/view',
                '_blank'
                );
        }
        else {
            this.title = 'Oops!';
            this.message = 'This record does not exist in the system yet, it is only a CSV row failure.';
            this.variant = 'warning';
            this.mode = 'pester';
            this.showNotification();
        }

            //This was giving me an error for some reason - went with the above in the interest of time
            /*
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: id,
                    objectApiName: 'Lead',
                    actionName: 'view'
                }
            });
            */
        }
    }
}