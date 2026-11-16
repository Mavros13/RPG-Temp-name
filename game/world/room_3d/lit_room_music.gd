extends AudioStreamPlayer

## Quiet loop that exists only on the lit room. Pause holds it silent.

const LOOP := preload("res://game/audio/lit_room_loop.wav")

var _held := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	volume_db = -18.0
	var wav := LOOP.duplicate() as AudioStreamWAV
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	var frames := int(round(wav.mix_rate * wav.get_length()))
	if frames > 0:
		wav.loop_end = frames
	stream = wav
	play()


func _process(_delta: float) -> void:
	if get_tree().paused:
		if not _held:
			stream_paused = true
			_held = true
		return
	if not _held:
		return
	_held = false
	stream_paused = false
	if not playing:
		play()
