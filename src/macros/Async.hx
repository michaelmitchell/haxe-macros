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

	var callbackName:String;

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
		var i = 0;

		for (expr in exprs) {
			this.currentExpr = expr;

			switch(expr.expr) {
				case EBlock(exprs):
					this.handleBlock(exprs);

				case EReturn(e):
					this.handleReturn(e);

				default:
					this.append(this.currentExpr);
			}

			i++;

			// if return has not been used add a callback to the end of the function
			if (!this.isCalled && i == exprs.length) {
				var pos = Context.currentPos();

				this.append({
					expr: ECall({
						expr: EConst(CIdent(this.callbackName)),
						pos: pos
					}, [{
						expr: EConst(CIdent('null')),
						pos: pos
					}]),
					pos: pos
				});

				this.isCalled = true;
			}
		}
	}

	function handleReturn(e) {
		var pos = Context.currentPos();

		//replace return wtih call to callback function supporting error first callback style
		this.append({
			expr: ECall({
				expr: EConst(CIdent(this.callbackName)),
				pos: pos
			}, [{
				expr: EConst(CIdent('null')),
				pos: pos
			}, e]),
			pos: pos
		});

		this.isCalled = true;
	}

	function handle() {
		var chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'.split(''),
			id = [];

		for (i in 0...12) {
			id.push(chars[Math.round(Math.random() * chars.length - 1)]);
		}

		// cache return type to apply to callback value
		this.returnType = this.method.ret;

		//remove return type requirement
		this.method.ret = null;

		// create a semi unique callback name to prevent naming conflicts
		this.callbackName = 'callback_' + id.join('');
		
		var type = null;

		// apply return type to callback function for type checking
		if (this.returnType != null) {
			type = TFunction([
					TPath({name: 'Dynamic', pack: []}),
					this.returnType
				],
				TPath({name: 'Void', pack: []})
			);
		}

		// add callback to method as last argument
		this.method.args.push({
			name: this.callbackName,
			type: type 
		});

		//trace(this.method.args[1]);

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
