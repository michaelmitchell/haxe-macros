package macros.sencha;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

class ExtJS {
	#if macro
	public static function buildClass() {
		var fields = Context.getBuildFields();

		var config = macro null;
		var mixins = macro null;
		var initField;

		for (field in fields) {
			if (field.name == '__init__') {
				initField = field;
			}
			else {
				switch (field.kind) {
					case FVar(t, expr): {
						if (field.name == 'config') {
							config = expr;
						}
						else if (field.name == 'mixins') {
							mixins = expr;
						}
					}
					default:
				}
			}
		}

		var pos = Context.currentPos();

		var extendField = {
			pos: pos,
			name: 'extend',
			meta: [{
				name: ':extern',
				params: [],
				pos: pos
			}],
			kind: FFun({
				args: [],
				expr: {expr: EBlock([]), pos: pos},
				params: [],
				ret: TPath({
					name: 'Void',
					pack: [],
					params: []
				})
			}),
			doc: null,
			access: [ADynamic, AStatic]
		};

		fields.push(extendField);

		var triggerExtendedField = {
			pos: pos,
			name: 'triggerExtended',
			meta: [{
				name: ':extern',
				params: [],
				pos: pos
			}],
			kind: FFun({
				args: [],
				expr: {expr: EBlock([]), pos: pos},
				params: [],
				ret: TPath({
					name: 'Void',
					pack: [],
					params: []
				})
			}),
			doc: null,
			access: [ADynamic, AStatic]
		};

		fields.push(triggerExtendedField);

		var className = Context.getLocalClass().toString();

		className = className.substr(className.lastIndexOf('.') + 1);

		var initExpr = macro {
			var __config = {
				config: $config,
				mixins: $mixins
			};

			com.sencha.extjs.ExtClass.create($i{className}, __config);

			// override exts extend functionality in favour of haxes
			$i{className}.extend = function() {};
			$i{className}.triggerExtended = function () {};

			com.sencha.extjs.ExtClass.process($i{className}, __config);
		};

		if (initField == null) {
			// create an init expr if it does not already exist
			initField = {
				pos: pos,
				name: '__init__',
				meta: [],
				kind: FFun({
					args: [],
					expr: initExpr,
					params: [],
					ret: TPath({
						name: 'Void',
						pack: [],
						params: []
					})
				}),
				doc: null,
				access: [AStatic]
			};

			fields.push(initField);
		}
		else {
			// add init expr to start of existing init function
			switch (initField.kind) {
				case FFun({expr: {expr: EBlock(exprs)}}): {
					exprs.unshift(initExpr);
				}
				default:
			}
		}

		return fields;
	}

	public static function buildEvents() {
		var fields = Context.getBuildFields();
		var newField;
		var events = [];

		for (field in fields) {
			switch (field.kind) {
				case FFun(method): {
					if (field.name == 'new') {
						newField = field;
					}
					else {
						for (m in field.meta) {
							if (m.name == 'on') {
								switch (m.params[0].expr) {
									case EConst(CString(s)): {
										events.push({
											method: field.name,
											name: s
										});
									}
									default:
								}
							}
						}
					}
				}
				default:
			}
		}

		var pos = Context.currentPos();
		var block = [];
		var blockExpr = {expr: EBlock(block), pos: pos};

		for (event in events) {
			var name = event.name;
			var method = event.method;

			block.push(macro this.on('${name}', this.$method));
		}

		if (newField == null) {
			// create an init expr if it does not already exist
			newField = {
				pos: pos,
				name: 'new',
				meta: [],
				kind: FFun({
					args: [{
						name: 'config',
						type: null,
						opt: true,
						value: null
					}],
					expr: macro {
						super(config);

						$blockExpr;
					},
					params: [],
					ret: TPath({
						name: 'Void',
						pack: [],
						params: []
					})
				}),
				doc: null,
				access: [APublic]
			};

			fields.push(newField);
		}
		else {
			switch (newField.kind) {
				case FFun({expr: {expr: EBlock(exprs)}}): {
					exprs.push(blockExpr);
				}
				default:
			}
		}

		return fields;
	}
	#end
}
