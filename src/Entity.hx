import flash.display.Sprite;
import mt.deepnight.slb.BSprite;
import mt.deepnight.Lib;
import mt.MLib;
import Const;

class Entity {
	public static var ALL : Array<Entity> = [];
	static var UNIQ = 0;

	var game					: Game;
	public var uid				: Int;
	public var spr				: BSprite;
	public var shadow			: BSprite;
	public var destroyAsked		: Bool;
	public var cd				: mt.Cooldown;

	public var cx				: Int;
	public var cy				: Int;
	public var xr				: Float;
	public var yr				: Float;
	public var xx				: Float;
	public var yy				: Float;

	public var dx				: Float;
	public var dy				: Float;
	public var frict			: Float;
	public var speed			: Float;
	public var dir				: Int;

	//var path					: Array<{x:Int, y:Int}>;
	public var nextCell				: Null<{cx:Int, cy:Int}>;

	public function new(x,y) {
		uid = UNIQ++;
		game = Game.ME;
		destroyAsked = false;
		ALL.push(this);
		cd = new mt.Cooldown();
		cx = cy = 0;
		xr = yr = 0.5;
		dx = dy = 0;
		frict = 0.4;
		speed = 0.12;
		dir = 0;
		//path = [];

		spr = new BSprite(Game.ME.tiles);
		setDepth(Const.DP_MOBS);

		shadow = game.tiles.get("icon", 4);
		game.sdm.add(shadow, Const.DP_BG);
		shadow.setCenter(0.5,0.5);
		shadow.alpha = 0.2;

		setPos(x,y);
	}

	public function setDir(d) {
		dir = d;
	}

	public function lookAt(e:Entity) {
		if( e.cx<cx ) setDir(3);
		else if( e.cx>cx ) setDir(1);
		else if( e.cy<cy ) setDir(0);
		else if( e.cy>cy ) setDir(2);
	}

	public function setAutoDir() {
		if( nextCell!=null ) {
			if( nextCell.cx<cx ) setDir(3);
			if( nextCell.cx>cx ) setDir(1);
			if( nextCell.cy<cy ) setDir(0);
			if( nextCell.cy>cy ) setDir(2);
		}
	}

	function setDepth(d:Int) {
		Game.ME.sdm.add(spr, d);
	}

	inline function coordToId(cx,cy) {
		return cx + cy*Game.ME.level.wid;
	}

	public function toString() {
		return "Ent@"+cx+","+cy;
	}

	public static function getAt(cx,cy) {
		return ALL.filter( function(e) return e.cx==cx && e.cy==cy );
	}

	public static function runAt(cx,cy, f:Entity->Void) {
		for(e in getAt(cx,cy))
			f(e);
	}

	public function sightCheck(x,y) {
		return Game.ME.level.sightCheck(cx,cy, x,y);
	}

	public function setPos(x,y, ?xr=0.5, ?yr=0.5) {
		cx = x;
		cy = y;
		this.xr = xr;
		this.yr = yr;
		updateSprite();
	}

	public function getPath(x,y) {
		var path = Game.ME.level.getPath(cx,cy, x,y);
		if( path.length>1 && path[0].x==cx && path[0].y==cy )
			path.shift();
		return path;
	}

	public inline function headTo(x,y) {
		var pt = getPath(x,y)[0];
		if( pt==null )
			nextCell = null;
		else
			nextCell = {cx:pt.x, cy:pt.y}
	}

	public function canReach(x,y) {
		return Game.ME.level.getPath(cx,cy, x,y).length>0;
	}

	public function stop() {
		nextCell = null;
		//dx*=0.5;
		//dy*=0.5;
	}

	public function getDirAng() {
		return switch( dir ) {
			case 0 : -MLib.PI/2;
			case 1 : 0;
			case 2 : MLib.PI/2;
			case 3 : MLib.PI;
			default : 0;
		}
	}

	//public function isoToScreen() {
		//return _isoToScreen(cx,cy,xr,yr);
	//}
//
	//public static function _isoToScreen(cx:Int,cy:Int, ?xr=0.5, yr=0.5) {
		//return {
			//x	: Const.OFFSET_X + Const.HEXWID * ((cy+yr) + (cx+xr))/2,
			//y	: Const.OFFSET_Y + Const.HEXHEI * ((cy+yr) - (cx+xr))/2,
		//}
	//}
//
	//public static function _screenToIso(x:Float,y:Float) {
		//x = (x - Const.OFFSET_X)*2/Const.HEXWID;
		//y = (y - Const.OFFSET_Y)*2/Const.HEXHEI;
		//var ix = (x-y)/2;
		//var iy = (x+y)/2;
		//return {
			//cx	: Std.int(ix),
			//cy	: Std.int(iy),
			//xr	: ix-Std.int(ix),
			//yr	: iy-Std.int(iy),
		//}
	//}

	public function updateSprite() {
		//var pt = isoToScreen();
		xx = (cx+xr)*Const.GRID;
		yy = (cy+yr)*Const.GRID;
		spr.x = Std.int(xx);
		spr.y = Std.int(yy);
		shadow.x = spr.x;
		shadow.y = spr.y+6;
	}

	public function askDestroy() {
		destroyAsked = true;
	}

	public function unregister() {
		spr.destroy();
		ALL.remove(this);
	}

	public function getSpeed() {
		return speed;
	}

	function getCellCenter() {
		return { xr:0.5, yr:0.5 }
	}

	public inline function isDelayed() {
		return cd.has("delay");
	}


	public function update() {
		xr+=dx;
		while( xr>1 ) {
			xr--;
			cx++;
		}
		while( xr<0 ) {
			xr++;
			cx--;
		}
		dx*=frict;
		if( MLib.fabs(dx)<0.005 ) dx = 0;

		yr+=dy;
		while( yr>1 ) {
			yr--;
			cy++;
		}
		while( yr<0 ) {
			yr++;
			cy--;
		}
		dy*=frict;
		if( MLib.fabs(dy)<0.005 ) dy = 0;


		cd.update();
	}
}

