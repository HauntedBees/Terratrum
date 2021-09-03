extends Node
class_name Consts

# Menu Stuff
const LEVEL_OPEN_TIME := 0.25
const LEVEL_CLOSE_TIME := 0.125
const MENU_TOP_HEIGHT := 40.0
const MENULEVEL_HEIGHT := 120.0

# Game Stuff
const BLOCK_SIZE := 64.0
const CAMERA_BOTTOM_OFFSET := BLOCK_SIZE * 7
const CAMERA_LEFT_OFFSET := BLOCK_SIZE * 2 + 12

const CLIMB_DELAY := 0.25
const WALK_SPEED := 300 * BLOCK_SIZE

const ACTION_TIME := 1.0/3.0
const NUM_WIGGLES := 3
const CLIMB_STEP_TIME := ACTION_TIME / 2
const WIGGLE_TIME := 0.5 / (NUM_WIGGLES * 2)
const DEATH_TIME := 1
const DROP_SPEED := 60.0 / ACTION_TIME

# score
const CLEAR_MULTIPLIER := 10
const CHAIN_MULTIPLIER := 30
const AIR_MULTIPLIER := 100
const CLEAR_AREA_BONUS := 500
# time bonus
# extra lives bonus
# undergrounders? probably not - do something with X blocks tho
