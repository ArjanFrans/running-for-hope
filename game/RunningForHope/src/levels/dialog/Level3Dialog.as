package levels.dialog
{
	import model.dialog.Dialog;
	import model.dialog.DialogLibrary;
	import model.dialog.QuestionResponse;
	import model.dialog.QuestionResponseSet;

	public class Level3Dialog
	{
		private static var loaded:Boolean = false;
		
		public function Level3Dialog()
		{
		}
		
		public static function load():void
		{
			var library:DialogLibrary = Main.getModel().getLevel(2).dialog;
			if (loaded) return;
			
			var chat:Dialog = new Dialog(Assets.getTexture("Characters", "Hope"), "Hope", "Hey [playerName]! How are you?");
			var qrs1:QuestionResponseSet = new QuestionResponseSet();
			qrs1.add(new QuestionResponse("I'm doing great! How about you?", "I'm actually not feeling too well."));
			qrs1.add(new QuestionResponse("I'm fine. You?", "I'm actually not feeling too well."));
			qrs1.add(new QuestionResponse("Stubbed my toe! How about you?", "Haha! I'm actually not feeling too well..."));
			chat.add(qrs1);
			
			var qrs2:QuestionResponseSet = new QuestionResponseSet();
			qrs2.add(new QuestionResponse("Oh? What's wrong with you?", "For a few weeks now I've had a fever, and I'm constantly tired."));
			qrs2.add(new QuestionResponse("Oh come on, what's the matter?", "... I've been having a fever for weeks now, and I never have any energy."));
			qrs2.add(new QuestionResponse("Don't be weak, it's nothing right?", "No, really. I've had a bad fever for weeks now, and I can hardly get out of bed. I'm so tired."));
			chat.add(qrs2);
			
			var qrs3:QuestionResponseSet = new QuestionResponseSet();
			qrs3.add(new QuestionResponse("Maybe you should go to the doctor...", "I guess. Would you come with me?"));
			qrs3.add(new QuestionResponse("That's terrible! Want me to take you to the doctor?", "Thanks [playerName], yeah lets do that."));
			qrs3.add(new QuestionResponse("Wow that sucks! Come on, we need to get you to a doctor.", "That's probably a good idea. Thanks."));
			chat.add(qrs3);
			
			var qrs4:QuestionResponseSet = new QuestionResponseSet();
			qrs4.add(new QuestionResponse("Alright, lets go!", null));
			qrs4.add(new QuestionResponse("Shall we go now?", "Yep! Lets go."));
			qrs4.add(new QuestionResponse("I'll race you there.", "Too funny. Lets go."));
			chat.add(qrs4);
			
			library.put("Level1Start", chat);
			loaded = true;
		}
	}
}