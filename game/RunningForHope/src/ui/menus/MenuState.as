package ui.menus
{
	import citrus.core.starling.StarlingCitrusEngine;
	import citrus.core.starling.StarlingState;
	
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.utils.HAlign;
	import starling.text.TextField;
	import citrus.core.CitrusEngine;
	import citrus.input.Input;
	
	public class MenuState extends StarlingState
	{
		private static var _this:MenuState;
		
		public function MenuState()
		{
			_this = this;
			super();
		}
		
		override public function initialize():void {	
			super.initialize();

			openMenu();
		};
		
		public static function openMenu(menu:Sprite = null):void {
			if(menu == null) menu = new MainMenu();
			
			while(_this.numChildren > 0) _this.removeChildAt(0);
			_this.addChild(new Image(Assets.getAtlas("Interface").getTexture("Background")));
			_this.addChild(menu);
		}
		
		public static function setTitle(title:String, title_x:int = 65, title_y:int = 110, align:String = HAlign.LEFT):void
		{
			var titleTextField:TextField = new TextField(780 - title_x, 50, title , "Arial", 25);
			titleTextField.bold = true;
			titleTextField.hAlign = align;
			titleTextField.x = title_x;
			titleTextField.y = title_y;
			titleTextField.color = 0xFFFFFFFF;
			_this.addChild(titleTextField);
		}
	}
}