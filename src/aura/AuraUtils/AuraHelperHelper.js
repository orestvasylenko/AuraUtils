({
    //$A.enqueueAction(cmp.get('c.myAction'));
    
    /*
    helper.fetch(cmp,
    			'c.getRecords',
                {param1: 'Param1', param2: 'Param2'})
    */
    //Apex Server Side Action
	fetch : function(cmp, method, params) {
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
                		? errors[0] && reject(errors[0].message)
                		: console.log('Unknown error')
                    	break
                    default: console.log(state)
                }
            })
            $A.enqueueAction(action)
        }))
    },
    
    /*helper.soql(cmp, 
                 'Account', 		 => sObject Api Name
                 ['Name', 'Phone'],  => Fields
                 ["Name LIKE '%E%'", => Conditionals WHERE
                 "Phone LIKE '%5%'"],=> Conditionals AND / OR
                 'Name', 			 => groupByField
                 'Name DESC', 		 => orderByField
                 10) 				 => quantity
    */
    //Dynamic query. 
    soql: function(cmp, sObject, fields, conditionals, groupByField, orderByField, quantity) {
        let self = this;
		return new Promise($A.getCallback(function(resolve, reject) {
           self.fetch(cmp, 'c.getRecords', 
           {  
              sObjectApiName: sObject, 
              fields: fields,
              conditionals: conditionals,
              groupByField: groupByField,
              orderByField: orderByField,
              quantity: quantity
           })
           .then(res => { resolve(res) })
           .catch(e => { reject(e) })
        }))
    },
                         
    dml: function(cmp, dml, data) {
        let self = this;
		return new Promise($A.getCallback(function(resolve, reject) {
           self.fetch(cmp, 'c.dml', 
           {  
              dml: dml,
              data: data
           })
           .then(res => { resolve(res) })
           .catch(e => { reject(e) })
        }))
    },
                         
    toast : function(title, type, message) {
        const show = $A.get('e.force:showToast')
        show.setParams({
            'title': title,
            'type': type,
            'message': message
        });
        show.fire()
    },
})