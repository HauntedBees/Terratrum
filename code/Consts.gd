extends Node
class_name Consts

# Menu Stuff
const LEVEL_OPEN_TIME := 0.25
const LEVEL_CLOSE_TIME := 0.125
const MENU_TOP_HEIGHT := 80.0
const MENULEVEL_HEIGHT := 120.0

# Game Stuff
const BLOCK_SIZE := 64.0
const FALL_TIME := 3.0
const ACTION_TIME := 1.0 / FALL_TIME
const POP_TIME := 0.25
const PLAYER_POP_TIME := 0.3
const POP_HOLD_TIME := POP_TIME * 0.75
const WIGGLE_TIME := ACTION_TIME * 2
const WALK_SPEED := 300 * BLOCK_SIZE
const TIME_TO_TRIGGER_CLIMB := ACTION_TIME / 2.0
const CLIMB_STEP_TIME := 2.0 / ACTION_TIME
# will probably be used
const DEATH_TIME := 1.0

const PREFALL_WAIT_TIME := 1.0#0.25
const AIR_DECREASE_RATE := 1.0 # higher = air depletes faster

# score
const CLEAR_MULTIPLIER := 10
const CHAIN_MULTIPLIER := 30
const AIR_MULTIPLIER := 100
const CLEAR_AREA_BONUS := 500
# time bonus
# extra lives bonus
# undergrounders? probably not - do something with X blocks tho

# useless
const CAMERA_BOTTOM_OFFSET := BLOCK_SIZE * 7
const CAMERA_LEFT_OFFSET := BLOCK_SIZE * 2 + 12
const NUM_WIGGLES := 3
const FLICKER_PART_TIME := ACTION_TIME / 6.0
const DROP_SPEED := 60.0 / ACTION_TIME # this is probably useless
const CLIMB_DELAY := 0.25
