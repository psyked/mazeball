module(..., package.seeall)
PerformanceOutput = {};
PerformanceOutput.mt = {};
PerformanceOutput.mt.__index = PerformanceOutput;

local prevTime = 0;
local maxSavedFps = 30;
local incrementalUpdateRate = 5;

local function createLayout(self)
  local memoryMonitorGroup = display.newGroup()
  local bgRect = display.newRect(display.screenOriginX + 1, display.contentHeight - display.screenOriginY - 51, 100, 50)
  bgRect:setFillColor(0, 0, 0, 204)
  memoryMonitorGroup:insert(bgRect)

  local oy = display.contentHeight - display.screenOriginY - 49;
  local ox = display.screenOriginX + 5;

  local font = "Courier"
  if system.getInfo("environment") == "simulator" then
	font = native.systemFont
  end

  self.memoryLabel = display.newText(memoryMonitorGroup, "M: initalising", ox, oy +2, font, 11)
  self.memoryLabel:setTextColor(255, 128, 0)
  memoryMonitorGroup:insert(self.memoryLabel)

  self.textureLabel = display.newText(memoryMonitorGroup, "T: initalising", ox, oy + 17, font, 11)
  self.textureLabel:setTextColor(128, 255, 0)
  memoryMonitorGroup:insert(self.textureLabel)

  self.framerate = display.newText("F: 0 [0/0]", ox, oy + 32, font, 11);
  self.framerate:setTextColor(0, 128, 255)
  memoryMonitorGroup:insert(self.framerate);

  return memoryMonitorGroup;
end

local function minElement(table)
  local min = 10000;
  for i = 1, #table do
	if (table[i] < min) then min = table[i]; end
  end
  return min;
end

local function maxElement(table)
  local max = 0;
  for i = 1, #table do
	if (table[i] > max) then max = table[i]; end
  end
  return max;
end

local function getLabelUpdater(self)
  local lastFps = {};
  local lastFpsCounter = 1;
  local incFpsCounter = 1;
  return function(event)
	local curTime = system.getTimer();
	local dt = curTime - prevTime;
	prevTime = curTime;

	local ox = display.screenOriginX + 5;
	local fps = math.floor(1000 / dt);

	lastFps[lastFpsCounter] = fps;
	lastFpsCounter = lastFpsCounter + 1;
	incFpsCounter = incFpsCounter + 1;
	if (lastFpsCounter > maxSavedFps) then lastFpsCounter = 1; end
	local minLastFps = minElement(lastFps);
	local maxLastFps = maxElement(lastFps);

	if (incFpsCounter > incrementalUpdateRate) then
	  incFpsCounter = 1
	  self.framerate.text = "F: " .. fps .. " [" .. minLastFps .. "/" .. maxLastFps .. "]";
	  self.framerate:setReferencePoint(display.TopLeftReferencePoint)
	  self.framerate.x = ox
	end

	collectgarbage("collect")

	local digits = 4
	local shift = 10 ^ digits

	self.memoryLabel.text = "M: " .. math.floor((collectgarbage("count") / 1024) * shift + 0.5) / shift .. " Mb"
	self.memoryLabel:setReferencePoint(display.TopLeftReferencePoint)
	self.memoryLabel.x = ox

	local textMem = math.floor(system.getInfo("textureMemoryUsed") / 1000000 * shift + 0.5) / shift
	self.textureLabel.text = "T: " .. textMem .. " Mb"
	self.textureLabel:setReferencePoint(display.TopLeftReferencePoint)
	self.textureLabel.x = ox
  end
end


local instance --= nil;
-- Singleton
function PerformanceOutput.new()
  if (instance ~= nil) then return instance; end
  local self = {};
  setmetatable(self, PerformanceOutput.mt);

  self.group = createLayout(self);

  Runtime:addEventListener("enterFrame", getLabelUpdater(self));

  instance = self;
  return self;
end