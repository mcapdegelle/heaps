package h2d;

import hxd.res.TiledMap;
import haxe.io.Path;

typedef TileInfo = {
	data    : TiledMapTileData, 
	tileset : TiledMapTileset,
}

class TiledLevel extends Sprite
{
	public var data (default, null) : TiledMapData;
	
	var groups    : Map<Int, TileGroup>;
	var mainTiles : Map<Int, Tile>;
	var subTiles  : Map<Int, Tile>;
	
	static var tmpTileData : TiledMapTileData;
	
	public function new(map : TiledMap, ?p) {
		super(p);
		
		data      = map.toMap();
		groups    = new Map<Int, TileGroup>();
		mainTiles = new Map<Int, Tile>();
		subTiles  = new Map<Int, Tile>();
		
		var dir = Path.directory(map.entry.path);
		
		// creates the tile cache
		for (ts in data.tilesets) {
			if (ts.image != null) { 
				// the tileset is a single image
				var main = createTile(ts, Path.join([dir, ts.image.source]));
				if (ts.margin != 0)
					main = main.sub(ts.margin, ts.margin, main.width - ts.margin * 2, main.height - ts.margin * 2);
				var tex = main.getTexture();
				mainTiles[tex.id] = main;
				var i = 0;
				for (t in main.grid(ts.tilewidth + ts.spacing)) {
					t.dy = -t.height;
					subTiles[ts.firstgid + i++] = t;
				}
			} else { 
				// the tileset is a collection of images
				for (td in ts.tiledata) {
					var sub = createTile(ts, Path.join([dir, td.image.source]));
					sub.dy = -sub.height;
					subTiles[ts.firstgid + td.id] = sub;
				}
			}
		}
		
		// spawn layers
		var index = 0;
		
		for (l in data.layers) {
			var spawnT = [];
			var spawnX = [];
			var spawnY = [];
			var spawnR = new Array<Float>();
			
			if (l.data != null) {
				// layer of tiles
				for (y in 0...data.height) {
					for (x in 0...data.width) {
						var gid = l.data[x + y * data.width];
						if (gid <= 0) continue;
						var tinfo = getTileInfo(gid);
						if (!spawnTile(l, tinfo, x, y)) continue;

						spawnT.push(subTiles[tinfo.tileset.firstgid + tinfo.data.id]);
						spawnX.push(data.tilewidth * x);
						spawnY.push(data.tileheight * (y + 1));
						spawnR.push(0);
					}
				}
			} else if (l.objects != null) {
				// layer of objects
				for (o in l.objects) {
					var tinfo = getTileInfo(o.gid);
					if (!spawnObject(l, o, tinfo)) continue;
					
					spawnT.push(subTiles[tinfo.tileset.firstgid + tinfo.data.id]);
					spawnX.push(o.x);
					spawnY.push(o.y);
					spawnR.push(o.rotation);
				}
			}
			
			if (spawnT.length == 0) return;
			
			var canGroupImages = true;
			var texid = spawnT[0].getTexture().id;
			for (t in spawnT) if (t.getTexture().id != texid) { canGroupImages = false; break; }
			
			trace("layer " + l.name + " can group ? " + canGroupImages);
			
			for (i in 0...spawnT.length)
				_spawnTile(index, spawnT[i], spawnX[i], spawnY[i], spawnR[i], canGroupImages);
			
			++index;
		}
	}

	/*
	 * This function is called when the level loads a texture to create its tile.
	 * Override this to change the texture source, or to retrive tiles from an atlas...  
	 */	
	public function createTile(tileset : TiledMapTileset, path : String) : h2d.Tile {
		return hxd.Res.load(path).toTile();
	}
	
	/*
	 * Override this to do something on tile spawning
	 * ie. Spawn game entites, add physics ...
	 * return true to display the tile, or false to discard it
	 */
	public function spawnTile(layer : TiledMapLayer, tinfo : TileInfo, x : Int, y : Int) : Bool { return true; }
	
	/*
	 * Override this to do something on object spawning
	 * ie. Spawn game entites, add physics ...
	 * return true to display the object, or false to discard it
	 */
	public function spawnObject(layer : TiledMapLayer, obj : TiledMapObject, ?tinfo : TileInfo) : Bool { return true; }
	
	public function getLayer(name) {
		for (l in data.layers) if (l.name == name) return l;
		return null;
	}
	
	public function getTileset(name) {
		for (t in data.tilesets) if (t.name == name) return t;
		return null;
	}
	
	function _spawnTile(layer : Int, tile : Tile, x : Int, y : Int, rotation : Float, canGroupImages : Bool) {
		var tex     = tile.getTexture();
		var groupId = (layer << 16) | tex.id;
		var group   = groups[groupId];
		if (group == null) {
			var main = mainTiles[tex.id];
			if (main == null) {
				if (!canGroupImages) {
					var img = new Bitmap(tile, this);
					img.x = x; img.y = y; img.rotation = rotation;
					return;
				}
				main = Tile.fromTexture(tex);
				mainTiles[tex.id] = main;
			}
			group = new TileGroup(main, this);
			groups[groupId] = group;
		}
		group.add(x, y, tile);
	}
	
	function getTileInfo(gid) : TileInfo {
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