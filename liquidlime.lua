
--===============================================================
-- BASE GAME - ADD LIQUIDLIME AS SPRAY TYPE
--===============================================================

local function addSprayType(sprayName, appRate, spraytypeName, groundType, baseType)
	
	if sprayName ~= nil and appRate ~= nil and spraytypeName ~= nil and groundType ~= nil and baseType ~= nil then
		-- print("SprayName: "..sprayName, "AppRate: "..appRate, "SprayType: "..spraytypeName, "Ground: "..groundType, "Base: "..tostring(baseType))
		if g_sprayTypeManager:addSprayType(sprayName, appRate, spraytypeName, groundType, baseType) then
			print("  BJR1984-INFO: Added Spraytype - "..sprayName)
		end
	end	
end
local function appendLoadMapData(self)
	
	print("  BJR1984-INFO: Registering New Spray Types")
	addSprayType("LIQUIDLIME", 0.0900, "LIME", 4, true)
	
end
SprayTypeManager.loadMapData = Utils.appendedFunction(SprayTypeManager.loadMapData, appendLoadMapData)

--===============================================================
-- PRECISION FARMING - ADD LIQUIDLIME AS SPRAY TYPE
--===============================================================

local function injectPrecisionFarmingFunctions()
	
	if not _G['FS22_precisionFarming'] then
		return
	end
	
	print("  BJR1984-INFO: Injecting LIQUIDLIME into Precision Farming")
--[[	
	local function newHUDExtension(self, superFunc, vehicle, uiScale, uiTextColor, uiTextSize)
		
		local HUDExtension = superFunc(self, vehicle, uiScale, uiTextColor, uiTextSize)
		local texts = HUDExtension.texts
		
		texts['headline_n_liquidFertilizer_ORIGINAL'] = HUDExtension.texts.headline_n_liquidFertilizer
		texts['headline_n_liquidFertilizer_LIQUIDLIME'] = HUDExtension.texts.headline_n_liquidFertilizer:gsub("Liquid Lime", "LIQUIDLIME")
		
		return HUDExtension
	end
	
	local function drawExtendedSprayerHUDExtension(self, leftPosX, rightPosX, posY)
		local ExtendedSprayerHUDExtension = _G['FS22_precisionFarming'].ExtendedSprayerHUDExtension --Check if needed
		if not self:canDraw() then
			return
		end
		local sourceVehicle, fillUnitIndex = ExtendedSprayerHUDExtension:getFillTypeSourceVehicle(self.vehicle)
		local sprayFillType = sourceVehicle:getFillUnitFillType(fillUnitIndex)
		if sprayFillType == FillType.LIQUIDLIME then
			hasLimeLoaded = true
		end
	end
	
	local ExtendedSprayerHUDExtension = _G['FS22_precisionFarming'].ExtendedSprayerHUDExtension
	HUDExtension.new = Utils.overwrittenFunction(HUDExtension.new, newHUDExtension)
	ExtendedSprayerHUDExtension.draw = Utils.overwrittenFunction(ExtendedSprayerHUDExtension.draw, drawExtendedSprayerHUDExtension)
]]	
	local function onEndWorkAreaProcessing(self, dt, hasProcessed)
		local spec = self.spec_extendedSprayer
		local specSprayer = self.spec_sprayer
		
		if self.isServer and specSprayer.workAreaParameters.isActive then
			local sprayVehicle = specSprayer.workAreaParameters.sprayVehicle
			local usage = specSprayer.workAreaParameters.usage
			local fillType = specSprayer.workAreaParameters.sprayFillType
			
			if (sprayVehicle ~= nil or self:getIsAIActive()) and self:getIsTurnedOn() then
				local usageRegular = spec.lastRegularUsage
				local farmlandStatistics, _, farmlandId = self:getPFStatisticInfo()
				
				if farmlandStatistics ~= nil and farmlandId ~= nil then
					if fillType == FillType.LIQUIDLIME then
						farmlandStatistics:updateStatistic(farmlandId, "usedLiquidLime", usage)
						farmlandStatistics:updateStatistic(farmlandId, "usedLiquidLimeRegular", usageRegular)
						-- print(" usage " .. tostring(usage))
					end
				end
			end
		end
	end
	
	local function getCurrentSprayerMode(self, superFunc)
		local ExtendedSprayer = _G['FS22_precisionFarming'].ExtendedSprayer --Check if needed
		local sprayer, fillUnitIndex = ExtendedSprayer.getFillTypeSourceVehicle(self)
		local fillType = sprayer:getFillUnitLastValidFillType(fillUnitIndex)
		if fillType == FillType.LIQUIDLIME then
			return true, false
			else
			return superFunc(self)
		end
	end
	
	local ExtendedSprayer = _G['FS22_precisionFarming'].ExtendedSprayer
	ExtendedSprayer.onEndWorkAreaProcessing = Utils.appendedFunction(ExtendedSprayer.onEndWorkAreaProcessing, onEndWorkAreaProcessing)
	ExtendedSprayer.getCurrentSprayerMode = Utils.overwrittenFunction(ExtendedSprayer.getCurrentSprayerMode, getCurrentSprayerMode)
	
	function loadFromItemsXML(self, xmlFile, key)
		print("key: ".. tostring(key) )
		print("statistics: ".. tostring(self.statisticsByFarmland) )
		-- DebugUtil.printTableRecursively(self.statisticsByFarmland, "-- ", 0, 1)
	end
	
	local FarmlandStatistics = _G['FS22_precisionFarming'].FarmlandStatistics
	FarmlandStatistics.loadFromItemsXML = Utils.appendedFunction(FarmlandStatistics.loadFromItemsXML, loadFromItemsXML)
end

local function prependFinalizeTypes(self)
	if self.rootElementName == 'vehicleTypes' then
		-- print("   FINALIZE VEHICLE TYPES ")
		if g_modIsLoaded['FS22_precisionFarming'] then
			print("  INFO: Precision Farming Loaded")
			injectPrecisionFarmingFunctions()
		end
	end
end

local oldFinalizeTypes = getmetatable(_G).__index.TypeManager.finalizeTypes
getmetatable(_G).__index.TypeManager.finalizeTypes = function(...) prependFinalizeTypes(...)
	return oldFinalizeTypes(...)
end						