(function() {
	window.brady = window.brady || {};
	var brady = window.brady;
	brady.firstrails =  brady.firstrails || {};
	
	brady.firstrails.mypage = function() {
		var adder = brady.firstrails.logic;
		var triggerElement;
		var resultElement;
		
		return {
			mypage : function (trigger,
							   result) {
				triggerElement = $(trigger);
				resultElement = $(result);
				triggerElement.click(displayresult);
				return this;
			}		
		};

		function displayresult() {
			resultElement.html("the value is "+adder.addstuff());
		}
	}();
})();


