package macros;

import com.sencha.extjs.ExtClass;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

class ExtJS {
	#if macro
	public static function build() {
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

			ExtClass.create($i{className}, __config);

			// override exts extend functionality in favour of haxes
			$i{className}.extend = function() {};
			$i{className}.triggerExtended = function () {};

			ExtClass.process($i{className}, __config);
		};

		if (initField == null) {
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
		}

		fields.push(initField);

		return fields;
	}
	#end
}