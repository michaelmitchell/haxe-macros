package macros;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;

class Async {

	var field:Field;

	var method:Function;

	var metadata:Metadata;

	var rootExpr:Expr;

	var rootBlock:Array<Expr>;

	var currentBlock:Array<Expr>;

	var currentExpr:Expr;

	var returnType:ComplexType;

	var isCalled:Bool = false;

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

		for (metadata in field.meta) {
			if (metadata.name == 'async') {
				method.expr = instance.handle();
			}
		}

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
		var pos = Context.currentPos(),
			i = 0;

		for (expr in exprs) {
			this.currentExpr = expr;

			switch(expr.expr) {
				case EBlock(exprs):
					this.handleBlock(exprs);

				case EIf(econd, eif, eelse):
					this.handleIf(econd, eif, eelse);

				case EReturn(e):
					this.handleReturn(e);

				default:
					this.append(this.currentExpr);
			}

			i++;

			// make sure we are back on the root block
			if (this.currentBlock == this.rootBlock) {
				// if return has not been used add a callback to the end of the function
				if (!this.isCalled && i == exprs.length) {
					this.append({
						expr: ECall({
							expr: EConst(CIdent('__return')),
							pos: pos
						}, [{
							expr: EConst(CIdent('null')),
							pos: pos
						}, {
							expr: EConst(CIdent('null')),
							pos: pos
						}]),
						pos: pos
					});

					// prevent callbacks from being called more than once
					this.append({expr: EReturn(null), pos: pos});
				}
			}
		}
	}

	function handleIf(econd, eif, eelse) {
		var pos = Context.currentPos(),
			currentBlock = this.currentBlock;

		if (eif != null) {
			var newIfBlock = [];

			this.currentBlock = newIfBlock;

			switch(eif.expr) {
				case EBlock(exprs):
					this.handleBlock(exprs);

				default:
			}

			eif.expr = EBlock(newIfBlock);
		}

		if (eelse != null) {
			var newElseBlock = [];

			this.currentBlock = newElseBlock;

			switch(eelse.expr) {
				case EBlock(exprs):
					this.handleBlock(exprs);

				default:
			}

			eelse.expr = EBlock(newElseBlock);
		}

		// switch back to previous block
		this.currentBlock = currentBlock;

		var expr = {
			expr: EIf(econd, eif, eelse),
			pos: pos
		};

		this.append(expr);
	}

	function handleReturn(e) {
		var pos = Context.currentPos();

		//replace return wtih call to callback function supporting error first callback style
		this.append({
			expr: ECall({
				expr: EConst(CIdent('__return')),
				pos: pos
			}, [{
				expr: EConst(CIdent('null')),
				pos: pos
			}, e]),
			pos: pos
		});

		// prevent callbacks from being called more than once
		this.append({expr: EReturn(null), pos: pos});

		if (this.currentBlock == this.rootBlock) {
			this.isCalled = true;
		}
	}

	function handle() {
		// cache return type to apply to callback value
		this.returnType = this.method.ret;

		//remove return type requirement
		this.method.ret = null;
		
		var type = null;

		// apply return type to callback function for type checking
		if (this.returnType != null) {
			type = TFunction([
					TPath({name: null, pack: []}),
					this.returnType
				],
				TPath({name: 'Void', pack: []})
			);
		}

		// add callback to method as last argument
		this.method.args.push({
			name: '__return',
			type: type 
		});

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
