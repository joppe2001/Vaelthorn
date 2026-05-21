extends Node
## SFX + music playback through pooled AudioStreamPlayers.
##
## SFX share a pool of 8 simultaneous players so we never instantiate
## audio nodes mid-combat. Music has its own dedicated player.

const SFX_POOL_SIZE := 8

var _sfx_players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	add_child(_music_player)
	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx_players.append(p)


func play_sfx(stream: AudioStream) -> void:
	if stream == null:
		return
	for p in _sfx_players:
		if not p.playing:
			p.stream = stream
			p.play()
			return
	# All players busy: silently drop. SFX overflow is acceptable in combat.


func play_music(stream: AudioStream) -> void:
	if stream == null:
		_music_player.stop()
		return
	if _music_player.stream == stream and _music_player.playing:
		return
	_music_player.stream = stream
	_music_player.play()


func stop_music() -> void:
	_music_player.stop()
