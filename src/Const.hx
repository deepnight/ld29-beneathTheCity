class Const { //}
	public static var WID = Std.int(flash.Lib.current.stage.stageWidth);
	public static var HEI = Std.int(flash.Lib.current.stage.stageHeight);
	public static var UPSCALE = 3;

	private static var uniq = 0;
	public static var DP_BG = uniq++;
	public static var DP_FX_BG = uniq++;
	public static var DP_HERO = uniq++;
	public static var DP_MOBS = uniq++;
	public static var DP_LIGHT = uniq++;
	public static var DP_FX = uniq++;
	public static var DP_FOG = uniq++;
	public static var DP_FX_TOP = uniq++;
	public static var DP_UI = uniq++;

	//public static var OFFSET_X = 50;
	//public static var OFFSET_Y = 100;
	public static var GRID = 16;
	//public static var HEXWID = 24;
	//public static var HEXHEI = Std.int(HEXWID*0.5);
}


enum Action {
	None;
	Pass;
	Walk(cx:Int, cy:Int);
	Patrol;
	Hunt(cx:Int, cy:Int);
	ExploreAround(cx:Int, cy:Int);
}
