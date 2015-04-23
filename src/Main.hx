import macros.Await;
import q.Q; 

@:build(macros.Async.build())
@:build(macros.Await.build())
class Main {

	static function main() {}

	public static function foo(i: Int) {
		try {
			trace(1);

			@await bar(i);

			trace(2);

			if (i == 1) {
				var x = @pwait bar(i);

				trace(x);
			}

			trace(1);
		}
		catch (e: String) {
			trace(e);
		}
		
		trace('after catching');
	}

	public static function bar(i: Int, ?__return) {
		var defer = Q.defer();

		return defer.promise;
	}

}

class Error {}
class AnotherError {}
