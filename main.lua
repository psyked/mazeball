display.setStatusBar(display.HiddenStatusBar)

local physics = require("physics")
physics.setScale(60)
physics.start(true)
physics.setGravity(0, 9.8)
--physics.setDrawMode("hybrid")
system.setAccelerometerInterval(100)

local function onTilt(event)
  physics.setGravity(-10 * event.yGravity, -10 * event.xGravity)
end

Runtime:addEventListener("accelerometer", onTilt)

local TILE_SIZE = 16
local MAZE_WIDTH = (display.contentHeight / TILE_SIZE) / 2
local MAZE_HEIGHT = (display.contentWidth / TILE_SIZE) / 2
local START_COLOR = { 255, 0, 0 }
local FINISH_COLOR = { 0, 255, 0 }
local WALL_COLOR = { 0, 0, 255 }
local WALKABLE_COLOR = { 200, 200, 200 }

-- directions
local NORTH = "N"
local SOUTH = "S"
local EAST = "E"
local WEST = "W"

-- localiables
local _width
local _height
local _maze -- Array
local _moves -- Array
local _start -- Point
local _finish -- Point
local _container -- Sprite
local mainGroup = display.newGroup()

local Point = {}

function Point:clone()
  return self:new(self.x, self.y)
end

function Point:new(x, y)
  local rtn = {}
  setmetatable(rtn, { __index = Point })
  rtn.x = x
  rtn.y = y
  return rtn
end

function switch(t)
  t.case = function(self, x)
	local f = self[x] or self.default
	if f then
	  if type(f) == "function" then
		f(x, self)
	  else
		error("case " .. tostring(x) .. " not a function")
	  end
	end
  end
  return t
end

local function _randInt(min, max)
  return math.floor((math.random() * (max - min + 1)) + min)
end

local function _initMaze()
  _maze = {}
  local x = 0
  while x < _height do
	_maze[x] = {}
	local y = 0
	while y < _width do
	  --	  print("initting _maze[" .. x .. "][" .. y .. "]")
	  _maze[x][y] = true
	  y = y + 1
	end
	x = x + 1
  end
  _maze[_start.x][_start.y] = false
end

local function _createMaze()
  local back
  local move
  local possibleDirections
  local pos = _start:clone() -- Point

  _moves = {}
  _moves[#_moves + 1] = pos.y + (pos.x * _width)
  while #_moves > 0  do
	possibleDirections = ""
	if (pos.x + 2) <= _height then
	  if ((pos.x + 2 < _height) and (_maze[pos.x + 2][pos.y] == true) and (pos.x + 2 ~= false) and (pos.x + 2 ~= _height - 1)) then
		possibleDirections = possibleDirections .. SOUTH
	  end
	end

	if (pos.x - 2) >= 0 then
	  if ((pos.x - 2 >= 0) and (_maze[pos.x - 2][pos.y] == true) and (pos.x - 2 ~= false) and (pos.x - 2 ~= _height - 1)) then
		possibleDirections = possibleDirections .. NORTH
	  end
	end

	if (pos.y - 2) >= 0 then
	  if ((pos.y - 2 >= 0) and (_maze[pos.x][pos.y - 2] == true) and (pos.y - 2 ~= false) and (pos.y - 2 ~= _width - 1)) then
		possibleDirections = possibleDirections .. WEST
	  end
	end

	if (pos.y + 2) <= _width then
	  if ((pos.y + 2 < _width) and (_maze[pos.x][pos.y + 2] == true) and (pos.y + 2 ~= false) and (pos.y + 2 ~= _width - 1)) then
		possibleDirections = possibleDirections .. EAST
	  end
	end

	if #possibleDirections > 0 then
	  move = _randInt(0, (#possibleDirections))

	  local test = switch{
		[NORTH] = function()
		  _maze[pos.x - 2][pos.y] = false
		  _maze[pos.x - 1][pos.y] = false
		  pos.x = pos.x - 2
		end,
		[SOUTH] = function()
		  _maze[pos.x + 2][pos.y] = false
		  _maze[pos.x + 1][pos.y] = false
		  pos.x = pos.x + 2
		end,
		[WEST] = function()
		  _maze[pos.x][pos.y - 2] = false
		  _maze[pos.x][pos.y - 1] = false
		  pos.y = pos.y - 2
		end,
		[EAST] = function()
		  _maze[pos.x][pos.y + 2] = false
		  _maze[pos.x][pos.y + 1] = false
		  pos.y = pos.y + 2
		end
	  }

	  local dirtomove = possibleDirections:sub(move, move)
	  test:case(dirtomove)

	  _moves[#_moves + 1] = (pos.y + (pos.x * _width))

	else

	  back = _moves[#_moves]
	  pos.x = math.floor(back / _width)
	  pos.y = back % _width
	  table.remove(_moves, #_moves)
	end
  end
end

local function _drawTile(color)
  local tile
  if color ~= START_COLOR then
	tile = display.newRect(0, 0, TILE_SIZE, TILE_SIZE)
  else
	tile = display.newCircle(0, 0, TILE_SIZE / 4)
  end
  tile:setFillColor(unpack(color))
  if color == WALL_COLOR then
	physics.addBody(tile, "static")
  end

  return tile
end

local function _drawMaze()
  local tile

  if _container ~= nil then
	mainGroup:remove(_container)
  end

  _container = display.newGroup()
  mainGroup:insert(_container)

  local x = 0
  while x < _height do
	local y = 0
	while y < _height do
	  local tile
	  if (_maze[x][y] == true) then
		tile = _drawTile(WALL_COLOR)
	  else
		tile = _drawTile(WALKABLE_COLOR)
	  end
	  tile.x = x * TILE_SIZE
	  tile.y = y * TILE_SIZE

	  _container:insert(tile)
	  y = y + 1
	end
	x = x + 1
  end

  -- start tile
  tile = _drawTile(START_COLOR)
  tile.x = _start.x * TILE_SIZE
  tile.y = _start.y * TILE_SIZE
  _container:insert(tile)

  physics.addBody(tile, {
	radius = TILE_SIZE / 4,
	density = 2,
	friction = 0,
	bounce = 0,
  })

  -- finish tile
  tile = _drawTile(FINISH_COLOR)
  tile.x = _finish.x * TILE_SIZE
  tile.y = _finish.y * TILE_SIZE
  _container:insert(tile)
end

local function _generate(event)
  _initMaze()
  _createMaze()
  _drawMaze()
end

local main = function()
  Runtime:addEventListener("tap", _generate)

  _width = MAZE_WIDTH * 2 + 1
  _height = MAZE_HEIGHT * 2 + 1

  _start = Point:new(1, 1)
  _finish = Point:new(_height - 2, _width - 2)

  _container = mainGroup

  _generate()
end

main()