package h2d;

import hxd.res.TiledMap;
import haxe.io.Path;

class TiledLevel extends Sprite
{
	public var data (default, null) : TiledMapData;
	
	var groups   : Map<String, TileGroup>;
	var sheets   : Map<String, Tile>;
	var tilesets : Map<String, Array<Tile>>;
	
	static var tmpTileData : TiledMapTileData;
	
	public function new(map : TiledMap, ?p) {
		super(p);
		
		groups   = new Map<String, TileGroup>();
		sheets   = new Map<String, Tile>();
		tilesets = new Map<String, Array<Tile>>();
		data     = map.toMap();
		
		var dir = Path.directory(map.entry.path);
		
		// populate tilesets
		for (ts in data.tilesets) {
			if (ts.image != null) {
				// tileset from a single image
				var master = loadImage(Path.join([dir, ts.image.source]), true);
				sheets  [ts.name] = master;
				tilesets[ts.name] = master.grid(ts.tilewidth);
			} else {
				// tileset from a collection of images
				var set = [];
				for (td in ts.tiledata)
					set[td.id] = loadImage(Path.join([dir, td.image.source]), false);
				tilesets[ts.name] = set;
			}
		}
		
		// spawn layers
		var ts = data.tilesets[0];
		for (l in data.layers) {
			if (l.data != null) {
				// layer of tiles
				for (y in 0...data.height) {
					for (x in 0...data.width) {
						var gid = l.data[x + y * data.width];
						if (gid <= 0) continue;
						var tinfo = getTileInfo(gid);
						var keepTile = spawnTile(l, tinfo.data, x, y);
						if (keepTile) _spawnTile(l, ts, tinfo.data.id, x * data.tilewidth, y * data.tileheight);
					}
				}
			} else if (l.objects != null) {
				// layer of objects
				for (o in l.objects) {
					var tinfo = getTileInfo(o.gid);
					var keepTile = spawnObject(l, o, tinfo.data);
					if (tinfo != null && keepTile) _spawnTile(l, tinfo.tileset, tinfo.data.id, o.x, o.y, o.rotation);
				}
			}
		}
	}
	
	/*
	 * Override this to do something on object spawning
	 * ie. Spawn game entites, add physics ...
	 * return true to display the object, or false to discard it
	 */
	public function spawnObject(layer : TiledMapLayer, obj : TiledMapObject, ?tile : TiledMapTileData) : Bool { return true; }
	
	/*
	 * Override this to do something on tile spawning
	 * ie. Spawn game entites, add physics ...
	 * return true to display the tile, or false to discard it
	 */
	public function spawnTile(layer : TiledMapLayer, tile : TiledMapTileData, x : Int, y : Int) : Bool { return true; }
	
	/*
	 * Override this to change the way tiles are created
	 * ie. create the tile from a TexturePacker atlas...
	 * "tileset" specifies if the tile is in a tileset or is a simple image
	 */	
	public function createTile(path : String, tileset : Bool) : h2d.Tile {
		var t = hxd.Res.load(path).toTile();
		t.dy = -t.height;
		return t;
	}
	
	public function getLayer(name) {
		for (l in data.layers) if (l.name == name) return l;
		return null;
	}
	
	public function getTileset(name) {
		for (t in data.tilesets) if (t.name == name) return t;
		return null;
	}
	
	function _spawnTile(layer, tileset, id, x, y, ?rotation) {
		if (rotation != null && rotation != 0.0) throw "rotation not handled yet...";
		
		if (sheets.exists(tileset.name)) { 
			// tile from an image region
			getGroup(layer.name, tileset.name).add(x, y, tilesets[tileset.name][id]);
		} else {
			// tile from an image
			var t = new Bitmap(tilesets[tileset.name][id], this);
			t.x = x; t.y = y;
		}
	}
	
	function getGroup(layer : String, tileset : String) : TileGroup {
		var key = layer + tileset;
		if (groups.exists(key))
			return groups[key];
		
		var tb = new h2d.TileGroup(sheets[tileset], this); 
		return tb;
	}
	
	function getTileInfo(gid) : {data : TiledMapTileData, tileset : TiledMapTileset} {
		if (gid == 0) return null;
		
		if (tmpTileData == null)
			tmpTileData = { id : 0, properties : new Map<String, String>(), image : null };
			
		// find the tileset
		var tileset = data.tilesets[0];
		for (ts in data.tilesets) {
			if (ts.firstgid > gid) break;
			tileset = ts;
		}
		
		var id = gid - tileset.firstgid;
		var tileData = tileset.tiledata[id];
		
		if (tileData == null) {
			tileData = tmpTileData;
			tileData.id = id;
		}
		
		return { data : tileData, tileset : tileset };
	}
}