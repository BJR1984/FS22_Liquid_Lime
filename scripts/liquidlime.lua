
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

--[=[
	local function newHUDExtension(self, superFunc, vehicle, uiScale, uiTextColor, uiTextSize)
		
		local HUDExtension = superFunc(self, vehicle, uiScale, uiTextColor, uiTextSize)
		local texts = HUDExtension.texts
		
		texts['headline_n_liquidFertilizer_ORIGINAL'] = HUDExtension.texts.headline_n_liquidFertilizer
		texts['headline_n_liquidFertilizer_LIQUIDLIME'] = HUDExtension.texts.headline_n_liquidFertilizer:gsub("Liquid Lime", "LIQUIDLIME")
		
		return HUDExtension
	end
]=]
	local function liquidLimeExtendedSprayerHUDExtension(self, superFunc, leftPosX, rightPosX, posY)
		local ExtendedSprayerHUDExtension = _G['FS22_precisionFarming'].ExtendedSprayerHUDExtension --Check if needed
		if not self:canDraw() then
			return
		end

		local upperPosY = posY + ((self.displayHeight or 0) + (self.additionalDisplayHeight or 0))

		local vehicle = self.realVehicle
		local spec = vehicle.spec_extendedSprayer

		local headline = self.texts.headline_ph_liquidlime

		local applicationRate = 0
		local applicationRateReal = 0
		local applicationRateStr = "%d l/ha"

		local changeBarText = ""

		local minValue = 0
		local maxValue = 0

		self.hasValidValues = false

		local soilTypeName = ""

		if spec.lastTouchedSoilType ~= 0 and self.soilMap ~= nil then
			local soilType = self.soilMap:getSoilTypeByIndex(spec.lastTouchedSoilType)
			if soilType ~= nil then
				soilTypeName = soilType.name
			end
		end

		local hasLimeLoaded = false
		local fillTypeDesc
		local sourceVehicle, fillUnitIndex = self:getFillTypeSourceVehicle(self.vehicle)
		local sprayFillType = sourceVehicle:getFillUnitFillType(fillUnitIndex)
		fillTypeDesc = g_fillTypeManager:getFillTypeByIndex(sprayFillType)
		local massPerLiter = (fillTypeDesc.massPerLiter / FillTypeManager.MASS_SCALE)

		if sprayFillType == FillType.LIQUIDLIME then
			hasLimeLoaded = true
		else
			return superFunc(self, leftPosX, rightPosX, posY)
		end

		local descriptionText = ""
		local stepResolution

		local enableZeroTargetFlag = false

		self.gradientInactive:setUVs(self.isColorBlindMode and self.colorBlindGradientUVsInactive or self.pHGradientUVsInactive)
		self.gradient:setUVs(self.isColorBlindMode and self.colorBlindGradientUVs or self.pHGradientUVs)

		local pHChanged = 0
		applicationRate = spec.lastLitersPerHectar * massPerLiter
		if not spec.sprayAmountAutoMode then
			local requiredLitersPerHa = self.pHMap:getLimeUsageByStateChange(spec.sprayAmountManual)
			pHChanged = self.pHMap:getPhValueFromChangedStates(spec.sprayAmountManual)
			applicationRate = requiredLitersPerHa * massPerLiter

			if pHChanged > 0 then
				changeBarText = string.format("pH +%s", formatDecimalNumber(pHChanged))
			end
		end

		local pHActualInt = spec.phActualBuffer:get()
		local pHTargetInt = spec.phTargetBuffer:get()
		local pHActual = self.pHMap:getPhValueFromInternalValue(pHActualInt)
		local pHTarget = self.pHMap:getPhValueFromInternalValue(pHTargetInt)
		if pHActualInt ~= 0 and pHTargetInt ~= 0 then
			self.actualValue = pHActual
			self.setValue = pHActual + pHChanged
			self.targetValue = pHTarget

			if spec.sprayAmountAutoMode then
				pHChanged = self.targetValue - self.actualValue
				if pHChanged > 0 then
					changeBarText = string.format("pH +%s", formatDecimalNumber(pHChanged))
				end
				self.setValue = self.targetValue
			end
			self.actualValueStr = "pH %.3f"
			if soilTypeName ~= "" then
				if spec.sprayAmountAutoMode then
					descriptionText = string.format(self.texts.description_limeAuto, soilTypeName, formatDecimalNumber(pHTarget))
				else
					descriptionText = string.format(self.texts.description_limeManual, soilTypeName, formatDecimalNumber(pHTarget))
				end
			end
		self.hasValidValues = true

		local nActualInt = spec.nActualBuffer:get()
		local nTargetInt = spec.nTargetBuffer:get()
		local nActual = self.nitrogenMap:getNitrogenValueFromInternalValue(nActualInt)
		local nTarget = self.nitrogenMap:getNitrogenValueFromInternalValue(nTargetInt)
		if nActualInt > 0 and nTargetInt > 0 then
			self.actualValue = nActual
			self.setValue = nActual + nitrogenChanged
			self.targetValue = nTarget

			if spec.sprayAmountAutoMode then
				nitrogenChanged = self.targetValue - self.actualValue
				if nitrogenChanged > 0 then
					changeBarText = string.format("+%dkg N/ha", nitrogenChanged)
				end

				self.setValue = self.targetValue
			end

			self.actualValueStr = "%dkg N/ha"

			local forcedFruitType
			if vehicle.spec_sowingMachine ~= nil then
				forcedFruitType = vehicle.spec_sowingMachine.workAreaParameters.seedsFruitType
			end

			local fillType = g_fillTypeManager:getFillTypeByIndex(g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(forcedFruitType or spec.nApplyAutoModeFruitType))
			if fillType ~= nil then
				if fillType ~= FillType.UNKNOWN and soilTypeName ~= "" then
					if nTarget > 0 then
						if spec.sprayAmountAutoMode then
							descriptionText = string.format(self.texts.description_fertilizerAutoFruit, fillType.title, soilTypeName)
						else
							descriptionText = string.format(self.texts.description_fertilizerManualFruit, fillType.title, soilTypeName)
						end
					else
						descriptionText = self.texts.description_noFertilizerRequired
						enableZeroTargetFlag = true
					end
				end
			end

			if descriptionText == "" and soilTypeName ~= "" then
				if spec.sprayAmountAutoMode then
					descriptionText = string.format(self.texts.description_fertilizerAutoNoFruit, soilTypeName)

					if self.nitrogenMap ~= nil then
						local fruitTypeIndex = self.nitrogenMap:getFruitTypeIndexByFruitRequirementIndex(spec.nApplyAutoModeFruitRequirementDefaultIndex)
						if fruitTypeIndex ~= nil then
							local _fillType = g_fillTypeManager:getFillTypeByIndex(g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(fruitTypeIndex))
							if _fillType ~= nil then
								descriptionText = string.format(self.texts.description_fertilizerAutoNoFruitDefault, _fillType.title, soilTypeName)
							end
						end
					end
				else
					descriptionText = string.format(self.texts.description_fertilizerManualNoFruit, soilTypeName)
				end
			end

			self.hasValidValues = true
		end

		if self.nitrogenMap ~= nil then
			minValue, maxValue = self.nitrogenMap:getMinMaxValue()

			local nAmount = spec.lastNitrogenProportion
			if nAmount == 0 then
				nAmount = self.nitrogenMap:getNitrogenAmountFromFillType(sprayFillType)
			end

			if spec.isSlurryTanker then
				local str = " (~%skgN/m³)"
				if sourceVehicle:getIsUsingExactNitrogenAmount() then
					str = " (%skgN/m³)"
				end

				applicationRateStr = applicationRateStr .. string.format(str, MathUtil.round(nAmount * 1000, 1))
			else
				applicationRateStr = applicationRateStr .. string.format(" (%s%%%%N)", MathUtil.round(nAmount * 100, 1))
			end

			stepResolution = self.nitrogenMap:getNitrogenFromChangedStates(1)
		end
	end

	if spec.sprayAmountAutoMode then
		applicationRateStr = applicationRateStr .. string.format(" (%s)", self.texts.automaticShort)
		soilTypeName = ""
	end

	self.actualPos = math.min((self.actualValue - minValue) / (maxValue - minValue), 1)
	self.setValuePos = math.min((self.setValue - minValue) / (maxValue - minValue), 1)
	self.targetPos = math.min((self.targetValue - minValue) / (maxValue - minValue), 1)

	local centerX = leftPosX + (rightPosX - leftPosX) * 0.5

	setTextColor(unpack(self.uiTextColor))
	setTextBold(true)
	setTextAlignment(RenderText.ALIGN_CENTER)
	renderDoubleText(centerX, upperPosY - self.textHeightHeadline * 1.1, self.textHeightHeadline, headline)
	setTextBold(false)

	-- gradient
	local gradientPosX = centerX - self.gradientInactive.width * 0.5 + self.gradientPosX
	local gradientPosY = upperPosY + self.gradientPosY
	if not self.hasValidValues then
		gradientPosY = gradientPosY + (self.actualBar.height - self.gradientInactive.height) + self.textHeight
	end

	self.gradientInactive:setPosition(gradientPosX, gradientPosY)
	self.gradientInactive:render()

	local gradientVisibilePos = 0
	if self.hasValidValues then
		gradientVisibilePos = self.actualPos
	end

	self.gradient:setPosition(gradientPosX, gradientPosY)
	self.gradient:setDimension(gradientVisibilePos * self.gradientInactive.width)
	self.gradient.uvs[5] = self.gradientInactive.uvs[1] + (self.gradientInactive.uvs[5] - self.gradientInactive.uvs[1]) * gradientVisibilePos
	self.gradient.uvs[7] = self.gradientInactive.uvs[3] + (self.gradientInactive.uvs[7] - self.gradientInactive.uvs[3]) * gradientVisibilePos
	self.gradient:setUVs(self.gradient.uvs)
	self.gradient:render()

	local labelMin
	local labelMax
	labelMin = string.format("pH\n%s", minValue)
	labelMax = string.format("pH\n%s", maxValue)

	local widthDiff = ((rightPosX - leftPosX) - self.gradientInactive.width) * 0.425
	renderDoubleText(gradientPosX - widthDiff, gradientPosY + self.gradientInactive.height * 0.85, self.gradientInactive.height * 1.3, labelMin)
	renderDoubleText(gradientPosX + self.gradientInactive.width + widthDiff, gradientPosY + self.gradientInactive.height * 0.85, self.gradientInactive.height * 1.3, labelMax)

	local additionalChangeLineHeight = 0

	-- actual
	local changeBarRendered = false
	if self.hasValidValues then
		-- target
		local targetBarX, targetBarY
		local showFlag = self.targetPos ~= 0 or enableZeroTargetFlag
		if showFlag then
			targetBarX = gradientPosX + self.gradientInactive.width * self.targetPos - self.targetBar.width * 0.5
			targetBarY = gradientPosY
			self.targetBar:setPosition(targetBarX, targetBarY)
			self.targetBar:render()

			self.targetFlag:setPosition(targetBarX, targetBarY + self.targetBar.height)
			self.targetFlag:render()
		end

		local actualBarText
		local actualBarTextOffset = self.actualBar.height + self.textHeight * 1.1
		local actualBarSkipFlagCollisionCheck = false
		if self.actualPos ~= self.targetPos then
			actualBarText = string.format(self.texts.actualValue, string.format(self.actualValueStr, self.actualValue))
		elseif spec.sprayAmountAutoMode or self.targetPos == self.setValuePos then
			if self.targetPos ~= 0 then
				actualBarText = string.format(self.texts.targetReached, string.format(self.actualValueStr, self.actualValue))
				actualBarTextOffset = -self.textHeight * 0.7
				actualBarSkipFlagCollisionCheck = true
				changeBarRendered = true
			end
		end

		if actualBarText ~= nil then
			local actualBarX = gradientPosX + self.gradientInactive.width * self.actualPos - self.actualBar.width * 0.5
			local actualBarY = gradientPosY + (self.gradientInactive.height - self.actualBar.height) * 0.5

			self.actualBar:setPosition(actualBarX, actualBarY)
			self.actualBar:render()

			local actualTextWidth = getTextWidth(self.textHeight * 0.7, actualBarText)
			actualBarX = math.max(math.min(actualBarX, rightPosX - actualTextWidth * 0.5), leftPosX + actualTextWidth * 0.5)

			if not actualBarSkipFlagCollisionCheck and showFlag then
				local rightTextBorder = actualBarX + actualTextWidth * 0.5
				if rightTextBorder > targetBarX and rightTextBorder < targetBarX + self.targetFlag.width * 0.5 then
					actualBarX = targetBarX - actualTextWidth * 0.5 - self.pixelSizeX
				end

				local leftTextBorder = actualBarX - actualTextWidth * 0.5
				if (leftTextBorder > targetBarX and leftTextBorder < targetBarX + self.targetFlag.width * 0.5)
				or (targetBarX > leftTextBorder and targetBarX < rightTextBorder) then
					actualBarX = targetBarX + self.targetFlag.width + self.pixelSizeX + actualTextWidth * 0.5
				end
			end

			renderDoubleText(actualBarX, actualBarY + actualBarTextOffset, self.textHeight * 0.7, actualBarText)
		end

		if self.setValuePos > self.actualPos then
			local goodColor = ExtendedSprayerHUDExtension.COLOR.SET_VALUE_BAR_GOOD
			local badColor = ExtendedSprayerHUDExtension.COLOR.SET_VALUE_BAR_BAD
			local difference = math.min((math.abs(self.setValue - self.targetValue) / stepResolution) / 3, 1)
			local differenceInv = 1 - difference
			local r, g, b, a = difference * badColor[1] + differenceInv * goodColor[1],
							difference * badColor[2] + differenceInv * goodColor[2],
							difference * badColor[3] + differenceInv * goodColor[3],
							1
			local setValueBarX = gradientPosX + self.gradientInactive.width * self.actualPos
			local setValueBarY = gradientPosY - self.gradientInactive.height - self.setValueBar.height
			self.setValueBar:setPosition(setValueBarX, setValueBarY)
			self.setValueBar:setDimension(self.gradientInactive.width * (math.min(self.setValuePos, 1) - self.actualPos))
			self.setValueBar:setColor(r, g, b, a)
			self.setValueBar:render()

			local setBarTextX = setValueBarX + self.setValueBar.width * 0.5
			local setBarTextY = setValueBarY + self.setValueBar.height * 0.2
			local setTextWidth = getTextWidth(self.setValueBar.height * 0.9, changeBarText)
			if setTextWidth > self.setValueBar.width * 0.95 then
				setBarTextY = setValueBarY - self.setValueBar.height
				additionalChangeLineHeight = self.setValueBar.height
			end
			renderDoubleText(setBarTextX, setBarTextY, self.setValueBar.height * 0.9, changeBarText)

			changeBarRendered = true
		end
	else
		descriptionText = self.texts.invalidValues
	end

	if descriptionText ~= "" and self.additionalDisplayHeight ~= 0 then
		setTextAlignment(RenderText.ALIGN_CENTER)
		renderDoubleText(centerX, posY + self.footerOffset + self.additionalTextHeightOffset - self.textHeight * 0.2, self.textHeight * 0.85, descriptionText, self.footerSeparationBar.width)
	end

	self.footerSeparationBar:setPosition(centerX - self.footerSeparationBar.width * 0.5, posY + self.footerOffset + self.textHeight * 1.2)
	self.footerSeparationBar:render()

	-- footer
	setTextAlignment(RenderText.ALIGN_LEFT)
	renderDoubleText(leftPosX, posY + self.footerOffset, self.textHeight, self.texts.applicationRate .. " " .. string.format(applicationRateStr, applicationRate, applicationRateReal))

	if soilTypeName ~= "" then
		setTextAlignment(RenderText.ALIGN_RIGHT)
		renderDoubleText(rightPosX, posY + self.footerOffset, self.textHeight, string.format(self.texts.soilType, soilTypeName))
	end

	-- do that at the end so we give the ui some time to increase the window height and then render the text above
	self.additionalDisplayHeight = additionalChangeLineHeight
	if descriptionText ~= "" then
		self.additionalDisplayHeight = self.additionalDisplayHeight + self.additionalTextHeightOffset
	end
	if not self.hasValidValues then
		self.additionalDisplayHeight = self.additionalDisplayHeight - self.invalidHeightOffset
	elseif not changeBarRendered then
		self.additionalDisplayHeight = self.additionalDisplayHeight - self.noSetBarHeightOffset
	end

	return posY
	end
	
	local ExtendedSprayerHUDExtension = _G['FS22_precisionFarming'].ExtendedSprayerHUDExtension
	--HUDExtension.new = Utils.appendedFunction(HUDExtension.new, newHUDExtension)
	ExtendedSprayerHUDExtension.draw = Utils.overwrittenFunction(ExtendedSprayerHUDExtension.draw, liquidLimeExtendedSprayerHUDExtension)

--Utils.prependedFunction
--Utils.appendedFunction
--Utils.overwrittenFunction

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