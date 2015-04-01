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
		if (i == 1) {
			pie();

			@await bar(1);

			trace(1);
		}
		else if (i == 2) {
			pie();

			@await bar(1);

			if (i == 2) {
				@await bar(2);
			}

			trace(3);
		}
		else {
			pie();
			
			@await bar(1);

			trace(3);
		}
	}

	@async static function bar(i: Int) {
		return i;
	}

	static function pie() {
		trace('pie is tasty');
	}

}

class Error {

	var message: String;
	
	public function new(m: String) {
		this.message = m;
	}

}
