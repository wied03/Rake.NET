(function() {
	window.brady = window.brady || {};
	var brady = window.brady;
	brady.firstrails =  brady.firstrails || {};
	
	brady.firstrails.logic = function() {
		var privatevar = 0;
		
		return {			
			addstuff : function() {
				var value = privatemethod();
				return value;
			}
		};
		
		function privatemethod() {
			return privatevar+=3;
		}
	}();
})();