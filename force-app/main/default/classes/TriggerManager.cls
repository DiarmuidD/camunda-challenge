public class TriggerManager {
    @testVisible public static Set<String> disableTriggerInTestClass = new Set<String>();
    @testVisible public static Boolean triggerRan = false;

    public static void createHandler(Schema.sObjectType objectType) {
        String sObjectType =  String.valueOf(objectType);
        //String triggerContext = FeatureManagementSetupService.canExecuteTrigger(sObjectType);
        if(!disableTriggerInTestClass.contains(sObjectType)) {
            triggerRan = true;
            ISobjectTrigger handler = getHandler(objectType);
            if(handler == null) {
                //throw exception
                System.debug('The Trigger Handler was null');
            }
            //execute(handler,triggerContext);
            execute(handler);
        }
    }

    private static ISobjectTrigger getHandler(Schema.sObjectType objectType) {
        if(objectType == Contact.SobjectType) {
            return new ContactTriggerHandler();
        }
        return null;
    }

    //private static void execute(ISobjectTrigger handler, String triggerContext) {
    private static void execute(ISobjectTrigger handler) {
        if (Trigger.isBefore) {
            // Call the bulk before to handle any caching of data and enable bulkification
            handler.beforeOperation();

            // Iterate through the records to be deleted passing them to the handler.
            if (Trigger.isDelete) {
                handler.beforeDelete(Trigger.Old, Trigger.OldMap);
            }
            // Iterate through the records to be inserted passing them to the handler.
            else if (Trigger.isInsert) {
                handler.beforeInsert(Trigger.new);
            }
            // Iterate through the records to be updated passing them to the handler.
            else if (Trigger.isUpdate) {
                handler.beforeUpdate(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
            }
        }
        else if(Trigger.isAfter) {
            // Call the bulk after to handle any caching of data and enable bulkification
            handler.afterOperation();

            // Iterate through the records deleted passing them to the handler.
            if (Trigger.isDelete) {
                handler.afterDelete(Trigger.old, Trigger.oldMap);
            }
            // Iterate through the records inserted passing them to the handler.
            else if (Trigger.isInsert) {
                handler.afterInsert(Trigger.new, Trigger.newMap);
            }
            // Iterate through the records updated passing them to the handler.
            else if (Trigger.isUpdate) {
                handler.afterUpdate(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
            }
        }
        // Perform any post processing
        handler.andFinally();
    }
}