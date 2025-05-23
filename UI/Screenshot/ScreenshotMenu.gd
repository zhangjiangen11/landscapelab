extends BoxContainer


var pos_manager: PositionManager
var time_manager: TimeManager

@export var teleport_menu: Control
@export var scenario_menu: Control

#FIXME: use a calendar for timeseries

func _ready():
	$Inputs/ScreenshotButton.pressed.connect(_on_screenshot)
	$Inputs/CheckBoxTimeSeries.toggled.connect(_toggle_time_series)


func _toggle_time_series(toggled: bool):
	$Inputs/TimeSeriesContainer.visible = toggled
	$Labels/TimeSeriesLabels.visible = toggled


func _on_screenshot():
	if not $Inputs/CheckBoxTimeSeries.is_pressed():
		if $Inputs/CheckBoxAllScenarios.is_pressed():
			for scenario in Scenarios.scenarios:
				scenario.activate()
				
				Screencapture.screenshot(
					$Inputs/UpscaleViewport.value,
					teleport_menu.last_teleport_name + "-" + scenario.name
				)
				
				await Screencapture.screenshot_finished
		else:
			Screencapture.screenshot(
					$Inputs/UpscaleViewport.value,
					teleport_menu.last_teleport_name
				)
	else:
		var prev_datetime = time_manager.datetime
		var current_datetime = $Inputs/TimeSeriesContainer/From.value
		var to = $Inputs/TimeSeriesContainer/To.value
		var interval_idx = 0
		var interval = $Inputs/TimeSeriesContainer/Interval/Hours.value
		interval +=  $Inputs/TimeSeriesContainer/Interval/Minutes.value / 60
		
		while to > current_datetime:
			time_manager.set_time(current_datetime, 0)
			await get_tree().process_frame
			Screencapture.screenshot(
				$Inputs/UpscaleViewport.value,
				"-%d" % interval_idx
			)
			await Screencapture.screenshot_finished
			
			current_datetime += interval
			interval_idx += 1
		
		time_manager.set_datetime_by_dict(prev_datetime)
