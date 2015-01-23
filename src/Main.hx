@:build(macros.Async.build())

class Main {

	public static function main() {
		var a:Int, b:Int, c:Int;

		var d = "something";

		var result1 = @await foo('Hello');

		trace(result1);

		var result2 = @await foo('bar');

		trace(result2);

		var result2 = @await foo('bar');

		trace(result2);
	}
	
	@async public static function foo(value:String, ?cb) {
		cb(value);
	}

}
