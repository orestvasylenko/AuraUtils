({
	allowLogException : function(cmp) {
        //Set Boolean Value LogException Function => check it in helper => fetch 
		cmp.set('v.allowLogException', true)
        console.log(cmp.get('v.allowLogException'))
	},
    
    restrictLogException : function(cmp) {
        //Set Boolean Value LogException Function => check it in helper => fetch 
		cmp.set('v.allowLogException', false)
        console.log(cmp.get('v.allowLogException'))
	}
})