public class ExceptionModel {
    @AuraEnabled
    public String ExceptionType {get; set;}
    @AuraEnabled
    public String ExceptionMessage {get; set;}
    @AuraEnabled
    public String RelatedTo {get; set;}
    @AuraEnabled
    public String StackTrace {get; set;}
    @AuraEnabled
    public String ClassName {get; set;}
    @AuraEnabled
    public String MethodName {get; set;}
    @AuraEnabled
    public Integer Line {get; set;}

	// Log Exception in Custom object => Exception__c. 
    // relatedToId : Case/Lead/Account/Custom object for which this error in logged.
    public static void LogException(ExceptionModel e) {
        Exception__c ex = new Exception__c();
        ex.ExceptionType__c = e.ExceptionType;
        ex.ExceptionMessage__c = e.ExceptionMessage;
        ex.RelatedTo__c = e.RelatedTo;
        ex.StackTrace__c = e.StackTrace;
        ex.ClassName__c = e.className;
        ex.MethodName__c = e.methodName;
        ex.Line__c = e.Line;
        Database.insert(ex);                    
    } 
}