/**/
import macros.Await;

@:build(macros.Async.build())
@:build(macros.Await.build())
/**/

class Main {

	static function main() {

	}

	public static function foo(a: Int, b: Int) {
		@await bar(0);

		try {
			trace(1);

			if (a == 1) {
				throw "banana";
			}

			@await bar(1);

			trace(2);

			try {
				@await bar(2);

				trace(2.1);

				throw "hello world";
			}
			catch (e: Error) {
				trace(2.2);
				
				throw "more";
			}

			if (a == 2) {
				throw "boat";
			}

			trace(3);
		}
		catch (e1: Error) {
			trace(e1);
		}
		catch (e2: AnotherError) {
			trace(e2);
		}

		trace('after');
	}

	@async static function bar(i: Int) {
		return i;
	}

}

class Error {}
class AnotherError {}
