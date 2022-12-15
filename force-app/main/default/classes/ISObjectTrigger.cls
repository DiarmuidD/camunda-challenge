public interface ISObjectTrigger {

    void beforeOperation();

    void afterOperation();

    void beforeInsert(List<Sobject> newObjs);

    void beforeUpdate(List<Sobject> newObjs, Map<Id, Sobject> newObjsMap, List<Sobject> oldObjs, Map<Id, Sobject> oldObjsMap);

    void beforeDelete(List<Sobject> oldObjs, Map<Id, Sobject> oldObjsMap);

    void afterInsert(List<Sobject> newObjs, Map<Id, Sobject> newObjsMap);

    void afterUpdate(List<Sobject> newObjs, Map<Id, Sobject> newObjsMap, List<Sobject> oldObjs, Map<Id, Sobject> oldObjsMap);

    void afterDelete(List<Sobject> oldObjs, Map<Id, Sobject> oldObjsMap);

    void andFinally();

}