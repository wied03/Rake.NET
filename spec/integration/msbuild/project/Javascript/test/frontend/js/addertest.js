TestCase("adderTest", {
	testAdd : function() {
	  var adder = brady.firstrails.logic;
	  assertEquals(3, adder.addstuff());
	  assertEquals(6, adder.addstuff());
	}
});