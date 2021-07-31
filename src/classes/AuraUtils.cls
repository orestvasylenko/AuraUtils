public with sharing  class AuraUtils {

    public class QueryParams {
        @AuraEnabled
        public String sObjectApiName {get; set;}
        @AuraEnabled
        public String[] fields {get; set;}
        @AuraEnabled
        public String[] conditionals {get; set;}
        @AuraEnabled
        public String groupByField {get; set;}
        @AuraEnabled
        public String orderByField {get; set;}
        @AuraEnabled
        public Integer quantity {get; set;}
    }
    
    @AuraEnabled
    public static List<sObject> getRecords(QueryParams params) {
        System.debug('params : ' + params);
        // Returned List
        List<sObject> newList = new List<sObject>();
        // Query
        String query = 'SELECT ';
        query += setFieldsInQuery(params.fields);
        query += ' FROM ' + params.sObjectApiName;
        query = setConditionalsInQuery(query, params.conditionals);
        query += ' WITH SECURITY_ENFORCED';
        query += setGroupByFieldInQuery(params.groupByField);
        query += setOrderByFieldInQuery(params.orderByField);
		query += setLimitInQuery(params.quantity);

        try {
            return Database.query(query);
        } catch(QueryException e){
            throw e;
        } 
    }

    // Set Params In Query
    public static String setFieldsInQuery(String[] fields) {
        if(fields != null || !fields.isEmpty()){
            return String.join( fields, ', ' );
        } else {
            throw error('No fields...');
        }
    }
    public static String setConditionalsInQuery(String query, String[] conditionals) {
        if(conditionals != null || !conditionals.isEmpty()){
            for(String conditional : conditionals){
                query += !query.contains('WHERE') ? ' WHERE ' + conditional : ' ' + conditional;
            }
        }
        return query;
    }
    public static String setGroupByFieldInQuery(String groupByField){
        return groupByField != null ? ' GROUP BY ' + groupByField : '';
    }
    public static String setOrderByFieldInQuery(String orderByField){
        return orderByField != null ? ' ORDER BY ' + orderByField : '';
    }
    public static String setLimitInQuery(Integer quantity){
        return quantity != null ? ' LIMIT ' + quantity : '';
    }
    // Call Custom Exception
    public class CustomException extends Exception {} 
    public static CustomException error(String message){
        return new CustomException(message); 
    }
    // Class Data Model For DmlParams
    public class DmlParams {
        @AuraEnabled
        public String dml {get; set;}
        @AuraEnabled
        public List<Map<String, Object>> data {get; set;}
    }
    
    @AuraEnabled // Dynamic DML Operations
    public static String dml(DmlParams params){
		// Check data size
        if(params.data != null || !params.data.isEmpty()){
            // List sObjects
            sObject[] sObjects = putNewValuesBeforeDmlOperation(params.data);
            // DML
            return fireDml(params.dml, sObjects);
        } else {
            throw error('No data...');
        }
    }

    public static sObject[] putNewValuesBeforeDmlOperation(List<Map<String, Object>> data){
        sObject[] sObjects = new sObject[]{};
        for(Map<String, Object> obj: data){
            // Check Id. For insert || upsert / update
            sObject sobj = definesObjectTypeOfRecord(obj);
            // Put new value...
            sobj = putNewValues(sobj, obj);
            // Add sObject to list
            sObjects.add(sobj);
        }
        return sObjects;
    }

    public static sObject definesObjectTypeOfRecord(Map<String, Object> obj){
        sObject sobj;
        // If Id exist => update / upsert
        if(obj.get('Id') != null){
            Id recordId = obj.get('Id').toString();
            //sobj = Schema.getGlobalDescribe().get(recordId.getSObjectType().getDescribe().getName()).newSObject();
            sobj.Id = recordId;
            return sobj;
        }
        // Else striving get sObject attribute from retrieved data
        // It means sObjectApiName, for ex. Account => ONLY insert
        else if(obj.get('sObject') != null){
            String sObjectApiName = obj.get('sObject').toString();
            // Removing 'sObject' attribute before dml
            obj.remove('sObject');
            return sobj = Schema.getGlobalDescribe().get(sObjectApiName).newSObject();
        }
        // Validation fields Id or sObjectApiName
        else {
            throw error('I can\'t find the record id. If you haven\'t it, input value of sObject');
        }
    }

    public static sObject putNewValues(sObject sobj, Map<String, Object> obj){
        if(obj != null && !obj.keySet().isEmpty()){
            for(String fieldApiName: obj.keySet()){
                sobj.put(fieldApiName, obj.get(fieldApiName));
            }
            return sobj;
        } else {
            throw error('No values to put...');
        }
    }

    public static String fireDml(String dml, sObject[] listSObjects){
        switch on dml {
            // Cases : null, insert, update, upsert, delete.
            when null {       
                throw error('Dml operation can\'t be null');
            }   
            when 'insert' {       
                try {
                    //new AccessUtils().InsertWithoutSharing(listSObjects, SchemaDescribeFieldResult);
                    Database.insert(listSObjects);
                    return 'The record has been created successfully.';
                } catch(DmlException e){
                    throw e;
                }
            }   
            when 'update' {       
                try {
                    //new AccessUtils().UpdateWithoutSharing(listSObjects, SchemaDescribeFieldResult);
                    Database.update(listSObjects);
                    return 'The record has been updated successfully.';
                } catch(DmlException e){
                    throw e;
                }
            }
            when 'upsert' {       
                try {
                    //new AccessUtils().UpsertWithoutSharing(listSObjects, SchemaDescribeFieldResult, null);
                    Database.upsert(listSObjects);
                    return 'The record has been updated successfully.';
                } catch(DmlException e){
                    throw e;
                }
            }
            when 'delete' {       
                try {
                    //new AccessUtils().DeleteWithoutSharing(listSObjects);
                    Database.delete(listSObjects);
                    return 'The record has been deleted successfully.';
                } catch(DmlException e){
                    throw e;
                }
            }
            when else {
                throw error('We don\'t support this dml operation.');
            }
        }
    }
    
    public static List<SelectOption> getObjectsForSelectOption(){
        try {
            List<SelectOption> sobjects = new List<SelectOption>();
            Map<String, SObjectType> objs = Schema.getGlobalDescribe();
            for(String sobj: objs.keySet()){
                sobjects.add(new SelectOption(sobj, objs.get(sobj).getDescribe().getName()));
            }
            return sobjects;
        } catch (Exception e){
            throw e;
        }   
    }

    public static List<SelectOption> getFieldForSelectOption(String selectedSObject){
        try {
            Map<String, SObjectField> allFields = Schema.getGlobalDescribe().get(selectedSObject).getDescribe().fields.getMap();
            List<SelectOption> fields = new List<SelectOption>();
            for(String field: allFields.keySet()){
                fields.add(new SelectOption(field, allFields.get(field).getDescribe().getLabel()));
            }
            return fields;
        } catch (Exception e){
            throw e;
        }
    }
    
    @AuraEnabled
    public static void LogException(ExceptionModel e){
        System.debug('e : ' + e);
        ExceptionModel.LogException(e);
    }
}