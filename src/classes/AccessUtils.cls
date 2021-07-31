public with sharing class AccessUtils {
    //Accessible
    public Boolean AccessibleWithoutSharing(Schema.SObjectType sObjectType, Schema.DescribeFieldResult[] fields) {
        FLSAccessControllerWithSharing acws = new FLSAccessControllerWithSharing();
        Boolean isObjectsAccessible=acws.isObjectAccessible(sObjectType);
        String notAccessibleFLS = acws.hasNotAccessibleFLS(fields);
        
        if (notAccessibleFLS != NULL || !isObjectsAccessible) {
            throw new SFDCAccessControlException( 'AccessViolationException',SFDCAccessControlException.ExceptionType.FIELD_ACCESS_VIOLATION,SFDCAccessControlException.ExceptionReason.NO_ACCESS,sObjectType.getDescribe().getLabel(),notAccessibleFLS); 
        }
        return true;
    }

    // Insert
    public Database.SaveResult[] InsertWithoutSharing(sObject[] objs, Schema.DescribeFieldResult[] fields) {
        FLSAccessControllerWithSharing acws = new FLSAccessControllerWithSharing();
        String notCreateableFLS = acws.hasNotCreateableFLS(fields);
        Boolean isObjectsCreateable = objs.isEmpty() ? true : acws.isObjectCreateable(objs);
        if (notCreateableFLS != NULL || !isObjectsCreateable) {
            throw new SFDCAccessControlException('AccessViolationException',SFDCAccessControlException.ExceptionType.FIELD_ACCESS_VIOLATION,SFDCAccessControlException.ExceptionReason.NO_CREATE,objs.getSObjectType().getDescribe().getName(),notCreateableFLS);
        }
        return Database.insert(objs);
    }
    public Database.SaveResult InsertWithoutSharing(sObject obj,Schema.DescribeFieldResult[] fields) {
        FLSAccessControllerWithSharing acws = new FLSAccessControllerWithSharing();
        String notCreateableFLS = acws.hasNotCreateableFLS(fields);
        Boolean isObjectCreateable = acws.isObjectCreateable(obj);
        if (notCreateableFLS != NULL || !isObjectCreateable) {
            throw new SFDCAccessControlException('AccessViolationException',SFDCAccessControlException.ExceptionType.FIELD_ACCESS_VIOLATION,SFDCAccessControlException.ExceptionReason.NO_CREATE,obj.getSObjectType().getDescribe().getName(),notCreateableFLS);
        }
        return Database.insert(obj);
    }
    // Update
    public Database.SaveResult UpdateWithoutSharing(sObject obj, Schema.DescribeFieldResult[] fields) {
        FLSAccessControllerWithSharing acws = new FLSAccessControllerWithSharing();
        String notUpdateableFLS = acws.hasNotUpdateableFLS(fields);
        Boolean isObjectUpdateable = acws.isObjectUpdateable(obj);
        if (notUpdateableFLS != NULL || !isObjectUpdateable) {
            throw new SFDCAccessControlException('AccessViolationException', SFDCAccessControlException.ExceptionType.FIELD_ACCESS_VIOLATION,SFDCAccessControlException.ExceptionReason.NO_UPDATE,obj.getSObjectType().getDescribe().getName(), notUpdateableFLS);
        }
        return Database.update(obj);
    }
    public Database.SaveResult[] UpdateWithoutSharing(sObject[] objs, Schema.DescribeFieldResult[] fields) {
        FLSAccessControllerWithSharing acws = new FLSAccessControllerWithSharing();
        String notUpdateableFLS = acws.hasNotUpdateableFLS(fields);
        Boolean isObjectsUpdateable = objs.isEmpty() ? true : acws.isObjectUpdateable(objs);
        if (notUpdateableFLS != NULL || !isObjectsUpdateable) {
            throw new SFDCAccessControlException('AccessViolationException',SFDCAccessControlException.ExceptionType.FIELD_ACCESS_VIOLATION,SFDCAccessControlException.ExceptionReason.NO_UPDATE,objs.getSObjectType().getDescribe().getName(), notUpdateableFLS );
        }
        return Database.update(objs);
    }
    // Upsert
    public Database.UpsertResult UpsertWithoutSharing(sObject obj,
                                                      Schema.DescribeFieldResult[] fields, 
                                                      Schema.SObjectField externalIdField) {
                                                                                                 
        FLSAccessControllerWithSharing acws = new FLSAccessControllerWithSharing();
        String notCreateableFLS = acws.hasNotCreateableFLS(fields);
        String notUpdateableFLS = acws.hasNotUpdateableFLS(fields);
        Boolean isObjectUpserteable = acws.isObjectUpserteable(obj);
        if (notCreateableFLS != NULL || notUpdateableFLS != NULL || !isObjectUpserteable) {
            throw new SFDCAccessControlException( 'AccessViolationException', SFDCAccessControlException.ExceptionType.FIELD_ACCESS_VIOLATION,(notCreateableFLS!=NULL) ? SFDCAccessControlException.ExceptionReason.NO_CREATE : SFDCAccessControlException.ExceptionReason.NO_UPDATE,obj.getSObjectType().getDescribe().getName(),(notCreateableFLS!=NULL) ? notCreateableFLS : notUpdateableFLS);
        }
                                        
        return Database.upsert(obj);
    }
    public Database.UpsertResult[] UpsertWithoutSharing(sObject[] objs,  Schema.DescribeFieldResult[] fields, Schema.SObjectField externalIdField) {
                                  
        FLSAccessControllerWithSharing acws = new FLSAccessControllerWithSharing();
        String notCreateableFLS = acws.hasNotCreateableFLS(fields);
        String notUpdateableFLS = acws.hasNotUpdateableFLS(fields);
        Boolean isObjectsUpserteable = objs.isEmpty() ? true : acws.isObjectUpserteable(objs);
        if (notCreateableFLS != NULL || notUpdateableFLS != NULL || !isObjectsUpserteable) {
            throw new SFDCAccessControlException('AccessViolationException', SFDCAccessControlException.ExceptionType.FIELD_ACCESS_VIOLATION, (notCreateableFLS!=NULL) ? SFDCAccessControlException.ExceptionReason.NO_CREATE : SFDCAccessControlException.ExceptionReason.NO_UPDATE,objs.getSObjectType().getDescribe().getName(), (notCreateableFLS!=NULL) ? notCreateableFLS : notUpdateableFLS);
        }
        SObjectType sObjectType = objs.getSObjectType();
        String listType = 'List<' + sObjectType + '>';
        List<SObject> castRecords = (List<SObject>)Type.forName(listType).newInstance();
        castRecords.addAll(objs);
        
        return Database.upsert(castRecords,externalIdField);
    }
    public List<Database.DeleteResult> DeleteWithoutSharing(List<sObject> obj) {
        FLSAccessControllerWithSharing acws = new FLSAccessControllerWithSharing();
        Boolean isObjectDeletable = acws.isObjectDeletable(obj);
        if (isObjectDeletable == false) {
            throw new SFDCAccessControlException( 'AccessViolationException',SFDCAccessControlException.ExceptionType.OBJECT_ACCESS_VIOLATION,SFDCAccessControlException.ExceptionReason.NO_DELETE,obj.getSObjectType().getDescribe().getName(), NULL);
        }
        return Database.delete(obj);
    }

    public with sharing class FLSAccessControllerWithSharing {
        public String hasNotAccessibleFLS(Schema.DescribeFieldResult[] fields) {
            String result = NULL;
            for (Schema.DescribeFieldResult field : fields) {
                Boolean isAccessible = field.isAccessible();
                if (!isAccessible) {
                    result = field.getName();
                    break;
                }
            }
            return result;
        }
        public String hasNotCreateableFLS(Schema.DescribeFieldResult[] fields) {
            String result = NULL;
            for (Schema.DescribeFieldResult field : fields) {
                Boolean isCreateable = field.isCreateable();
                if (!isCreateable) {
                    result = field.getName();
                    break;
                }
            }
            return result;
        }
        public String hasNotUpdateableFLS(Schema.DescribeFieldResult[] fields) {
            String result = NULL;
            for (Schema.DescribeFieldResult field : fields) {
                // For Master-Detail fields check for Creatable instead of Updateable access
                Boolean isUpdateable = (field.getRelationshipOrder() != NULL) ? field.isCreateable() : field.isUpdateable();
                if (!isUpdateable) {
                    result = field.getName();
                    break;
                }
            }
            return result;
        }
        public Boolean isObjectAccessible(Schema.SObjectType sObjectType) {
            return sObjectType.getDescribe().isAccessible();
        }
        public Boolean isObjectAccessible(sObject obj) {
            return obj.getSObjectType().getDescribe().isAccessible();
        }
        public Boolean isObjectAccessible(List<sObject> obj) {
            return obj.getSObjectType().getDescribe().isAccessible();
        }
        public Boolean isObjectCreateable(sObject obj) {
            return obj.getSObjectType().getDescribe().isCreateable();
        }
        public Boolean isObjectCreateable(List<sObject> obj) {
            return obj.getSObjectType().getDescribe().isCreateable();
        }
        public Boolean isObjectUpserteable(sObject obj) {
            return (obj.getSObjectType().getDescribe().isCreateable() && obj.getSObjectType().getDescribe().isUpdateable());
        }
        public Boolean isObjectUpserteable(List<sObject> obj) {
            return (obj.getSObjectType().getDescribe().isCreateable() && obj.getSObjectType().getDescribe().isUpdateable());
        }
        public Boolean isObjectUpdateable(sObject obj) {
            return obj.getSObjectType().getDescribe().isUpdateable();
        }
        public Boolean isObjectUpdateable(List<sObject> obj) {
            return obj.getSObjectType().getDescribe().isUpdateable();
        }
        public Boolean isObjectDeletable(sObject obj) {
            return obj.getSObjectType().getDescribe().isDeletable();
        }
        public Boolean isObjectDeletable(List<sObject> obj) {
            return obj.getSObjectType().getDescribe().isDeletable();
        }
    }
}