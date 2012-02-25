package{
	/*
	Harpoon Class
	
	functions:
	
	megaPoon()
	getX()
	getY()
	*/
	import flash.display.*;
	import flash.text.*;
	import flash.events.*;
	import flash.utils.*;
	import flash.ui.*;
	
	public class Harpoon extends MovieClip{
		private var isMega:Boolean=false;
		private var myAngle:int;
		private var dead:Boolean=false;
		public var myWhales:Array=new Array();
		
		public function Harpoon(mega:Boolean,angle:int){
			isMega=mega;
			if(isMega) gotoAndStop("mega");
			rotation=angle;
			myAngle=angle;
			hitbox.visible=false;
			this.hitArea=hitbox;
		}
		
		public function getAngle(){
			return myAngle;
		}
		
		//returns type of harpoon
		public function megaPoon(){
			return isMega;
		}
		
		//returns X velocity
		public function getX(){
			var xbuf:int=Math.sin(myAngle*(Math.PI/180))*7;//14;
			return xbuf;
		}
		
		//returns Y velocity
		public function getY(){
			var ybuf:int=Math.cos(myAngle*(Math.PI/180))*-7;//14;
			return ybuf;
		}
		
		//add a whale to the harpoon
		public function pushWhale(whale:Whale){
			myWhales.push(whale);
		}
		
		public function getDead(){
			return dead;
		}
		public function killPoon(){
			dead=true;
		}
	}
}