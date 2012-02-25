/*
Whale Class

functions:

Whale class takes a Level Object, an initial direction boolean, and a color
stores speed, color, initial direction, level index, alive status, and current direction

getSpeed()
getColor()
isAlive()
killWhale()
getDirection()
reverseDirection()
getMasDir()
getLevel()
*/
package {
	import flash.display.*;
	import flash.text.*;
	import flash.events.*;
	import flash.utils.*;

	public class Whale extends MovieClip {
		
		
		private var asplode:Boolean=false;
		private var mySpeed:Number;
		private var myColor:String;
		
		//true==stage right
		private var masDir:Boolean;
		
		private var myLevel:int;
		private var alive:Boolean=true;

		// if direction is left, false. if right, true.
		private var dir:Boolean=false;

		public function Whale(myLvl:Object,myDir:Boolean,clr:String) {
			mySpeed=2.5;//5;
			myColor=clr;
			this.y=myLvl.y;
			masDir=myDir;
			dir=!myDir;
			myLevel=myLvl.lvl;
			this.gotoAndPlay(clr);
			
			if (!dir) {
				this.x=590;
			} else {
				scaleX*=-1;
				this.x=-40;
			}

			//set the whale's hit box
			hitArea=this.hitbox;
			this.hitbox.visible=false;
		}
		
		//make the whale "rainbow"
		public function setRainbow(){
			myColor="rainbow";
			gotoAndPlay("rainbow");
		}

		//return whale speed
		public function getSpeed() {
			return mySpeed;
		}

		//return whale color
		public function getColor() {
			return myColor;
		}

		//return  true if the whale is alive
		public function isAlive() {
			return alive;
		}

		//KILL THE WHALE!
		public function killWhale() {
			alive=false;
			this.stop();
		}

		//return whale's direction
		public function getDirection() {
			return dir;
		}

		//reverse whale's direction
		public function reverseDirection() {
			dir=! dir;
			scaleX*=-1;
		}
		
		//return masDir
		public function getMasDir(){
			return masDir;
		}
		
		//return level index
		public function getLevel(){
			return myLevel;
		}
		
		public function getAsplode(){
			return asplode;
		}
		public function setAsplode(){
			asplode=true;
		}
	}
}