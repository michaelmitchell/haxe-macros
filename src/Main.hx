import macros.Await;
import q.Q; 

@:build(macros.Async.build())
@:build(macros.Await.build())
class Main {

	static function main() {}

	public static function foo(i: Int) {
		trace(1);

		try {
			var x = switch (i) {
				case 1: 2;
				case 2: {
					if (i == 1) {
						throw "hello";
					}

					var a = @await bar(i);

					trace(a);

					3;
				}
				default: {
					@await bar(i);
				};
			}
		}
		catch (e: Error) {
			trace(e);
		}

		trace(2);
	}

	public static function bar(i: Int, ?__return) {
		return i;
	}

}

class Error {}
class AnotherError {}
