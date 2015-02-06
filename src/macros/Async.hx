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

	public static function build() {
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

	public static function run(field:Field, method:haxe.macro.Function) {
		var instance = new Async(field, method);

		method.expr = instance.process();

		return method;
	}

	public function new(field:Field, method:haxe.macro.Function) {
		this.field = field;
		this.method = method;
		this.metadata = field.meta;

		trace(this.metadata);

		this.rootExpr = method.expr;
		this.currentExpr = this.rootExpr;

		this.rootBlock = [];
		this.currentBlock = this.rootBlock;
	}

	public function processBlock(exprs:Array<Expr>) {
		for (expr in exprs) {
			this.currentExpr = expr;

			switch(expr.expr) {
				case EBlock(exprs):
					this.processBlock(exprs);

				case EVars(vars):
					this.processVars(vars);

				default:
					this.append(this.currentExpr);
			}
		}
	}

	public function processVars(vars:Array<Var>) {
		for (v in vars) {
			this.currentVar = v;
			
			var expr = v.expr;

			if (expr != null) {
				switch (expr.expr) {
					case EMeta(s, e):
						this.processMeta(s, e);

					default:
						this.append(this.currentExpr);
				}
			}
			else {
				this.append(this.currentExpr);
			}
		}
	}

	public function processMeta(s, e) {
		this.currentMetadataEntry = s;
		this.currentMetadataExpr = e;

		if (s.name == 'await') {
			switch (e.expr) {
				case ECall(e, p):
					this.processCall(e, p);

				default:
					this.append(this.currentExpr);
			}
		}
		else {
			this.append(this.currentExpr);
		}
	}

	public function processCall(ce, p) {
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

	public function process() {
		var expr = this.rootExpr;

		this.currentExpr = expr;

		// first expr should be block
		switch(expr.expr) {
			case EBlock(exprs):
				this.processBlock(exprs);

			default:
				this.append(expr);
		}

		return {
			expr: EBlock(this.rootBlock),
			pos: Context.currentPos()
		};
	}

	public function append(expr:Expr) {
		this.currentBlock.push(expr);
	}

}
