@:build(macros.Async.build())
@:build(macros.Await.build())

class Main {

	static function main() {
	}

	@async static function foo(value: Int) {
	}

	@async static function bar(value: Int) {
		try {
			switch (value) {
				case 1:
					trace(1);
					return 1;
				default:
					trace(2);
					return 2;
			}
		}
		catch (e: Dynamic) {
			return 1;
		}
		
		return 1;
	}

}
