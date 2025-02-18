package;

import datetime.DateTime;

using api.IdeckiaApi;
using StringTools;

typedef Props = {
	@:editable("prop_sound_path", "ding.mp3", null, PropEditorFieldType.path)
	var sound_path:String;
}

typedef ReminderData = {
	var day:Day;
	var time:Time;
	var playSound:Bool;
	var description:String;
}

@:name("reminder")
@:description("action_description")
@:localize("loc")
class Reminder extends IdeckiaAction {
	static public inline var DAY_FORMAT = '%F';
	static public inline var TIME_FORMAT = '%H:%M';
	static inline var JSON_SPACE = '    ';

	var reminders:Array<ReminderData> = [];
	var soundPath:String;
	var remindersPath:String;
	var timer:haxe.Timer;

	static inline var FILE_NAME = '__reminders.json';

	override public function init(initialState:ItemState):js.lib.Promise<ItemState> {
		remindersPath = haxe.io.Path.join([js.Node.__dirname, FILE_NAME]);
		reminders = api.data.Data.getJson(remindersPath);

		soundPath = if (haxe.io.Path.isAbsolute(props.sound_path)) {
			props.sound_path;
		} else {
			haxe.io.Path.join([js.Node.__dirname, props.sound_path]);
		}

		if (!sys.FileSystem.exists(soundPath)) {
			core.dialog.error(Loc.sound_not_existing_title.tr(), Loc.sound_not_existing_body.tr([soundPath]));
			soundPath = null;
		}

		timer = new haxe.Timer(60 * 1000);
		timer.run = checkReminders;

		return super.init(initialState);
	}

	override public function deinit() {
		timer.stop();
		timer = null;
	}

	function checkReminders() {
		var now = DateTime.local();
		var day, time, reminderDateTime;
		var passedRemindersIndex = [];

		for (i in 0...reminders.length) {
			var r = reminders[i];
			day = r.day;
			time = r.time;
			reminderDateTime = DateTime.make(day.getYear(), day.getMonth(), day.getDay(), time.getHour(), time.getMinute(), now.getSecond());

			if (now >= reminderDateTime) {
				passedRemindersIndex.push(i);
				if (r.playSound && soundPath != null)
					core.mediaPlayer.play(soundPath);
				core.dialog.info('Reminder: $day / $time', r.description);
			}
		}

		for (i in passedRemindersIndex) {
			reminders.splice(i, 1);
		}

		if (passedRemindersIndex.length != 0)
			saveToFile();
	}

	public function execute(currentState:ItemState):js.lib.Promise<ActionOutcome> {
		return new js.lib.Promise((resolve, reject) -> {
			var locale = core.data.getCurrentLocale();
			var dialogPath = haxe.io.Path.join([js.Node.__dirname, 'dialog_$locale.json']);
			if (!sys.FileSystem.exists(dialogPath)) {
				dialogPath = haxe.io.Path.join([js.Node.__dirname, 'dialog_en_uk.json']);
			}
			core.dialog.custom(dialogPath).then(response -> {
				switch response {
					case Some(values):
						var day = '', time = '', playSound = false, description = '';
						for (v in values) {
							if (v.id == 'day')
								day = v.value.trim();
							if (v.id == 'time')
								time = v.value.trim();
							if (v.id == 'play_sound')
								playSound = v.value == 'true';
							if (v.id == 'description')
								description = v.value.trim();
						}

						if (day == '' || time == '' || description == '') {
							core.dialog.error(Loc.empty_fields_title.tr(), Loc.empty_fields_body.tr());
							resolve(new ActionOutcome({state: currentState}));
							return;
						}

						reminders.push({
							day: new Day(day),
							time: new Time(time),
							playSound: playSound,
							description: description
						});
						saveToFile();

						resolve(new ActionOutcome({state: currentState}));
					case None:
				}
			}).catchError(reject);
		});
	}

	function saveToFile() {
		sys.io.File.saveContent(remindersPath, haxe.Json.stringify(reminders, JSON_SPACE));
	}
}

abstract Day(String) {
	public inline function new(s:String)
		this = s;

	public function getYear()
		return toDateTime().getYear();

	public function getMonth()
		return toDateTime().getMonth();

	public function getDay()
		return toDateTime().getDay();

	public function equals(dateTime:DateTime)
		return this == dateTime.format(Reminder.DAY_FORMAT);

	@:to
	public function toDateTime()
		return DateTime.fromString(this);
}

abstract Time(String) {
	public inline function new(s:String)
		this = s;

	function splitHourMinute() {
		if (this == null)
			return [0, 0];
		return this.split(':').map(c -> (c == '') ? 0 : Std.parseInt(c));
	}

	public function getHour()
		return splitHourMinute()[0];

	public function getMinute()
		return splitHourMinute()[1];

	public function getTotalSeconds()
		return toDateTime().getTime();

	@:to
	public function toDateTime() {
		var sp = splitHourMinute();
		var zero = new DateTime(0);
		return zero.add(Hour(sp[0])).add(Minute(sp[1]));
	}
}
