package;

import flixel.graphics.FlxGraphic;
import flixel.input.gamepad.FlxGamepad;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.net.curl.CURLCode;
#if FEATURE_DISCORD
import Discord.DiscordClient;
#end

using StringTools;

class StoryMenuState extends MusicBeatState
{
	var scoreText:FlxText;

	public static function weekData():Array<Dynamic>
	{
		return [
			['tutorial'],
			['bopeebo', 'fresh', 'dadbattle'],
			['spookeez', 'south', "monster"],
			['pico', 'philly', "blammed"],
			['satin-panties', "high", "milf"],
			['cocoa', 'eggnog', 'winter-horrorland'],
			['senpai', 'roses', 'thorns'],
			['ugh', 'guns', 'stress']
		];
	}

	var curDifficulty:Int = 1;

	public static var weekUnlocked:Array<Bool> = [];

	var weekCharacters:Array<Dynamic> = [
		['', 'bf', 'gf'],
		['dad', 'bf', 'gf'],
		['spooky', 'bf', 'gf'],
		['pico', 'bf', 'gf'],
		['mom', 'bf', 'gf'],
		['parents-christmas', 'bf', 'gf'],
		['senpai', 'bf', 'gf'],
		['tankman', 'bf', 'gf']
	];

	var weekDiffs:Array<Dynamic> = [
		['easy', 'normal', 'hard'],
		['easy', 'normal', 'hard'],
		['easy', 'normal', 'hard'],
		['easy', 'normal', 'hard'],
		['easy', 'normal', 'hard'],
		['easy', 'normal', 'hard'],
		['easy', 'normal', 'hard']
	];

	var weekNames:Array<String> = CoolUtil.coolTextFile(Paths.txt('data/weekNames'));

	var diffList:Array<String> = [];

	var txtWeekTitle:FlxText;

	var curWeek:Int = 0;

	var currentWeek:Int = 0;

	var txtTracklist:FlxText;

	var availableDiffs:String = '';

	var grpWeekText:FlxTypedGroup<MenuItem>;
	var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;

	var grpLocks:FlxTypedGroup<FlxSprite>;

	var difficultySelectors:FlxGroup;
	var sprDifficulty:FlxSprite;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;
	var diffsThatExists:Array<String>;

	function unlockWeeks():Array<Bool>
	{
		var weeks:Array<Bool> = [];
		#if debug
		for (i in 0...weekNames.length)
			weeks.push(true);
		return weeks;
		#end

		weeks.push(true);

		for (i in 0...FlxG.save.data.weekUnlocked)
			weeks.push(true);

		return weeks;
	}

	function cleanDifficulties()
	{
		diffsThatExists = [];
		diffList = CoolUtil.coolTextFile(Paths.txt('data/weeksDifficulties'));

		try
		{
			var splitDiffs:Array<String> = diffList[curWeek].split(':');

			// WTF Epic YandereDev moment 😭

			if (splitDiffs[0].contains('easy'))
				diffsThatExists.push('easy');
			else if (splitDiffs[0].contains('normal'))
				diffsThatExists.push('normal');
			else if (splitDiffs[0].contains('hard'))
				diffsThatExists.push('hard');

			if (splitDiffs[1].contains('easy'))
				diffsThatExists.push('easy');
			else if (splitDiffs[1].contains('normal'))
				diffsThatExists.push('normal');
			else if (splitDiffs[1].contains('hard'))
				diffsThatExists.push('hard');

			if (splitDiffs[2].contains('easy'))
				diffsThatExists.push('easy');
			else if (splitDiffs[2].contains('normal'))
				diffsThatExists.push('normal');
			else if (splitDiffs[2].contains('hard'))
				diffsThatExists.push('hard');
		}
		catch (e)
		{
			Debug.logWarn(e);
		}

		if (diffsThatExists.length == 0)
			diffsThatExists = ["easy", "normal", "hard"];
	}

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		weekUnlocked = unlockWeeks();

		PlayState.currentSong = "bruh";
		PlayState.inDaPlay = false;
		#if FEATURE_DISCORD
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Story Mode Menu", null);
		#end

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		if (FlxG.sound.music != null)
		{
			if (!FlxG.sound.music.playing)
			{
				FlxG.sound.playMusic(Paths.music(FlxG.save.data.watermark ? "ke_freakyMenu" : "freakyMenu"));
				Conductor.changeBPM(102);
			}
		}

		persistentUpdate = persistentDraw = true;

		scoreText = new FlxText(10, 10, 0, "SCORE: 49324858", 36);
		scoreText.setFormat("VCR OSD Mono", 32);

		txtWeekTitle = new FlxText(FlxG.width * 0.7, 10, 0, "", 32);
		txtWeekTitle.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, RIGHT);
		txtWeekTitle.alpha = 0.7;

		var rankText:FlxText = new FlxText(0, 10);
		rankText.text = 'RANK: GREAT';
		rankText.setFormat(Paths.font("vcr.ttf"), 32);
		rankText.size = scoreText.size;
		rankText.screenCenter(X);

		var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');
		var yellowBG:FlxSprite = new FlxSprite(0, 56).makeGraphic(FlxG.width, 400, 0xFFF9CF51);

		grpWeekText = new FlxTypedGroup<MenuItem>();
		add(grpWeekText);

		grpLocks = new FlxTypedGroup<FlxSprite>();
		add(grpLocks);

		var blackBarThingie:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 56, FlxColor.BLACK);
		add(blackBarThingie);

		grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();

		trace("Line 70");

		for (i in 0...weekData().length)
		{
			var weekThing:MenuItem = new MenuItem(0, yellowBG.y + yellowBG.height + 10, i);
			weekThing.y += ((weekThing.height + 20) * i);
			weekThing.targetY = i;
			grpWeekText.add(weekThing);

			weekThing.screenCenter(X);
			weekThing.antialiasing = FlxG.save.data.antialiasing;
			// weekThing.updateHitbox();

			// Needs an offset thingie
			if (!weekUnlocked[i])
			{
				trace('locking week ' + i);
				var lock:FlxSprite = new FlxSprite(weekThing.width + 10 + weekThing.x);
				lock.frames = ui_tex;
				lock.animation.addByPrefix('lock', 'lock');
				lock.animation.play('lock');
				lock.ID = i;
				lock.antialiasing = FlxG.save.data.antialiasing;
				grpLocks.add(lock);
			}
		}

		trace("Line 96");

		grpWeekCharacters.add(new MenuCharacter(0, 100, 0.5, false));
		grpWeekCharacters.add(new MenuCharacter(450, 25, 0.9, true));
		grpWeekCharacters.add(new MenuCharacter(850, 100, 0.5, true));

		difficultySelectors = new FlxGroup();
		add(difficultySelectors);

		trace("Line 124");

		leftArrow = new FlxSprite(grpWeekText.members[0].x + grpWeekText.members[0].width + 10, grpWeekText.members[0].y + 10);
		leftArrow.frames = ui_tex;
		leftArrow.animation.addByPrefix('idle', "arrow left");
		leftArrow.animation.addByPrefix('press', "arrow push left");
		leftArrow.animation.play('idle');
		leftArrow.antialiasing = FlxG.save.data.antialiasing;
		difficultySelectors.add(leftArrow);

		sprDifficulty = new FlxSprite(0, leftArrow.y);
		sprDifficulty.antialiasing = FlxG.save.data.antialiasing;
		cleanDifficulties();
		changeDifficulty();

		difficultySelectors.add(sprDifficulty);

		rightArrow = new FlxSprite(leftArrow.x + sprDifficulty.width + 68, leftArrow.y);
		rightArrow.frames = ui_tex;
		rightArrow.animation.addByPrefix('idle', 'arrow right');
		rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
		rightArrow.animation.play('idle');
		rightArrow.antialiasing = FlxG.save.data.antialiasing;
		difficultySelectors.add(rightArrow);

		trace("Line 150");

		add(yellowBG);
		add(grpWeekCharacters);

		txtTracklist = new FlxText(FlxG.width * 0.05, yellowBG.x + yellowBG.height + 100, 0, "Tracks", 32);
		txtTracklist.alignment = CENTER;
		txtTracklist.font = rankText.font;
		txtTracklist.color = 0xFFe55777;
		add(txtTracklist);
		// add(rankText);
		add(scoreText);
		add(txtWeekTitle);

		updateText();

		var bullShit:Int = 0;

		for (item in grpWeekText.members)
		{
			item.targetY = bullShit - curWeek;
			if (item.targetY == Std.int(0) && weekUnlocked[curWeek])
				item.alpha = 1;
			else
				item.alpha = 0.6;
			bullShit++;
		}

		PlayStateChangeables.modchart = true;
		PlayStateChangeables.botPlay = false;
		PlayStateChangeables.opponentMode = false;
		PlayStateChangeables.mirrorMode = false;
		PlayStateChangeables.holds = true;
		PlayStateChangeables.healthDrain = false;
		PlayStateChangeables.healthGain = 1;
		PlayStateChangeables.healthLoss = 1;
		PlayStateChangeables.practiceMode = false;
		PlayStateChangeables.skillIssue = false;

		trace("Line 165");

		super.create();
	}

	override function update(elapsed:Float)
	{
		// scoreText.setFormat('VCR OSD Mono', 32);
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.5));

		scoreText.text = "WEEK SCORE:" + lerpScore;

		txtWeekTitle.text = weekNames[curWeek].toUpperCase();

		txtWeekTitle.x = FlxG.width - (txtWeekTitle.width + 10);

		// FlxG.watch.addQuick('font', scoreText.font);

		difficultySelectors.visible = weekUnlocked[curWeek];

		grpLocks.forEach(function(lock:FlxSprite)
		{
			lock.y = grpWeekText.members[lock.ID].y;
		});

		if (!movedBack)
		{
			if (!selectedWeek)
			{
				var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

				if (gamepad != null)
				{
					if (gamepad.justPressed.DPAD_UP)
					{
						changeWeek(-1);
					}
					if (gamepad.justPressed.DPAD_DOWN)
					{
						changeWeek(1);
					}

					if (gamepad.pressed.DPAD_RIGHT)
						rightArrow.animation.play('press')
					else
						rightArrow.animation.play('idle');
					if (gamepad.pressed.DPAD_LEFT)
						leftArrow.animation.play('press');
					else
						leftArrow.animation.play('idle');

					if (gamepad.justPressed.DPAD_RIGHT)
					{
						changeDifficulty(1);
					}
					if (gamepad.justPressed.DPAD_LEFT)
					{
						changeDifficulty(-1);
					}
				}

				#if !mobile
				if (FlxG.mouse.wheel != 0)
				{
					#if desktop
					changeWeek(-FlxG.mouse.wheel);
					#else
					if (FlxG.mouse.wheel < 0) // HTML5 BRAIN'T
						changeWeek(1);
					else if (FlxG.mouse.wheel > 0)
						changeWeek(-1);
					#end
				}
				#end

				if (FlxG.keys.justPressed.UP)
				{
					changeWeek(-1);
				}

				if (FlxG.keys.justPressed.DOWN)
				{
					changeWeek(1);
				}

				var mouseRight = (FlxG.mouse.overlaps(rightArrow, FlxG.camera) && FlxG.mouse.justPressed);
				var mouseLeft = (FlxG.mouse.overlaps(leftArrow, FlxG.camera) && FlxG.mouse.justPressed);

				if (controls.RIGHT || mouseRight)
					rightArrow.animation.play('press')
				else
					rightArrow.animation.play('idle');

				if (controls.LEFT || mouseLeft)
					leftArrow.animation.play('press');
				else
					leftArrow.animation.play('idle');

				if (controls.RIGHT_P || mouseRight)
					changeDifficulty(1);
				if (controls.LEFT_P || mouseLeft)
					changeDifficulty(-1);
			}

			var weekClicked = (FlxG.mouse.overlaps(grpWeekText.members[curWeek]) && FlxG.mouse.pressed && !stopspamming);
			if ((controls.ACCEPT && !FlxG.keys.pressed.ALT) || weekClicked)
			{
				selectWeek();
			}
		}

		if (controls.BACK && !movedBack && !selectedWeek)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			movedBack = true;
			MusicBeatState.switchState(new MainMenuState());
			clean();
		}

		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		super.update(elapsed);
	}

	var movedBack:Bool = false;
	var selectedWeek:Bool = false;
	var stopspamming:Bool = false;

	function selectWeek()
	{
		if (weekUnlocked[curWeek])
		{
			if (stopspamming == false)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));

				grpWeekText.members[curWeek].startFlashing();
				grpWeekCharacters.members[1].animation.play('bfConfirm');
				stopspamming = true;
			}

			PlayState.storyPlaylist = weekData()[curWeek];
			PlayState.isStoryMode = true;
			selectedWeek = true;
			PlayState.songMultiplier = 1;

			PlayState.isSM = false;

			PlayState.storyDifficulty = curDifficulty;

			var diff:String = '-${diffsThatExists[PlayState.storyDifficulty]}';
			if (diff == '-normal')
				diff = '';
			PlayState.sicks = 0;
			PlayState.bads = 0;
			PlayState.shits = 0;
			PlayState.goods = 0;
			PlayState.campaignMisses = 0;
			PlayState.SONG = Song.conversionChecks(Song.loadFromJson(PlayState.storyPlaylist[0], diff));
			PlayState.storyWeek = curWeek;
			PlayState.campaignScore = 0;
			PlayState.campaignAccuracy = 0;
			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				#if !FEATURE_MP4VIDEOS
				if (FlxG.save.data.optimize || !FlxG.save.data.background)
				{
					switch (curWeek)
					{
						case 7:
							LoadingState.loadAndSwitchState(new VideoState('cutscenes/ugh_cutscene', new PlayState()), true);

						default:
							LoadingState.loadAndSwitchState(new PlayState(), true);
					}
				}
				else
				{
					LoadingState.loadAndSwitchState(new PlayState(), true);
				}
				#else
				LoadingState.loadAndSwitchState(new PlayState(), true);
				#end
			});
		}
	}

	var tweenDifficulty:FlxTween;

	function changeDifficulty(change:Int = 0):Void
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = diffsThatExists.length - 1;
		if (curDifficulty > diffsThatExists.length - 1)
			curDifficulty = 0;

		var newImage:FlxGraphic = Paths.image('menuDifficulties/${diffsThatExists[curDifficulty]}');

		if (sprDifficulty.graphic != newImage)
		{
			sprDifficulty.loadGraphic(newImage);
			sprDifficulty.x = leftArrow.x + 60;
			sprDifficulty.x += (308 - sprDifficulty.width) / 3;
			sprDifficulty.alpha = 0;
			sprDifficulty.y = leftArrow.y - 15;

			if (tweenDifficulty != null)
				tweenDifficulty.cancel();
			tweenDifficulty = FlxTween.tween(sprDifficulty, {y: leftArrow.y + 15, alpha: 1}, 0.07, {
				onComplete: function(twn:FlxTween)
				{
					tweenDifficulty = null;
				}
			});
		}

		sprDifficulty.alpha = 0;

		// USING THESE WEIRD VALUES SO THAT IT DOESNT FLOAT UP
		sprDifficulty.y = leftArrow.y - 15;
		intendedScore = Highscore.getWeekScore(curWeek, curDifficulty);

		#if !switch
		intendedScore = Highscore.getWeekScore(curWeek, curDifficulty);
		#end

		FlxTween.tween(sprDifficulty, {y: leftArrow.y + 15, alpha: 1}, 0.07);
	}

	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	function changeWeek(change:Int = 0):Void
	{
		curWeek += change;

		cleanDifficulties();
		changeDifficulty();

		if (curWeek >= weekData().length)
			curWeek = 0;
		if (curWeek < 0)
			curWeek = weekData().length - 1;

		var bullShit:Int = 0;

		for (item in grpWeekText.members)
		{
			item.targetY = bullShit - curWeek;
			if (item.targetY == Std.int(0) && weekUnlocked[curWeek])
				item.alpha = 1;
			else
				item.alpha = 0.6;
			bullShit++;
		}

		FlxG.sound.play(Paths.sound('scrollMenu'));

		updateText();
	}

	function updateText()
	{
		grpWeekCharacters.members[0].setCharacter(weekCharacters[curWeek][0]);
		grpWeekCharacters.members[1].setCharacter(weekCharacters[curWeek][1]);
		grpWeekCharacters.members[2].setCharacter(weekCharacters[curWeek][2]);

		txtTracklist.text = "Tracks\n";
		var stringThing:Array<String> = weekData()[curWeek];

		for (i in stringThing)
			txtTracklist.text += "\n" + i;

		txtTracklist.text = txtTracklist.text.toUpperCase();

		txtTracklist.screenCenter(X);
		txtTracklist.x -= FlxG.width * 0.35;

		txtTracklist.text += "\n";

		#if !switch
		intendedScore = Highscore.getWeekScore(curWeek, curDifficulty);
		#end
	}

	public static function unlockNextWeek(week:Int):Void
	{
		if (week <= weekData().length - 1 /*&& FlxG.save.data.weekUnlocked == week*/) // fuck you, unlocks all weeks
		{
			weekUnlocked.push(true);
			trace('Week ' + week + ' beat (Week ' + (week + 1) + ' unlocked)');
		}

		FlxG.save.data.weekUnlocked = weekUnlocked.length - 1;
		FlxG.save.flush();
	}

	override function beatHit()
	{
		super.beatHit();

		if (curBeat % 2 == 0)
		{
			grpWeekCharacters.members[0].bopHead();
			grpWeekCharacters.members[1].bopHead();
		}
		else if (weekCharacters[curWeek][0] == 'spooky' || weekCharacters[curWeek][0] == 'gf')
			grpWeekCharacters.members[0].bopHead();

		if (weekCharacters[curWeek][2] == 'spooky' || weekCharacters[curWeek][2] == 'gf')
			grpWeekCharacters.members[2].bopHead();
	}
}
