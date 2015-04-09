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

	public static function foo(a: Int, b: Int) {
		trace('before all');

		switch (a) {
			case 1:
				trace(1);
			case 2:
				switch (b) {
					case 1:
						trace(1);
						do {
							trace(a);	

							if (a == 1) {
								continue;
							}

							@await bar(1);

							if (b == 1) {
								break;
							}

							trace(b);
						}
						while (a < 0);

						trace(1.1);
					case 2:
						trace(2);
				}
			case 3:
				trace(3);
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
