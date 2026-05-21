extends Node
## Lightweight local telemetry: FPS sampling, error counters.
##
## Phase 9+ will add opt-in remote reporting (Sentry / self-hosted GlitchTip).
## For now, this is local-only and prints to console.

const SAMPLE_WINDOW := 120 ## ~2 seconds at 60fps

var _frame_samples: Array[float] = []
var error_count: int = 0


func _process(_delta: float) -> void:
	_frame_samples.append(Engine.get_frames_per_second())
	if _frame_samples.size() > SAMPLE_WINDOW:
		_frame_samples.pop_front()


func avg_fps() -> float:
	if _frame_samples.is_empty():
		return 0.0
	var sum := 0.0
	for s in _frame_samples:
		sum += s
	return sum / _frame_samples.size()


func min_fps() -> float:
	if _frame_samples.is_empty():
		return 0.0
	var m: float = _frame_samples[0]
	for s in _frame_samples:
		if s < m:
			m = s
	return m


func report_error(context: String) -> void:
	error_count += 1
	push_error("[Telemetry] error in %s (total=%d)" % [context, error_count])
