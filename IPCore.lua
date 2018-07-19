local IPUIDebug=false

function InstancePortalUI_OnLoad(self)
	LoadAddOn("Blizzard_WorldMap")
	self:RegisterEvent("ADDON_LOADED")

	RegisterCVar("IPUITrackInstancePortals", "1")

	IPUIPrintDebug("InstancePortalUI_OnLoad()")
	WorldMapFrame:AddDataProvider(CreateFromMixins(IPInstancePortalMapDataProviderMixin));
	hooksecurefunc("ToggleDropDownMenu", IPUIDropDownInit)

end

function IPUIDropDownInit(_, _, dropDownFrame, _, _, _, _, clickedButton)
	local trackingOptionsFrame = WorldMapFrame.overlayFrames[2]
	local trackingOptionsMenu = trackingOptionsFrame.DropDown

	local function OnSelection(button)
		SetCVar("IPUITrackInstancePortals", button.checked and "1" or "0", "INSTANCE_PORTAL_REFRESH");
	end

	if dropDownFrame == trackingOptionsMenu then

		local info = UIDropDownMenu_CreateInfo();

		UIDropDownMenu_AddSeparator();
		info.isTitle = nil;
		info.notCheckable = nil;
		info.text = DUNGEONS.." / "..RAIDS;
		info.isNotRadio = true;
		info.checked = GetCVarBool("IPUITrackInstancePortals");
		info.func = OnSelection;
		info.keepShownOnClick = true;
		info.value = "IPUITrackInstancePortals";
		UIDropDownMenu_AddButton(info);
	end
end

function IPUIPrintDebug(t)
	if (IPUIDebug) then
		print(t)
	end
end

function IPUIGetEntranceInfoForMapID(mapID, i)

		instancePortal = IPUIPinDB[mapID][i]
		if not (instancePortal) then
			IPUIPrintDebug("No instances for map: "..mapID)
			return nil
		end

		local x = instancePortal[1]/100
		local y = instancePortal[2]/100
		local subInstanceMapIDs = instancePortal[3]
		local hubName = instancePortal[4]

		if hubName then
			entranceInfo = {};

			entranceInfo["areaPoiID"] = C_AreaPoiInfo.GetAreaPOIForMap(mapID)[0];
			entranceInfo["position"] = CreateVector2D(x, y);
			entranceInfo["name"] = hubName;

			local description = "";
			local dungeonCount = 0
			local raidCount = 0

			for m = 1, #subInstanceMapIDs do
				local instanceID = subInstanceMapIDs[m]
				local localizedName = EJ_GetInstanceInfo(instanceID);
				local requiredLevel = IPUIInstanceMapDB[subInstanceMapIDs[m]][3]
				local dungonType = IPUIInstanceMapDB[subInstanceMapIDs[m]][2];

				if dungonType == 1 then
					dungeonCount=dungeonCount+1
					description = description..localizedName.." |cFF888888("..LFG_TYPE_DUNGEON.." - "..requiredLevel..")|r\n"
				else
					raidCount=raidCount+1
					description = description..localizedName.." |cFF888888("..LFG_TYPE_RAID.." - "..requiredLevel..")|r\n"
				end
			end

			entranceInfo["description"] = description;

			if dungeonCount > raidCount then
				entranceInfo["atlasName"] = "Dungeon";
			else
				entranceInfo["atlasName"] = "Raid";
			end

			entranceInfo["journalInstanceID"] = 0;
			entranceInfo["hub"] = 1;

			IPUIPrintDebug("Hub: " .. entranceInfo["name"]);

			return entranceInfo
		end

		local m = 1
		if IPUIInstanceMapDB[subInstanceMapIDs[m]] then
			local name = IPUIInstanceMapDB[subInstanceMapIDs[m]][1]
			local type = IPUIInstanceMapDB[subInstanceMapIDs[m]][2]
			local requiredLevel = IPUIInstanceMapDB[subInstanceMapIDs[m]][3]
			local tier = IPUIInstanceMapDB[subInstanceMapIDs[m]][4]

			entranceInfo = {};

			entranceInfo["areaPoiID"] = C_AreaPoiInfo.GetAreaPOIForMap(mapID)[0];
			entranceInfo["position"] = CreateVector2D(x, y);
			if (type == 1) then
				entranceInfo["atlasName"] = "Dungeon";
				entranceInfo["description"] = LFG_TYPE_DUNGEON;
			else
				entranceInfo["atlasName"] = "Raid";
				entranceInfo["description"] = LFG_TYPE_RAID;
			end

			EJ_SelectTier(tier)
			local instanceID = subInstanceMapIDs[m]

			local localizedName = EJ_GetInstanceInfo(instanceID);

			entranceInfo["name"] = localizedName.." |cFF888888("..requiredLevel..")|r";

			entranceInfo["journalInstanceID"] = instanceID;
			entranceInfo["tier"] = tier;
			entranceInfo["hub"] = 0;

			IPUIPrintDebug("Instance: " .. entranceInfo["name"].." id:"..instanceID);

			return entranceInfo
		end
end
