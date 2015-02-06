@:build(macros.Async.build())

class Main {

	public static function main() {
		var result1 = @await foo('1');

		trace(result1);

		var result2 = @await foo('2');

		trace(result2);

		var result3 = @await foo('3');

		trace(result3);
	}
	
	@async public static function foo(value:String) {
		return value;
	}

}
