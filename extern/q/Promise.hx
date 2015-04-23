package q;

extern class Promise {
	function then(result: Dynamic -> Void, error: Dynamic -> Void): Promise;
}
