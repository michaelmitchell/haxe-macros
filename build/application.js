(function () { "use strict";
var Main = function() { };
Main.main = function() {
	var a;
	var b;
	var c;
	var d = "something";
	var result1 = Main.foo("Hello");
	console.log("Hello");
};
Main.foo = function(value) {
	return value;
};
Main.__meta__ = { obj : { ext : null}, statics : { foo : { async : null}}};
Main.main();
})();

//# sourceMappingURL=application.js.map