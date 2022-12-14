import { LightningElement, track, api } from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import uploadParticipants from '@salesforce/apex/csvUploadController.uploadParticipants';

const columns = [
    { label: 'First Name', fieldName: 'firstName' },
    { label: 'Last Name', fieldName: 'lastName' },
    { label: 'Record Id', fieldName: 'recordId' },
    { label: 'Training Date', fieldName: 'trainingDate' },
    { label: 'Training Name', fieldName: 'trainingName' },
    { label: 'Email', fieldName: 'email' },
    { label: 'Object', fieldName: 'sObjName' },
    { label: 'Status', fieldName: 'status', wrapText: true },

    /*this.recordId = '';
        this.firstname = '';
        this.lastName = '';
        this.trainingDate = '';
        this.trainingName = '';
        this.email = '';
        this.status = '';
        this.sObjName = '';
        */
];

export default class AccountTrainingParticipants extends LightningElement {
    //INclude apex refresh so that the contact appears without the user having to refresh the page
    @api recordId;
    @track columns = columns;
    @track data;
    @track fileName = '';
    @track UploadFile = 'Upload CSV File';
    @track showLoadingSpinner = false;
    @track isTrue = false;
    @track error;
    selectedRecords;
    filesUploaded = [];
    file;
    fileContents;
    fileReader;
    content;
    MAX_FILE_SIZE = 1500000;

    //Pagination
    // All existing rows
    allData;
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
            this.filesUploaded = event.target.files;
            this.fileName = event.target.files[0].name;
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
                window.console.log('File Size is to long');
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
            window.console.log('result ====> ', result);

            this.allData = result;
            console.log('allData: ', this.allData);
            this.updatePage();
            this.fileName = this.fileName + ' - Uploaded Successfully';
            this.isTrue = false;
            this.showLoadingSpinner = false;

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success!!',
                    message: this.file.name + ' - Uploaded Successfully!!!',
                    variant: 'success',

                }),
            );
        })
        .catch(error => {
            this.showLoadingSpinner = false;
            this.fileName = '';
            this.error = error.body.message;
            window.console.log(error);
            this.dispatchEvent(

                new ShowToastEvent({

                    title: 'Error while uploading File',

                    message: error.message,

                    variant: 'error',

                }),

            );
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
        this.pageNumber = Math.max(0, this.pageNumber - 1)
        this.updatePage();
    }
    // Back to the beginning
    first() {
        this.pageNumber = 0;
        this.updatePage();
    }
    // Forward a page
    next() {
        this.pageNumber = Math.min(Math.floor((this.allData.length-9)/10), this.pageNumber + 1)
        this.updatePage();
    }
    // Forward to the end
    last() {
        this.pageNumber = Math.floor((this.allData.length-9)/10)
        this.updatePage();
    }

    updateSearch(event) {
        var regex = new RegExp(event.target.value,'gi');
        console.log('regex: ' + regex);
        this.pageData = this.allData.filter(row => regex.test(row.status));
    }
}