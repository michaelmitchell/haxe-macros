(function () { "use strict";
var Main = function() { };
Main.main = function() {
	var a;
	var b;
	var c;
	var d = "something";
	Main.foo("Hello",function(result1) {
		console.log(result1);
		Main.foo("bar",function(result2) {
			console.log(result2);
			Main.foo("bar",function(result21) {
				console.log(result21);
			});
		});
	});
};
Main.foo = function(value,cb) {
	cb(value);
};
Main.__meta__ = { statics : { foo : { async : null}}};
Main.main();
})();

//# sourceMappingURL=application.js.map