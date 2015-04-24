import macros.Await;

@:build(macros.Await.build())
class Main {

	static function main() {}

	@async public static function foo(i: Int) {
		try {
			var x = @await bar(1);

			if (i == 2) {
				throw "error";
			}

			return x;
		}
		catch (e: String) {
			trace(e);

			throw e;
		}
	}

	@async public static function bar(i: Int) {
		return 1;
	}

}