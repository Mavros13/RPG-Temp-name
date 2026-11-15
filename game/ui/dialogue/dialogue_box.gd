class_name DialogueBox
extends CanvasLayer
## Bottom-screen dialogue box: a speaker name, one line of body text, and Continue.
##
## Instance [code]res://game/ui/dialogue/dialogue_box.tscn[/code] under any node.
## The sample line is the default, so the box is readable before a caller sets text.
## Continue hides the box, then emits [signal continued]. A listener can call
## [method show_line] from that signal to show the next line.

signal continued

const SAMPLE_SPEAKER := "Archivist"
const SAMPLE_LINE := "Hold still. The forge is listening for your name."

@export var speaker_name: String = SAMPLE_SPEAKER
@export_multiline var body_text: String = SAMPLE_LINE

@onready var _speaker_label: Label = %SpeakerLabel
@onready var _body_label: Label = %BodyLabel
@onready var _continue_button: Button = %ContinueButton


func _ready() -> void:
	_continue_button.pressed.connect(_on_continue_pressed)
	show_line(speaker_name, body_text)


func show_line(speaker: String, text: String) -> void:
	speaker_name = speaker
	body_text = text
	_speaker_label.text = speaker
	_body_label.text = text
	show()
	_continue_button.grab_focus()


func _on_continue_pressed() -> void:
	hide()
	continued.emit()
