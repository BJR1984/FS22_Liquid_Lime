
--===============================================================
-- BASE GAME - ADD LIQUIDLIME AS SPRAY TYPE
--===============================================================

local function addSprayType(sprayName, appRate, spraytypeName, groundType, baseType)
	if sprayName ~= nil and appRate ~= nil and spraytypeName ~= nil and groundType ~= nil and baseType ~= nil then
		-- print("SprayName: "..sprayName, "AppRate: "..appRate, "SprayType: "..spraytypeName, "Ground: "..groundType, "Base: "..tostring(baseType))
		if g_sprayTypeManager:addSprayType(sprayName, appRate, spraytypeName, groundType, baseType) then
			print("BJR1984-INFO: Added Spraytype - "..sprayName)
		end
	end
end

local function appendLoadMapData(self)
	print("BJR1984-INFO: Registering New Spray Types")
	addSprayType("LIQUIDLIME", 0.0162, "LIME", 4, true)
end

SprayTypeManager.loadMapData = Utils.appendedFunction(SprayTypeManager.loadMapData, appendLoadMapData)

--===============================================================
-- PRECISION FARMING - ADD LIQUIDLIME AS SPRAY TYPE
--===============================================================

local function injectPrecisionFarmingFunctions()
	if not _G['FS22_precisionFarming'] then
		return
	end

	print("BJR1984-INFO: Injecting LIQUIDLIME into Precision Farming")

	local function draw_ExtendedSprayerHUDExtension(self, superFunc, leftPosX, rightPosX, posY)
		local ExtendedSprayerHUDExtension = _G['FS22_precisionFarming'].ExtendedSprayerHUDExtension --Check if needed
		if not self:canDraw() then
			return
		end
		local upperPosY = posY + ((self.displayHeight or 0) + (self.additionalDisplayHeight or 0))
		local vehicle = self.realVehicle
		local spec = vehicle.spec_extendedSprayer
		local headline = g_i18n:getText("hudExtensionSprayer_headline_ph_liquidlime", "LIQUIDLIME")
		local applicationRate = 0
		local applicationRateReal = 0
		local applicationRateStr = "%d.3 l/ha"
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
		local sourceVehicle, fillUnitIndex = self:getFillTypeSourceVehicle(self.vehicle)
		local sprayFillType = sourceVehicle:getFillUnitFillType(fillUnitIndex)
		fillTypeDesc = g_fillTypeManager:getFillTypeByIndex(sprayFillType)
		if sprayFillType ~= FillType.LIQUIDLIME then
			return superFunc(self, leftPosX, rightPosX, posY)
		end
		local descriptionText = ""
		local stepResolution
		local enableZeroTargetFlag = false
		local litersPerHectar = spec.lastLitersPerHectar
-- Start of old if hasLimeLoaded then
		self.gradientInactive:setUVs(self.isColorBlindMode and self.colorBlindGradientUVsInactive or self.pHGradientUVsInactive)
		self.gradient:setUVs(self.isColorBlindMode and self.colorBlindGradientUVs or self.pHGradientUVs)
		local pHChanged = 0
		applicationRate = litersPerHectar
		if not spec.sprayAmountAutoMode then
			local requiredLitersPerHa = self.pHMap:getLimeUsageByStateChange(spec.sprayAmountManual)
			pHChanged = self.pHMap:getPhValueFromChangedStates(spec.sprayAmountManual)
			applicationRate = requiredLitersPerHa
			if pHChanged > 0 then
				changeBarText = string.format("pH +%s", string.format("%.2f",pHChanged))
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
					changeBarText = string.format("pH +%s", string.format("%.2f",pHChanged))
				end
				self.setValue = self.targetValue
			end
			self.actualValueStr = "pH %.3f"
			if soilTypeName ~= "" then
				if spec.sprayAmountAutoMode then
					descriptionText = string.format(self.texts.description_limeAuto, soilTypeName, string.format("%.2f",pHTarget))
				else
					descriptionText = string.format(self.texts.description_limeManual, soilTypeName, string.format("%.2f",pHTarget))
				end
			end
			self.hasValidValues = true
		end
		if self.pHMap ~= nil then
			minValue, maxValue = self.pHMap:getMinMaxValue()
		end
		stepResolution = spec.pHMap:getPhValueFromChangedStates(1)
		-- Else end of pH Section
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
		renderText(centerX, upperPosY - self.textHeightHeadline * 1.1, self.textHeightHeadline, headline)
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
		local widthDiff = ((rightPosX - leftPosX) - self.gradientInactive.width) * 0.425
		renderText(gradientPosX - widthDiff, gradientPosY + self.gradientInactive.height * 0.85, self.gradientInactive.height * 1.3, string.format("pH\n%s", minValue))
		renderText(gradientPosX + self.gradientInactive.width + widthDiff, gradientPosY + self.gradientInactive.height * 0.85, self.gradientInactive.height * 1.3, string.format("pH\n%s", maxValue))
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
				renderText(actualBarX, actualBarY + actualBarTextOffset, self.textHeight * 0.7, actualBarText)
			end
			if self.setValuePos > self.actualPos then
				local goodColor = ExtendedSprayerHUDExtension.COLOR.SET_VALUE_BAR_GOOD
				local badColor = ExtendedSprayerHUDExtension.COLOR.SET_VALUE_BAR_BAD
				local difference = math.min((math.abs(self.setValue - self.targetValue) / stepResolution) / 3, 1)
				local differenceInv = 1 - difference
				local r, g, b, a = difference * badColor[1] + differenceInv * goodColor[1], difference * badColor[2] + differenceInv * goodColor[2], difference * badColor[3] + differenceInv * goodColor[3], 1
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
				renderText(setBarTextX, setBarTextY, self.setValueBar.height * 0.9, changeBarText)
				changeBarRendered = true
			end
		else
			descriptionText = self.texts.invalidValues
		end
		if descriptionText ~= "" and self.additionalDisplayHeight ~= 0 then
			setTextAlignment(RenderText.ALIGN_CENTER)
			renderText(centerX, posY + self.footerOffset + self.additionalTextHeightOffset - self.textHeight * 0.2, self.textHeight * 0.85, descriptionText, self.footerSeparationBar.width)
		end
		self.footerSeparationBar:setPosition(centerX - self.footerSeparationBar.width * 0.5, posY + self.footerOffset + self.textHeight * 1.2)
		self.footerSeparationBar:render()
		-- footer
		setTextAlignment(RenderText.ALIGN_LEFT)
		renderText(leftPosX, posY + self.footerOffset, self.textHeight, self.texts.applicationRate .. " " .. string.format(applicationRateStr, applicationRate, applicationRateReal))
		if soilTypeName ~= "" then
			setTextAlignment(RenderText.ALIGN_RIGHT)
			renderText(rightPosX, posY + self.footerOffset, self.textHeight, string.format(self.texts.soilType, soilTypeName))
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
	ExtendedSprayerHUDExtension.draw = Utils.overwrittenFunction(ExtendedSprayerHUDExtension.draw, draw_ExtendedSprayerHUDExtension)

	local function onEndWorkAreaProcessing_ExtendedSprayer(self, dt, hasProcessed)
		local spec = self.spec_extendedSprayer
		local specSprayer = self.spec_sprayer
		if self.isServer then
			if specSprayer.workAreaParameters.isActive then
				local sprayVehicle = specSprayer.workAreaParameters.sprayVehicle
				local usage = specSprayer.workAreaParameters.usage
				local fillType = specSprayer.workAreaParameters.sprayFillType
				if sprayVehicle ~= nil or self:getIsAIActive() then
					if self:getIsTurnedOn() then
						local usageRegular = spec.lastRegularUsage
						local farmlandStatistics, _, farmlandId = self:getPFStatisticInfo()
						if farmlandStatistics ~= nil and farmlandId ~= nil then
							if fillType == FillType.LIME
							or fillType == FillType.LIQUIDLIME then
								farmlandStatistics:updateStatistic(farmlandId, "usedLime", usage)
								farmlandStatistics:updateStatistic(farmlandId, "usedLimeRegular", usageRegular)
							elseif fillType == FillType.FERTILIZER then
								farmlandStatistics:updateStatistic(farmlandId, "usedMineralFertilizer", usage)
								farmlandStatistics:updateStatistic(farmlandId, "usedMineralFertilizerRegular", usageRegular)
							elseif fillType == FillType.LIQUIDFERTILIZER then
								farmlandStatistics:updateStatistic(farmlandId, "usedLiquidFertilizer", usage)
								farmlandStatistics:updateStatistic(farmlandId, "usedLiquidFertilizerRegular", usageRegular)
							elseif fillType == FillType.MANURE then
								farmlandStatistics:updateStatistic(farmlandId, "usedManure", usage)
								farmlandStatistics:updateStatistic(farmlandId, "usedManureRegular", usageRegular)
							elseif fillType == FillType.LIQUIDMANURE or fillType == FillType.DIGESTATE then
								farmlandStatistics:updateStatistic(farmlandId, "usedLiquidManure", usage)
								farmlandStatistics:updateStatistic(farmlandId, "usedLiquidManureRegular", usageRegular)
							end
						end
					end
				end
			end
		end
	end
	
	local function getCurrentSprayerMode_ExtendedSprayer(self, superFunc)
		local ExtendedSprayer = _G['FS22_precisionFarming'].ExtendedSprayer --Check if needed
		local sprayer, fillUnitIndex = ExtendedSprayer.getFillTypeSourceVehicle(self)
		local fillType = sprayer:getFillUnitLastValidFillType(fillUnitIndex)
		if fillType == FillType.LIQUIDLIME then
			return true, false
		else
			return superFunc(self)
		end
	end
	
	local function onChangedFillType_ExtendedSprayer(self, superFunc, fillUnitIndex, fillTypeIndex, oldFillTypeIndex)
		local spec = self.spec_extendedSprayer
		if spec.isSolidFertilizerSprayer and fillTypeIndex == FillType.LIME then
			local _, _, pHMaxValue = spec.pHMap:getMinMaxValue()
			spec.sprayAmountManualMax = pHMaxValue - 1
			spec.pHMap.limeUsage.usagePerState = 730
			spec.isLimingActive = true
		elseif spec.isLiquidFertilizerSprayer and fillTypeIndex == FillType.LIQUIDLIME then
			local _, _, pHMaxValue = spec.pHMap:getMinMaxValue()
			spec.sprayAmountManualMax = pHMaxValue - 1
			spec.pHMap.limeUsage.usagePerState = 200
			spec.isLimingActive = true
		else
			local _, _, nMaxValue = spec.nitrogenMap:getMinMaxValue()
			spec.sprayAmountManualMax = nMaxValue - 1
			spec.isLimingActive = false
		end
	end

	local function onUpdate_ExtendedSprayer(self, superFunc, dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
		local ExtendedSprayer = _G['FS22_precisionFarming'].ExtendedSprayer --Check if needed
		local spec = self.spec_extendedSprayer
		if self.isServer then
			if g_time - spec.lastAreaChangeTime > 500 then
				spec.lastGroundUpdateDistance = spec.lastGroundUpdateDistance + self.lastMovedDistance
					if spec.lastGroundUpdateDistance > spec.groundUpdateDistance then
					spec.lastGroundUpdateDistance = 0
					local workArea = self:getWorkAreaByIndex(1)
					if workArea ~= nil then
						local x, _y, z
						-- if the work area starts in the middle of the vehicle we use the start node, otherwise the middle between start and width
						local lx, _, _ = localToLocal(workArea.start, self.rootNode, 0, 0, 0)
						if math.abs(lx) < 0.5 then
							x, y, z =getWorldTranslation(workArea.start)
						else
							local x1, y1, z1 = getWorldTranslation(workArea.start)
							local x2, y2, z2 = getWorldTranslation(workArea.width)
							x, y, z = (x1 + x2) * 0.5, (y1 + y2) * 0.5, (z1 + z2) * 0.5
						end
						local isOnField, _ = FSDensityMapUtil.getFieldDataAtWorldPosition(x, 0, z)
						if isOnField then
							local sprayer, fillUnitIndex = ExtendedSprayer.getFillTypeSourceVehicle(self)
							local fillType = sprayer:getFillUnitLastValidFillType(fillUnitIndex)
							if fillType == FillType.UNKNOWN then
								fillType = sprayer:getFillUnitFirstSupportedFillType(fillUnitIndex)
							end
							if fillType == FillType.LIME
							or fillType == FillType.LIQUIDLIME then
								local pHLevel = spec.pHMap:getLevelAtWorldPos(x, z)
								local pHOptimal = 0
								local soilTypeIndex = spec.soilMap:getTypeIndexAtWorldPos(x, z)
								if soilTypeIndex > 0 then
									pHOptimal = spec.pHMap:getOptimalPHValueForSoilTypeIndex(soilTypeIndex)
								end
								spec.phChangeBuffer:add(0)
								spec.phActualBuffer:add(pHLevel, true)
								spec.phTargetBuffer:add(pHOptimal, true)
								spec.lastTouchedSoilTypeReal = soilTypeIndex
								if spec.lastTouchedSoilType == 0 then
									spec.lastTouchedSoilType = soilTypeIndex
								end
							else
								local forcedFruitType
								if self.spec_sowingMachine ~= nil then
									forcedFruitType = self.spec_sowingMachine.workAreaParameters.seedsFruitType
								end
								local nLevel = spec.nitrogenMap:getLevelAtWorldPos(x, z)
								local nTarget, soilTypeIndex, fruitTypeIndex = spec.nitrogenMap:getTargetLevelAtWorldPos(x, z, nil, forcedFruitType, fillType, nLevel, spec.nApplyAutoModeFruitRequirementDefaultIndex)
								spec.nChangeBuffer:add(0)
								spec.nActualBuffer:add(nLevel, true, true)
								spec.nTargetBuffer:add(nTarget, true, true)
								self:setSprayAmountAutoFruitTypeIndex(fruitTypeIndex)
								spec.lastTouchedSoilTypeReal = soilTypeIndex
								if spec.lastTouchedSoilType == 0 then
									spec.lastTouchedSoilType = soilTypeIndex
								end
							end
						else
							spec.phChangeBuffer:reset()
							spec.phActualBuffer:reset()
							spec.phTargetBuffer:reset()

							spec.nChangeBuffer:reset()
							spec.nActualBuffer:reset()
							spec.nTargetBuffer:reset()

							spec.lastTouchedSoilType = 0
							spec.lastTouchedSoilTypeReal = 0
							spec.lastLitersPerHectar = 0
							spec.lastNitrogenProportion = 0

							self:raiseDirtyFlags(spec.usageValuesDirtyFlag)
						end
					end
				else
					spec.phActualBuffer:add(nil, true)
					spec.phTargetBuffer:add(nil, true)

					spec.nActualBuffer:add(nil, true)
					spec.nTargetBuffer:add(nil, true)
				end
			elseif self:getIsTurnedOn() then
				spec.phActualBuffer:add()
				spec.phTargetBuffer:add()

				spec.nActualBuffer:add()
				spec.nTargetBuffer:add()
				spec.lastGroundUpdateDistance = spec.groundUpdateDistance * 0.5
			else
				spec.lastGroundUpdateDistance = spec.groundUpdateDistance * 0.5
			end
		end
	end

	local ExtendedSprayer = _G['FS22_precisionFarming'].ExtendedSprayer
	ExtendedSprayer.onEndWorkAreaProcessing = Utils.overwrittenFunction(ExtendedSprayer.onEndWorkAreaProcessing, onEndWorkAreaProcessing_ExtendedSprayer)
	ExtendedSprayer.getCurrentSprayerMode = Utils.overwrittenFunction(ExtendedSprayer.getCurrentSprayerMode, getCurrentSprayerMode_ExtendedSprayer)
	ExtendedSprayer.onChangedFillType = Utils.overwrittenFunction(ExtendedSprayer.onChangedFillType, onChangedFillType_ExtendedSprayer)
	ExtendedSprayer.onUpdate = Utils.overwrittenFunction(ExtendedSprayer.onUpdate, onUpdate_ExtendedSprayer)
--[[
	local function onLoad_WeedSpotSpray(self, superFunc, savegame)
		local spec = self.spec_weedSpotSpray
		spec.limeLevelMapId, spec.limeLevelFirstChannel, spec.limeLevelNumChannels = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.LIME_LEVEL)
	end

	local function onUpdate_WeedSpotSpray(self, superFunc, dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
		local WeedSpotSpray = _G['FS22_precisionFarming'].WeedSpotSpray --Check if needed
		local spec = self.spec_weedSpotSpray
		if spec.isAvailable then
			local sprayFillType = self.spec_sprayer.workAreaParameters.sprayFillType
			if spec.isEnabled then
				if self:getIsTurnedOn() then
					for i=1, WeedSpotSpray.NOZZLE_UPDATES_PER_FRAME do
						local nozzleNode = spec.nozzleNodes[spec.currentUpdateIndex]
						if sprayFillType == FillType.HERBICIDE then
							local x, y, z = localToWorld(nozzleNode.node, 0, 0, nozzleNode.zOffset)
							local densityBits = getDensityAtWorldPos(spec.weedMapId, x, y, z)
							local weedState = bitAND(bitShiftRight(densityBits, spec.weedFirstChannel), 2 ^ spec.weedNumChannels - 1)
							if spec.weedDetectionStates[weedState] then
								nozzleNode.lastActiveTime = g_time + spec.nozzleUpdateFrameDelay * dt * 1.5
								spec.effectsDirty = true
							end
						elseif sprayFillType == FillType.LIQUIDLIME then
							local x, y, z = localToWorld(nozzleNode.node, 0, 0, nozzleNode.zOffset)
							local densityBits = getDensityAtWorldPos(spec.limeLevelMapId, x, y, z)
							local sprayType = bitAND(bitShiftRight(densityBits, spec.limeLevelFirstChannel), 2 ^ spec.limeLevelNumChannels - 1)
							local densityBitsGround = getDensityAtWorldPos(spec.groundTypeMapId, x, y, z)
							local groundType = bitAND(bitShiftRight(densityBitsGround, spec.groundTypeFirstChannel), 2 ^ spec.groundTypeNumChannels - 1)
							if groundType ~= 0 and sprayType ~= FieldSprayType.LIME then
								nozzleNode.lastActiveTime = g_time + spec.nozzleUpdateFrameDelay * dt * 1.5
								spec.effectsDirty = true
							end
						else
							local x, y, z = localToWorld(nozzleNode.node, 0, 0, nozzleNode.zOffset * 2)
							local densityBits = getDensityAtWorldPos(spec.sprayTypeMapId, x, y, z)
							local sprayType = bitAND(bitShiftRight(densityBits, spec.sprayTypeFirstChannel), 2 ^ spec.sprayTypeNumChannels - 1)
							local densityBitsGround = getDensityAtWorldPos(spec.groundTypeMapId, x, y, z)
							local groundType = bitAND(bitShiftRight(densityBitsGround, spec.groundTypeFirstChannel), 2 ^ spec.groundTypeNumChannels - 1)
							if groundType ~= 0 and sprayType ~= FieldSprayType.FERTILIZER then
								nozzleNode.lastActiveTime = g_time + spec.nozzleUpdateFrameDelay * dt * 1.5
								spec.effectsDirty = true
							end
						end
						spec.currentUpdateIndex = spec.currentUpdateIndex + 1
						if spec.currentUpdateIndex > #spec.nozzleNodes then
							spec.currentUpdateIndex = 1
						end
					end
				end
				self:updateNozzleEffects(dt, false)
			else
				self:updateNozzleEffects(dt, true, sprayFillType == FillType.UNKNOWN)
			end
		end
	end

	local WeedSpotSpray = _G['FS22_precisionFarming'].WeedSpotSpray
	WeedSpotSpray.onLoad = Utils.appendedFunction(WeedSpotSpray.onLoad, onLoad_WeedSpotSpray)
	WeedSpotSpray.onUpdate = Utils.overwrittenFunction(WeedSpotSpray.onUpdate, onUpdate_WeedSpotSpray)
]]
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
		-- print(" FINALIZE VEHICLE TYPES ")
		if g_modIsLoaded['FS22_precisionFarming'] then
			print("INFO: Precision Farming Loaded")
			injectPrecisionFarmingFunctions()
		end
	end
end

local oldFinalizeTypes = getmetatable(_G).__index.TypeManager.finalizeTypes
getmetatable(_G).__index.TypeManager.finalizeTypes = function(...) prependFinalizeTypes(...)
	return oldFinalizeTypes(...)
end