import mt.deepnight.PathFinder;
import mt.deepnight.Bresenham;
import mt.deepnight.Color;
import mt.deepnight.Lib;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.BlendMode;
import mt.MLib;

@:bitmap("assets/levels.png") class GfxSource extends BitmapData {}

typedef Cell = {
	var coll		: Bool;
	var blockSight	: Bool;
}

class Level {
	public static var PSCALE = 5;
	public static var SHADOW = 0x0F252D;

	public var wid		: Int;
	public var hei		: Int;
	public var lid		: Int;

	public var map		: Array<Array<Cell>>;
	public var pf		: PathFinder;
	var pt0				: flash.geom.Point;

	public var spots	: Map<String, Array<{cx:Int, cy:Int}>>;

	public var lightSources	: Array<{cx:Int, cy:Int, tx:Int, ty:Int, active:Bool}>;
	var lightMap		: Array<Array<Float>>;
	var bg				: Bitmap;
	var darkFog			: Bitmap;
	var darkPerlin		: BitmapData;
	var darkMask		: BitmapData;
	var coldMask		: BitmapData;

	var fow				: BitmapData;
	var fowRender		: Bitmap;
	var rseed			: mt.Rand;

	public function new(lid:Int) {
		this.lid = lid;
		wid = 32;
		hei = 32;
		spots = new Map();
		lightSources = [];
		rseed = new mt.Rand(0);
		pt0 = new flash.geom.Point();

		var source = new GfxSource(0,0);

		map = new Array();
		for(cx in 0...wid) {
			map[cx] = new Array();
			for(cy in 0...hei) {
				var p = source.getPixel(cx+lid*32,cy);
				if( p==0xFFFFFF ) addSpot("wall", cx,cy);
				if( p==0x00FF00 ) addSpot("hero", cx,cy);
				if( p==0xFF0000 ) addSpot("mobs", cx,cy);
				if( p==0x750000 ) addSpot("patrol", cx,cy);
				if( p==0xffae00 ) addSpot("light", cx,cy);
				if( p==0x777777 ) addSpot("props", cx,cy);
				if( p==0x654382 ) addSpot("entrance", cx,cy);
				if( p==0x0000ff ) addSpot("exit", cx,cy);
				if( p==0x20531f ) addSpot("tree", cx,cy);
				if( p==0xde58ff ) addSpot("blood", cx,cy);
				if( p==0x2cd0c2 ) addSpot("fence", cx,cy);
				if( p==0xbfe5ff ) addSpot("window", cx,cy);
				if( p==0x625cb2 ) addSpot("sister", cx,cy);
				map[cx][cy] = {
					coll		: p==0xFFFFFF || p==0x777777 || p==0x20531f || p==0x654382 || p==0x2cd0c2 || p==0xbfe5ff,
					blockSight	: p==0xFFFFFF || p==0xbfe5ff,
				}
				if( p==0x20531f ) // tree
					map[cx][cy-1].coll = true;
			}
		}

		source.dispose();

		pf = new PathFinder(wid,hei);
		pf.cacheSymetricPaths = false; // unknown bug, to be fixed later
		for(cx in 0...wid)
			for(cy in 0...hei)
				pf.setCollision(cx,cy, hasCollision(cx,cy));

		for(pt in getSpots("light"))
			addLight(pt.cx, pt.cy);

		var w = wid*Const.GRID;
		var h = hei*Const.GRID;

		bg = new Bitmap( new BitmapData(w, h, true, 0x0) );
		Game.ME.sdm.add(bg, Const.DP_BG);

		coldMask = bg.bitmapData.clone();

		fow = new BitmapData(w+32,h+32, true, Color.addAlphaF(SHADOW));
		fowRender = new Bitmap(fow.clone());
		#if !debug
		Game.ME.sdm.add(fowRender, Const.DP_FOG);
		#end
		fowRender.x = fowRender.y = -16;

		darkPerlin = new BitmapData(MLib.ceil(w/PSCALE), MLib.ceil(h/PSCALE), true, 0x0);
		darkMask = darkPerlin.clone();

		darkFog = new Bitmap(darkPerlin.clone());
		Game.ME.sdm.add(darkFog, Const.DP_FOG);
		darkFog.scaleX = darkFog.scaleY = PSCALE;

		render();
	}


	public function destroy() {
		bg.bitmapData.dispose();
		bg.bitmapData = null;

		darkFog.bitmapData.dispose();
		darkFog.bitmapData = null;

		darkPerlin.dispose();
		darkMask.dispose();
		fow.dispose();
		coldMask.dispose();

		fowRender.bitmapData.dispose();
		fowRender.bitmapData = null;
	}


	public function revealFog(cx,cy, ?r=5) {
		var rect = new flash.geom.Rectangle(0,0,Const.GRID,Const.GRID);
		var changed = false;
		fow.colorTransform(fow.rect, new flash.geom.ColorTransform(0,0,0,1, 0,255,0));
		for(x in cx-r...cx+r+1)
			for(y in cy-r...cy+r+1)
				if( Lib.distanceSqr(x,y,cx,cy)<=r*r && sightCheck(cx,cy, x,y) && fow.getPixel32(16+x*Const.GRID, 16+y*Const.GRID)!=0x0 ) {
					changed = true;
					rect.x = 16 + x*Const.GRID;
					rect.y = 16 + y*Const.GRID;
					fow.fillRect(rect, 0x0);
					Fx.ME.revealFog(x,y);
				}

		// Render
		var bd = fowRender.bitmapData;
		if( changed ) {
			fow.applyFilter(fow,fow.rect, pt0, new flash.filters.GlowFilter(0xFF0000,1, 32,32,4, 1,true));
			bd.copyChannel(fow, fow.rect, pt0, flash.display.BitmapDataChannel.GREEN, flash.display.BitmapDataChannel.ALPHA);
		}
		//bd.colorTransform(bd.rect, new flash.geom.ColorTransform(1,1,1, 0.6));
		//bd.draw(fow);
	}


	function initLight() {
		// Map
		lightMap = [];
		for( cx in 0...wid ) {
			lightMap[cx] = [];
			for( cy in 0...hei )
				lightMap[cx][cy] = 0;
		}

		// Sources
		for(pt in lightSources) {
			var r = 4;
			if( !pt.active )
				continue;

			for(x in pt.cx-r...pt.cx+r+1)
				for(y in pt.cy-r...pt.cy+r+1) {
					if( !inBounds(x,y) )
						continue;

					var d = Lib.distance(pt.cx, pt.cy, x,y);
					if( d<=6 && sightCheck(pt.cx,pt.cy, x,y) ) {
						var l = 1-d/6;
						lightMap[x][y] = MLib.fmax(lightMap[x][y], l*l);
					}
				}
		}

		// Cold mask
		coldMask.fillRect(coldMask.rect, 0x0 );
		var r = new flash.geom.Rectangle(0,0,Const.GRID,Const.GRID);
		for( cx in 0...wid )
			for( cy in 0...hei ) {
				var l = lightMap[cx][cy];
				if( hasTorch(cx,cy) )
					l = 0.8;
				r.x = cx*Const.GRID;
				r.y = cy*Const.GRID;
				coldMask.fillRect(r, Color.addAlphaF( 0x00FF00, 1-l ));
			}

		coldMask.applyFilter(coldMask, coldMask.rect, pt0, new flash.filters.BlurFilter(64,64,2));
		//var bmp = new Bitmap(coldMask);
		//Game.ME.root.addChild(bmp);
	}


	function renderLights() {
		// Render
		var bd = bg.bitmapData.clone();
		bd.fillRect(bd.rect, 0x0 );
		var dbd = bd.clone();
		var dark = SHADOW;
		var light = 0x729823;
		var r = new flash.geom.Rectangle(0,0,Const.GRID,Const.GRID);
		for( cx in 0...wid )
			for( cy in 0...hei ) {
				var l = lightMap[cx][cy];
				if( hasTorch(cx,cy) )
					l = 0.8;
				r.x = cx*Const.GRID;
				r.y = cy*Const.GRID;
				if( l==0 )
					dbd.fillRect(r, Color.addAlphaF(SHADOW, Lib.rnd(0.6,1)));
				else
					bd.fillRect(r, Color.addAlphaF( Color.interpolateInt(dark,light,l), l ));
			}

		var obd = bd.clone();

		dbd.applyFilter(dbd,dbd.rect,pt0, new flash.filters.BlurFilter(16,16,2));
		//bg.bitmapData.draw(dbd, new flash.geom.ColorTransform(1,1,1, 0.));

		bd.applyFilter(bd,bd.rect,pt0, new flash.filters.BlurFilter(8,8,2));
		bd.applyFilter(bd,bd.rect,pt0, new flash.filters.GlowFilter(dark, 0.7, 16,16,3, 2));
		bg.bitmapData.draw(bd, new flash.geom.ColorTransform(1,1,1, 0.5), BlendMode.ADD);

		obd.applyFilter(obd,obd.rect,pt0, new flash.filters.BlurFilter(16,16));
		obd.colorTransform(obd.rect, new flash.geom.ColorTransform(1,1,1,1, 255,255,255));
		bg.bitmapData.draw(obd, new flash.geom.ColorTransform(1,1,1, 1), BlendMode.OVERLAY);

		darkMask.fillRect(darkMask.rect, 0x0);
		var m = new flash.geom.Matrix();
		m.scale(1/PSCALE, 1/PSCALE);
		darkMask.draw(dbd, m);

		bd.dispose();
		obd.dispose();
		dbd.dispose();
	}

	public function inFog(cx:Int,cy:Int) {
		var x = Std.int((cx+0.5)*Const.GRID)+16;
		var y = Std.int((cy+0.5)*Const.GRID)+16;
		var g = Const.GRID;
		return fow.getPixel32(x, y)>0 &&
			fow.getPixel32(x+g, y)>0 &&
			fow.getPixel32(x-g, y)>0 &&
			fow.getPixel32(x, y+g)>0 &&
			fow.getPixel32(x, y-g)>0;
	}

	function renderBg() {
		var tiles = Game.ME.tiles;
		var bd = bg.bitmapData;
		bd.fillRect(bd.rect, 0x0);

		var torches = [];
		var wbd = bd.clone();
		var gbd = bd.clone();
		var wallFrame = lid>=3 ? 2 : 0;
		for(cx in 0...wid)
			for(cy in 0...hei) {
				var x = cx*Const.GRID;
				var y = cy*Const.GRID;

				var hasWall = hasSpot(cx,cy,"wall");

				if( !hasWall )
					if( lid==0 && (cy>=25 || cx<=10) )
						tiles.drawIntoBitmapRandom(gbd,x,y, "grass", rseed.random);
					else
						tiles.drawIntoBitmapRandom(gbd,x,y, "ground", rseed.random);

				if( hasWall )
					if( !hasSpot(cx,cy+1,"wall") )
						tiles.drawIntoBitmap(wbd,x,y, "wall", wallFrame);
					else
						tiles.drawIntoBitmap(wbd,x,y, "wall", wallFrame+1);

				var t = getTorch(cx,cy);
				if( t!=null ) {
					torches.push(t);
					if( t.cx<t.tx )
						tiles.drawIntoBitmap(wbd, x-16,y+2, "torch", 2 + (t.active?0:1));
					else if( t.cx>t.tx )
						tiles.drawIntoBitmap(wbd, x+16,y+2, "torch", 4 + (t.active?0:1));
					else
						tiles.drawIntoBitmap(wbd, x,y+2, "torch", 0 + (t.active?0:1));
				}
			}

		for( pt in getSpots("tree") )
			tiles.drawIntoBitmap(wbd, pt.cx*Const.GRID,pt.cy*Const.GRID, "bigProps", 0, 0.2,0.6);

		for( pt in getSpots("props") )
			tiles.drawIntoBitmapRandom(wbd, pt.cx*Const.GRID, pt.cy*Const.GRID-rseed.irange(0,5), "props", rseed.random, 0,0);

		for( pt in getSpots("blood") )
			tiles.drawIntoBitmapRandom(gbd, pt.cx*Const.GRID, pt.cy*Const.GRID, "blood", rseed.random, 0,0);

		for( pt in getSpots("exit") )
			tiles.drawIntoBitmap(wbd, pt.cx*Const.GRID, pt.cy*Const.GRID, "stair", 1);

		for( pt in getSpots("entrance") )
			tiles.drawIntoBitmap(wbd, pt.cx*Const.GRID, pt.cy*Const.GRID, "stair", 0);

		for( pt in getSpots("fence") )
			tiles.drawIntoBitmap(wbd, pt.cx*Const.GRID, pt.cy*Const.GRID, "swall", 1);

		for( pt in getSpots("window") )
			tiles.drawIntoBitmap(wbd, pt.cx*Const.GRID, pt.cy*Const.GRID, "swall", 0);

		if( !Game.ME.doneTuto.exists("sister") )
			for( pt in getSpots("sister") )
				tiles.drawIntoBitmap(wbd, pt.cx*Const.GRID, pt.cy*Const.GRID, "icon", 7);



		gbd.applyFilter(gbd, gbd.rect, pt0, new flash.filters.GlowFilter(SHADOW,1, 16,16,1, 2, true));
		gbd.applyFilter(gbd, gbd.rect, pt0, new flash.filters.DropShadowFilter(3,25, SHADOW,0.7, 0,0,1, 2, true));


		// Glows
		var s = tiles.get("halo");
		s.setCenter(0.5,0.5);
		var ct = new flash.geom.ColorTransform();
		ct.alphaMultiplier = 0.3;
		for(t in torches) {
			s.x = (t.cx+0.5)*Const.GRID;
			s.y = (t.cy+0.5)*Const.GRID;
			gbd.draw(s, s.transform.matrix, ct, OVERLAY);
		}
		s.destroy();


		bd.draw(gbd);
		bd.draw(wbd);

		// Cold darkness
		var cold = bd.clone();
		cold.applyFilter(cold, cold.rect, pt0, Color.getColorizeFilter(SHADOW,0.8,0.2));
		cold.copyChannel(coldMask, coldMask.rect, pt0, flash.display.BitmapDataChannel.ALPHA, flash.display.BitmapDataChannel.ALPHA);
		bd.copyPixels(cold, cold.rect, pt0, true);
		cold.dispose();


		wbd.dispose();
		gbd.dispose();
	}


	public function render() {
		rseed.initSeed(0);
		initLight();
		renderBg();
		renderLights();
	}

	public function addLight(cx,cy) {
		var tx = cx;
		var ty = cy;
		if( hasCollision(cx,cy-1) )
			ty--;
		else if( hasCollision(cx-1,cy) )
			tx--;
		else if( hasCollision(cx+1,cy) )
			tx++;
		lightSources.push({cx:cx, cy:cy, tx:tx, ty:ty, active:true});
	}

	public inline function getLight(cx,cy) {
		return inBounds(cx,cy) ? lightMap[cx][cy] : 0;
	}

	function addSpot(id, cx,cy) {
		if( !spots.exists(id) )
			spots.set(id, []);
		spots.get(id).push({ cx:cx, cy:cy });
	}

	public function getSpots(id) {
		if( !spots.exists(id) )
			return [];
		else
			return spots.get(id);
	}

	public function hasSpot(cx,cy,id) {
		for(s in getSpots(id))
			if( s.cx==cx && s.cy==cy )
				return true;
		return false;
	}

	public function sightCheck(x1:Int,y1:Int,x2:Int,y2:Int, ?precise=true) {
		return
			if( precise )
				Bresenham.checkThinLine(x1,y1,x2,y2, function(x,y) {
					return !isBlockingSight(x,y);
				});
			else
				Bresenham.checkFatLine(x1,y1,x2,y2, function(x,y) {
					return !isBlockingSight(x,y);
				});
	}

	public inline function inBounds(cx,cy) {
		return cx>=0 && cx<wid && cy>=0 && cy<hei;
	}

	public inline function hasCollision(cx,cy) {
		return inBounds(cx,cy) ? map[cx][cy].coll : true;
	}

	public inline function isBlockingSight(cx,cy) {
		return inBounds(cx,cy) ? map[cx][cy].blockSight : true;
	}

	public inline function hasTorch(cx,cy) {
		var t = getTorch(cx,cy);
		return t!=null && t.active;
	}
	public inline function getTorch(cx,cy) {
		return lightSources.filter( function(pt) return pt.tx==cx && pt.ty==cy )[0];
	}

	public function getIllumination(cx,cy) {
		var l = getLight(cx,cy);
		return
			if( l>=0.6 ) 2;
			else if( l>=0.2 ) 1;
			else 0;
	}

	public inline function getPath(x1,y1, x2,y2) {
		var p = pf.getPath( {x:x1, y:y1}, {x:x2, y:y2} );
		return p;
		//return pf.smooth(p);
	}


	public function update() {
		var time = Game.ME.time;

		darkPerlin.perlinNoise(8,8,3, 1, false,true,1,true, [
			new flash.geom.Point(time*0.011, time*0.08),
			new flash.geom.Point(time*0.05, -time*0.07),
		]);
		darkPerlin.copyChannel(darkMask, darkMask.rect, pt0, flash.display.BitmapDataChannel.ALPHA, flash.display.BitmapDataChannel.ALPHA);
		darkFog.bitmapData.copyPixels(darkPerlin, darkPerlin.rect, pt0);
		darkFog.alpha = 0.5;
		darkFog.blendMode = MULTIPLY;

		if( time%4== 0 )
			for(pt in lightSources)
				if( pt.active )
					Fx.ME.firefly(pt.cx,pt.cy);
				else {
					Fx.ME.smoke(Const.GRID*(pt.cx + 0.5 + (pt.tx-pt.cx)*0.4), Const.GRID*(pt.cy + 0.5 + (pt.ty-pt.cy)*0.4));
				}
	}
}