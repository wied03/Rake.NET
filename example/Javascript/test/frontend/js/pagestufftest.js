TestCase("pageStuffTest", {
	setUp : function() {
		 /*:DOC += <span id="trigger"></span> */
		 /*:DOC += <span id="result"></span> */	
		 brady.firstrails.logic.addstuff = function() {
			return "i mocked it";
		}
		// Mocking JQuery AJax calls can be done too.  jQuery.ajax = function ...
	},
	testEventBind : function() {
		var stuff = brady.firstrails.mypage.mypage("#trigger", "#result");
		$("#trigger").click();
		assertEquals("the value is i mocked it",
					 $("#result").html())
	}
});