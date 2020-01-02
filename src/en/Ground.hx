package en;

import flash.display.Sprite;
import mt.deepnight.slb.BSprite;

class Ground extends Entity {
	public function new(x,y, coll) {
		super(x,y);
		xr=yr = 0;

		spr.setCenter(0,0);
		//spr.graphics.clear();
		//spr.graphics.lineStyle(1,0x0,1);
		//spr.graphics.drawRect(0,0,Const.GRID,Const.GRID);
		setDepth(Const.DP_BG);
		if( !coll ) {
			spr.set("ground");
		}
		else {
			spr.set("wall");
		}
	}
}