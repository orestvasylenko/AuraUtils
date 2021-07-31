({
    
    /*
    helper.fetch(cmp,
    			'c.getRecords',
                {param1: 'Param1', param2: 'Param2'})
    */
    // ************************************************ MAIN SERVER SIDE ACTION ***
	fetch : function(cmp, method, params) {
        let self = this
        return new Promise($A.getCallback(function(resolve, reject) {
            cmp.set('v.spinner', true)
            const action = cmp.get(method)
            params && action.setParams(params)
            action.setCallback(this, response => {
                cmp.set('v.spinner', false)
                const state = response.getState()
                switch (state) {
                    case 'SUCCESS': resolve(response.getReturnValue())
                    	break
                    case 'INCOMPLETE': console.log('INCOMPLETE')
                    	break
                	case 'ERROR': const errors = response.getError()
                	errors 
                		? errors[0] && cmp.get('v.allowLogException') 
                					? self.fetch(cmp, 'c.LogException', { e: self.parseError(errors[0], cmp.get('v.recordId')) }) 
            						   && reject(self.parseError(errors[0], cmp.get('v.recordId'))) 
            						: reject(self.parseError(errors[0], cmp.get('v.recordId')))
                		: console.log('Unknown error')
                    	break
                    default: console.log(state)
                }
            })
            $A.enqueueAction(action)
        }))
    },
	// ************************************************ QUERY UTILS ***
    getQueryParams: function(sObject, 
                             fields, 
                             conditionals, 
                             groupByField, 
                             orderByField, 
                             quantity) {
        // Model of query params
        return new class QueryParams {
            constructor(sObjectApiName, 
                        fields, 
                        conditionals,
                        groupByField, 
                        orderByField, 
                        quantity) {
                
               this.sObjectApiName = sObjectApiName
               this.fields = fields
               this.conditionals = conditionals
               this.groupByField = groupByField
               this.orderByField = orderByField
               this.quantity = quantity
            }
        }
    },
    
    /*
        let params = helper.getQueryParams(sObject,      => 'Account'
                                           fields,       => ['Name', 'Phone']
                                           conditionals, => ["Name LIKE '%E%'", "Phone LIKE '%5%'"]
                                           groupByField, => 'Name'
                                           orderByField, => 'Name DESC'
                                           quantity)     => 10 (LIMIT)
    	helper.soql(cmp, params)
    */
    //Dynamic query. 
    soql: function(cmp, params) {
        let self = this;
		return new Promise($A.getCallback(function(resolve, reject) {
            self.fetch(cmp, 'c.getRecords', { params: params })
                .then(res => { resolve(res) })
                .catch(e => { reject(e) })
        }))
    },
	// ************************************************ DML UTILS ***
    getDmlParams: function(dml, data){
        let self = this
        // Model of dml params
        return new class DmlParams {
            constructor(dml, data) {
              this.dml = dml
              this.data = self.prepareDataTypeBeforeDml(data)
            }
        }
    },                   
    // Should be Array.
    prepareDataTypeBeforeDml: function(inputs){
        let self = this
        class UnsupportedTypes {
            constructor(type, supportedtypes, unsupportedtypes){
                this.type = type
                this.supportedtypes = ['array', 'object', 'string']
                this.unsupportedtypes = ['null', 'undefined', 'boolean', 'number']
            }
        }
		// Define type of variable. 
		// 1. If array => return inputs. 
		// 2. If object => convert to Array & return.
		// 3. If string => check type & follow 1 AND 2 rule.
        let output = self.typeOf(inputs) === 'object'
                          ? new Array(inputs)
                          : self.typeOf(inputs) === 'array' 
                              ? inputs
                              : self.typeOf(inputs) === 'string' 
                                  ? inputs.includes('Id') || 
            						inputs.includes('sObject') ? self.typeOf(JSON.parse(inputs)) === 'object'
                                                                   ? new Array(inputs)
                                                                       : self.typeOf(inputs) === 'array' 
                                                                           ? inputs
        																   : new UnsupportedTypes(self.typeOf(inputs))
                                  							   : 'Cant find Id or sObject field in json'
                                  : new UnsupportedTypes(self.typeOf(inputs))
        return output
    },
    // Get Type Of Variable
    typeOf: function(inputs){
  		return Object.prototype.toString.call(inputs)
                     .substring(Object.prototype.toString.call(inputs).indexOf(" ") + 1, 
                                Object.prototype.toString.call(inputs).indexOf("]")).toLowerCase()
    },
    /*
        let params = helper.getDmlParams(dml,  => could be: 'insert', 'update', 'upsert', 'delete'
                                         data) => could be: array, object, json
    	helper.dml(cmp, params)
    */
    // DML
    dml: function(cmp, params) {
        let self = this;
		return new Promise($A.getCallback(function(resolve, reject) {
           self.fetch(cmp, 'c.dml', 
           { params : params })
           .then(res => { resolve(res) })
           .catch(e => { reject(e) })
        }))
    },
    // ************************************************ ADDITIONALLY UTILS ***
    toast : function(title, type, message) {
        const show = $A.get('e.force:showToast')
        show.setParams({
            'title': title,
            'type': type,
            'message': message
        });
        show.fire()
    },
    
    parseError: function(e, relatedId){
		let errorPath = e.stackTrace.substring(e.stackTrace.indexOf('\nClass'), e.stackTrace.length)
        const getCurrentErrorPath = stackTrace => {
        	return errorPath.substring(errorPath.lastIndexOf('Class.'), 
            						   errorPath.indexOf(':')).replace('Class.', '')
        }
        
        let error = getCurrentErrorPath(e.stackTrace)

        let exceptionType = e.exceptionType
        let exceptionMessage = e.message
        let relatedTo = relatedId ? relatedId : $A.get("$SObjectType.CurrentUser.Id")
        let stackTrace = e.stackTrace
        let className = error.substring(0, error.indexOf('.'))
        let methodName = error.substring(error.indexOf('.') + 1, error.length)
        let line = errorPath.slice(errorPath.lastIndexOf('line ') + 'line '.length, 
                                   errorPath.indexOf(', '))

        let Exception = {
            exceptionType: exceptionType,
            exceptionMessage: exceptionMessage,
            relatedTo: relatedTo,
            stackTrace: stackTrace,
            className: className,
            methodName: methodName,
            line: line
        }
        
        return Exception
    },
})