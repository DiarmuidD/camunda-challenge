trigger ContactTrigger on Contact (before update, before insert, before delete, after update, after insert, after delete) {
    TriggerManager.createHandler(Contact.SobjectType);
}