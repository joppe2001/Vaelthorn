class_name Palette extends RefCounted
## Master palette for Vaelthorn (Endesga-64 inspired).
##
## Lock to these colors. When adding UI / VFX / sprite tints, reference
## constants from here — never hand-pick hex values in scenes or code.
## When importing third-party sprites that don't fit, remap them in
## Aseprite to the closest match here.
##
## Why a palette discipline matters: see docs/06-art.md.

# ─── Backgrounds ─────────────────────────────────────────────────────
const BG_VOID := Color("#07070c")    ## true background, far below everything
const BG_DEEP := Color("#0e0e15")    ## main scene background
const BG_MID := Color("#13131c")     ## slightly lifted (mid-band)
const BG_GROUND := Color("#1a1a25")  ## ground / floor band
const BG_PANEL := Color("#1d1d2c")   ## panel surfaces

# ─── Text & UI chrome ────────────────────────────────────────────────
const TEXT_PRIMARY := Color("#f4f4f4")
const TEXT_MUTED := Color("#94b0c2")
const TEXT_DIM := Color("#566c86")

const BORDER := Color("#3a3a55")
const BORDER_BRIGHT := Color("#566c86")

# ─── Accents ─────────────────────────────────────────────────────────
const ACCENT_GOLD := Color("#f9c74f")
const ACCENT_GOLD_DEEP := Color("#c98b1d")
const ACCENT_CYAN := Color("#42caff")
const SUCCESS := Color("#a7f070")
const DANGER := Color("#cb414b")
const WARN := Color("#ef9a3a")

# ─── Damage popup colors ─────────────────────────────────────────────
const POPUP_NORMAL := Color("#ffffff")
const POPUP_CRIT := Color("#fed442")
const POPUP_LUCKY := Color("#8df0c0")
const POPUP_HEAL := Color("#88c070")
const POPUP_MISS := Color("#a0a0b0")

# ─── Element colors (used for tints, popups, banner accents) ─────────
const ELEM_FIRE := Color("#ef7d57")
const ELEM_WATER := Color("#41a6f6")
const ELEM_EARTH := Color("#a7c66a")
const ELEM_WIND := Color("#e0e8f0")
const ELEM_LIGHT := Color("#fed442")
const ELEM_DARK := Color("#7a4cb9")

# ─── HP bar styling ──────────────────────────────────────────────────
const HP_FILL := Color("#cb414b")    ## red fill
const HP_FILL_LOW := Color("#7a1f25") ## desaturated when below 25%
const HP_BG := Color("#1d1d2c")
const HP_BORDER := Color("#566c86")


static func element_color(element_index: int) -> Color:
	match element_index:
		0: return ELEM_FIRE
		1: return ELEM_WATER
		2: return ELEM_EARTH
		3: return ELEM_WIND
		4: return ELEM_LIGHT
		5: return ELEM_DARK
		_: return TEXT_MUTED
