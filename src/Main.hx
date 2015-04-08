/**
import com.dongxiguo.continuation.Continuation;

@:build(com.dongxiguo.continuation.Continuation.cpsByMeta(":async"))
/**/

/**/
import macros.Await;

@:build(macros.Async.build())
@:build(macros.Await.build())
/**/

class Main {

	static function main() {

	}

	public static function foo(i: Int) {
		trace('before all');

		if (i == 1) {
			trace('before');

			if (i == 2) {
				if (i == 3) {
					//@await bar(1);
				}

				trace(1);
			}
			else if (i == 3) {
				trace(1);

				return;
			}
		
			trace('after');
		}

		trace('after all');
	}

	@async static function bar(i: Int) {
		return i;
	}

}

class Error {

	var message: String;
	
	public function new(m: String) {
		this.message = m;
	}

}
