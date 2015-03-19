package macros;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;

class Await {

	var field:Field;

	var method:Function;

	var metadata:Metadata;

	var rootExpr:Expr;

	var rootBlock:Array<Expr>;

	var currentBlock:Array<Expr>;

	var currentExpr:Expr;

	var currentBinop:Binop;
	
	var currentBinopExpr1:Expr;

	var currentBinopExpr2:Expr;

	var currentMetadataEntry:MetadataEntry;

	var currentMetadataExpr:Expr;

	var currentVar:Var;

	static function build() {
		var fields = Context.getBuildFields();

		for (field in fields) {
			switch (field.kind) {
				case FFun(method):
					if (method.expr != null) {
						method = Await.run(field, method);
					}
				default:
			}
		}

		return fields;
	}

	static function run(field:Field, method:haxe.macro.Function) {
		var instance = new Await(field, method);

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
	}

	function handleBlock(exprs:Array<Expr>) {
		for (expr in exprs) {
			this.currentExpr = expr;

			switch(expr.expr) {
				case EBinop(op, e1, e2):
					this.handleBinop(op, e1, e2);

				case EBlock(exprs):
					this.handleBlock(exprs);

				case EVars(vars):
					this.handleVars(vars);

				case EMeta(s, e):
					this.handleMeta(s, e);

				default:
					this.append(this.currentExpr);
			}
		}
	}

	function handleBinop(op, e1, e2) {
		if (op == OpAssign) {
			this.currentBinop = op;
			this.currentBinopExpr1 = e1;
			this.currentBinopExpr2 = e2;

			var expr = e2.expr;

			if (expr != null) {
				switch (expr) {
					case EMeta(s, e):
						this.handleMeta(s, e);

					default:
						this.append(this.currentExpr);
				}
			}
			else {
				this.append(this.currentExpr);
			}

			this.currentBinop = null;
			this.currentBinopExpr1 = null;
			this.currentBinopExpr2 = null;
		}
		else {
			this.append(this.currentExpr);
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
			
			this.currentVar = null;
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

		this.currentMetadataEntry = null;
		this.currentMetadataExpr = null;
	}

	function handleCall(ce, p) {
		var pos = Context.currentPos();

		this.append({expr: EBlock([this.currentMetadataExpr]), pos: pos});

		// create write block
		var binopExpr1 = this.currentBinopExpr1,
			currentVar = this.currentVar,
			name;

		//work out the name of assignment if any
		if (binopExpr1 != null) {
			switch (binopExpr1.expr) {
				case EConst(c):
					switch (c) {
						case CIdent(s):
							name = s;
						default:
					}
				default:
			}
		}
		else if (currentVar != null) {
			name = 'var ' + currentVar.name;
		}
		
		var method = Context.parse('function(error, __result) {}', pos);

		p.push(method);

		// the new root block inside the callback function
		var newBlock = [];

		// add assignment if there is one...
		if (name != null) {
			var opAssign =  Context.parse(name + ' = __result', pos);

			newBlock.push(opAssign);
		}

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
		switch (expr.expr) {
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
