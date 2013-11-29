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
	import starling.core.Starling;
	import starling.events.ResizeEvent;
	import flash.geom.Rectangle;
	import nape.geom.Vec2;

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
			stage.addEventListener(starling.events.ResizeEvent.RESIZE, onResize);
			onResize(new ResizeEvent("init", Starling.current.nativeStage.stageWidth, Starling.current.nativeStage.stageHeight));
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
		
		/**
		 * Resize the sprite to window
		 */
		private function onResize(event:ResizeEvent):void
		{
			
			var newWidth:Number = event.width;
			var newHeight:Number = event.height;
			this.width = newWidth;
			this.height = newHeight;
	
			if(Config.KEEP_SCALING_RATIO) {
				var aspectRatio:Number = width / height;
				var scale:Number = 1;
				var crop:Vec2 = new Vec2(0, 0);
				if(aspectRatio > Config.ASPECT_RATIO)
				{
					scale = height / Config.VIRTUAL_HEIGHT;
					crop.x = (width - Config.VIRTUAL_WIDTH * scale) / 2;
				}
				else if(aspectRatio < Config.ASPECT_RATIO)
				{
					scale = width / Config.VIRTUAL_WIDTH;
					crop.y = (height - Config.VIRTUAL_HEIGHT*scale) / 2;
				}
				else
				{
					scale = width / Config.VIRTUAL_WIDTH;
				}
				newWidth = Config.VIRTUAL_WIDTH * scale;
				newHeight = Config.VIRTUAL_HEIGHT * scale;
			}
			
			var viewPortRectangle:Rectangle = new Rectangle();
			viewPortRectangle.width = newWidth;
			viewPortRectangle.height = newHeight;
			if(!Config.DEBUG_MODE) viewPortRectangle.x = (width - newWidth) / 2;
			Starling.current.stage.stageWidth = newWidth + (width - newWidth);
			Starling.current.stage.stageHeight = newHeight;
			Starling.current.viewPort = viewPortRectangle;
		
		}
		
	
	}
}