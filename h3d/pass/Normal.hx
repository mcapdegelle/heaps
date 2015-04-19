package h3d.pass;

class Normal extends Default {

	var normalMapId : Int;
	public var reduceSize : Int = 0;

	public function new() {
		super();
		priority = 10;
		normalMapId = hxsl.Globals.allocID("normalMap");
	}

	override function getOutputs() {
		return ["output.position", "output.normal"];
	}

	override function draw( passes ) {
		var texture = tcache.allocTarget("normalMal", ctx, ctx.engine.width >> reduceSize, ctx.engine.height >> reduceSize);
		ctx.engine.setTarget(texture);
		ctx.engine.clear(0, 1);
		passes = super.draw(passes);
		ctx.sharedGlobals.set(normalMapId, texture);
		return passes;
	}

}