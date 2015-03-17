package macros;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Printer;

class Async {

	var field:Field;

	var method:Function;

	var metadata:Metadata;

	var rootExpr:Expr;

	var rootBlock:Array<Expr>;

	var currentBlock:Array<Expr>;

	var currentExpr:Expr;

	var currentMetadataEntry:MetadataEntry;

	var currentMetadataExpr:Expr;

	var currentVar:Var;

	static function build() {
		var fields = Context.getBuildFields();

		for (field in fields) {
			switch (field.kind) {
				case FFun(method):
					if (method.expr != null) {
						method = Async.run(field, method);
					}
				default:
			}
		}

		return fields;
	}

	static function run(field:Field, method:haxe.macro.Function) {
		var instance = new Async(field, method);

		method.expr = instance.handle();

		return method;
	}

	function new(field:Field, method:haxe.macro.Function) {
		this.field = field;
		this.method = method;
		this.metadata = field.meta;

		this.rootExpr = method.expr;
		this.currentExpr = this.rootExpr;

		this.rootBlock = [];
		this.currentBlock = this.rootBlock;

		for (metadata in this.metadata) {
			if (metadata.name == 'async') {
				this.addCallbackFn();
			}
		}
	}

	function addCallbackFn() {
		this.method.args.push({name: 'callback', type: null});
	}

	function handleBlock(exprs:Array<Expr>) {
		for (expr in exprs) {
			this.currentExpr = expr;

			switch(expr.expr) {
				case EBlock(exprs):
					this.handleBlock(exprs);

				case EVars(vars):
					this.handleVars(vars);

				default:
					this.append(this.currentExpr);
			}
		}
	}

	function handleVars(vars:Array<Var>) {
		for (v in vars) {
			this.currentVar = v;
			
			var expr = v.expr;

			if (expr != null) {
				switch (expr.expr) {
					case EMeta(s, e):
						this.handleMeta(s, e);

					default:
						this.append(this.currentExpr);
				}
			}
			else {
				this.append(this.currentExpr);
			}
		}
	}

	function handleMeta(s, e) {
		this.currentMetadataEntry = s;
		this.currentMetadataExpr = e;

		if (s.name == 'await') {
			switch (e.expr) {
				case ECall(e, p):
					this.handleCall(e, p);

				default:
					this.append(this.currentExpr);
			}
		}
		else {
			this.append(this.currentExpr);
		}
	}

	function handleCall(ce, p) {
		var v = this.currentVar,
			pos = Context.currentPos(),
			method = Context.parse('function(' + v.name + ') {}', pos);

		p.push(method);

		var e = this.currentMetadataExpr;

		this.append({
			expr: EBlock([e]),
			pos: pos
		});

		// create write block
		var newBlock = [];

		switch (method.expr) {
			case EFunction(name, fe):
				// replace new methods block with new write target
				fe.expr = {
					expr: EBlock(newBlock),
					pos: pos
				};

				this.currentBlock = newBlock;

			default:
		}
	}

	function handle() {
		var expr = this.rootExpr;

		this.currentExpr = expr;

		// first expr should be block
		switch(expr.expr) {
			case EBlock(exprs):
				this.handleBlock(exprs);

			default:
				this.append(expr);
		}

		return {
			expr: EBlock(this.rootBlock),
			pos: Context.currentPos()
		};
	}

	function append(expr:Expr) {
		this.currentBlock.push(expr);
	}

}
