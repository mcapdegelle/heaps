package h2d;

class TileSheet
{
	public var main : Tile;
	public var groups : Map<String, Array<Tile>>;
	
	public function new(t) {
		this.main = t;
		groups = new Map<String, Array<Tile>>();
	}
	
	public function getTile(name : String, frame = 0) {
		if (frame != 0)
			return groups.get(name)[frame];
		
		var r = ~/([a-zA-Z]+)[-_]?([0-9]*)/;
		r.match(name);
		var nameFrame = r.matched(2);
		if (nameFrame != "") frame = Std.parseInt(nameFrame);
		return groups.get(r.matched(1))[frame];
	}
	
	public inline function getGroup(name : String) {
		return groups.get(name);
	}
	
	public inline function setTile(name : String, x, y, w, h, dx = 0, dy = 0) {
		groups.set(name, [main.sub(x, y, w, h, dx, dy)]);
	}
	
	public inline function pushTile(group : String, x, y, w, h, dx = 0, dy = 0) {
		var g = groups.get(group);
		if (g == null) {
			g = new Array<Tile>();
			groups.set(group, g);
		}
		g.push(main.sub(x, y, w, h, dx, dy));
	}
}