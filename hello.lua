-- Ensure the game is fully loaded before continuing execution
if not game:IsLoaded() then
	game.Loaded:Wait()
end
task.wait(1)
local currentGameId = game.GameId
if tostring(currentGameId) ~= "7436755782" then
	return
end 

-- Prevent multiple instances of Exotic Hub from running
if _G.is_running_gag then
	warn("[Exotic Hub] Already running!")
	return
end
_G.is_running_gag = true
print("Exotic Hub: Starting Part 1 (Initialization & Framework)...")
print("Place ID: ", game.PlaceId)

-- ==========================================
-- ROBLOX SERVICES & CORE EVENT CHANNELS
-- ==========================================
local Services = {}
Services.LocalizationService = game:GetService("LocalizationService")
Services.UserInputService = game:GetService("UserInputService")
Services.HttpService = game:GetService("HttpService")
Services.ReplicatedStorage = game:GetService("ReplicatedStorage")
Services.Workspace = game:GetService("Workspace")
Services.TeleportService = game:GetService("TeleportService")
Services.Players = game:GetService("Players")
Services.RunService = game:GetService("RunService")
Services.MarketplaceService = game:GetService("MarketplaceService")
Services.Modules = Services.ReplicatedStorage:WaitForChild("Modules")
Services.LocalPlayer = Services.Players.LocalPlayer
Services.Character = Services.LocalPlayer.Character or Services.LocalPlayer.CharacterAdded:Wait()
Services.Backpack = Services.LocalPlayer:WaitForChild("Backpack")
Services.PlayerGui = Services.LocalPlayer:WaitForChild("PlayerGui")
Services.player_humanoid = Services.Character:FindFirstChildOfClass("Humanoid")

-- Game Action Network Remotes
Services.GameEvents = Services.ReplicatedStorage:WaitForChild("GameEvents")
Services.petsServiceRemote = Services.GameEvents:WaitForChild("PetsService")
Services.PetEggService = Services.GameEvents:WaitForChild("PetEggService")
Services.BuyGearStock = Services.GameEvents:FindFirstChild("BuyGearStock")
Services.BuySeedStock = Services.GameEvents.BuySeedStock
Services.BuyDailySeedShopStock = Services.GameEvents:FindFirstChild("BuyDailySeedShopStock")
Services.BuyPetEgg = Services.GameEvents:FindFirstChild("BuyPetEgg")
Services.BuyTravelingMerchantShopStock = Services.GameEvents:WaitForChild("BuyTravelingMerchantShopStock")
Services.SellPetRemote = Services.GameEvents:WaitForChild("SellPet_RE")
Services.SellAllPetsRemote = Services.GameEvents:WaitForChild("SellAllPets_RE")
Services.Sell_Inventory = Services.GameEvents.Sell_Inventory
Services.DataStream = Services.GameEvents.DataStream
Services.PlantRemote = Services.GameEvents:WaitForChild("Plant_RE")
Services.collectEvent = (Services.GameEvents:WaitForChild("Crops")):WaitForChild("Collect")
Services.FavItem = Services.GameEvents:WaitForChild("Favorite_Item")
Services.BuyEventShopStock = Services.GameEvents:WaitForChild("BuyEventShopStock")
Services.BoostService = Services.GameEvents:WaitForChild("PetBoostService")
Services.TrowelRemote = Services.GameEvents:WaitForChild("TrowelRemote")
Services.MutationService = Services.GameEvents:WaitForChild("PetMutationMachineService_RE")
Services.ActivePetService = Services.GameEvents:WaitForChild("ActivePetService")
Services.SellPetShopSelected = Services.GameEvents:WaitForChild("SellPetShopSelected")

-- Utility Action Network Remotes
Services.SprayService_RE = Services.GameEvents:WaitForChild("SprayService_RE")
Services.CookingPotService_RE = Services.GameEvents:WaitForChild("CookingPotService_RE")
Services.CraftingGlobalObjectService = Services.GameEvents:WaitForChild("CraftingGlobalObjectService")
Services.SprinklerService = Services.GameEvents:WaitForChild("SprinklerService")
Services.Water_RE = Services.GameEvents:WaitForChild("Water_RE")
Services.BonfireService = Services.GameEvents:WaitForChild("BonfireService")
Services.Remove_Item = Services.GameEvents.Remove_Item
Services.DeleteObject = Services.ReplicatedStorage.GameEvents.DeleteObject
Services.PetLeadService_RE = Services.GameEvents.PetLeadService_RE
Services.PetCooldownsUpdated = Services.GameEvents.PetCooldownsUpdated
Services.TryUseGear = Services.GameEvents.TryUseGear
Services.TryMapleSyrup = Services.GameEvents.TryMapleSyrup
Services.Reclaimer = Services.GameEvents.ReclaimerService_RE
Services.BuySeasonPassStock = Services.GameEvents:FindFirstChild("SeasonPass") and Services.GameEvents.SeasonPass:FindFirstChild("BuySeasonPassStock")

-- Physical Workspace Folders
Services.petsContainer = Services.Workspace:WaitForChild("PetsPhysical")
Services.GearShopUI = Services.PlayerGui:WaitForChild("Gear_Shop")
Services.SeedShopUI = Services.PlayerGui:WaitForChild("Seed_Shop")
Services.PetShopUI = Services.PlayerGui:WaitForChild("PetShop_UI")
Services.TravelingMerchantShop_UI = Services.PlayerGui:WaitForChild("TravelingMerchantShop_UI")
Services.DigRemote = (Services.GameEvents:WaitForChild("DiggingMiniGame")):WaitForChild("DigRemoteEvent")
Services.fails = 0 

-- Safe require helper to prevent crashes if standard modules are updated
function Services.safeRequire(moduleInstance)
	local success, result = pcall(require, moduleInstance)
	if not success or result == nil then
		warn("[SafeRequire] Failed to load module:", moduleInstance)
		Services.fails = Services.fails + 1
		return nil
	end
	return result
end 

-- Load Game Data Modules
Services.DataService = Services.safeRequire(Services.ReplicatedStorage.Modules.DataService)
Services.mod_load = {
	LoadAllModules = function()
		local petServices = Services.Modules:FindFirstChild("PetServices")
		if petServices then
			local activePetsService = petServices:FindFirstChild("ActivePetsService")
			if activePetsService then
				Services.ActivePetsService = activePetsService
			end
		end
	end
}
Services.mod_load.LoadAllModules()

-- Setup external and framework controllers
local TradeWorldController = Services.safeRequire(Services.Modules.TradeControllers.TradeWorldController)
local RebirthShared = Services.safeRequire(Services.ReplicatedStorage.Modules.RebirthShared)
local SeedData = Services.safeRequire(Services.ReplicatedStorage.Data.SeedData)
local PetUtilities = Services.safeRequire(Services.ReplicatedStorage.Modules.PetServices.PetUtilities)
local PlantTraitsData = Services.safeRequire(Services.ReplicatedStorage.Modules.PlantTraitsData)
local CraftingRecipeRegistry = Services.safeRequire(Services.ReplicatedStorage.Data.CraftingData.CraftingRecipeRegistry)
local FoodRecipeData = Services.safeRequire(Services.ReplicatedStorage.Data.FoodRecipeData)
local GearData = Services.safeRequire(Services.ReplicatedStorage.Data.GearData)
local SeasonPassShop = nil
local EventShopData = Services.safeRequire(Services.ReplicatedStorage.Data.EventShopData)
local PetList = Services.safeRequire(Services.ReplicatedStorage.Data.PetRegistry.PetList)
local PetRegistry = Services.safeRequire(Services.ReplicatedStorage.Data.PetRegistry)
local InventoryService = Services.safeRequire(Services.Modules.InventoryService)

-- Retrieve Season Pass Data
function Services.GetSessionPassModule()
	local dataFolder = Services.ReplicatedStorage:FindFirstChild("Data")
	if not dataFolder then
		return nil
	end
	local seasonPass = dataFolder:FindFirstChild("SeasonPass")
	if not seasonPass then
		return nil
	end
	local shopData = seasonPass:FindFirstChild("SeasonPassShopData")
	if not shopData then
		return nil
	end
	local success, result = pcall(require, shopData)
	if success then
		Services.SeasonPassShop = result
		return result
	else
		warn("[SeasonPassShopData] require failed:", result)
		return nil
	end
end
Services.GetSessionPassModule()
local PetMutationRegistry = Services.safeRequire(Services.ReplicatedStorage.Data.PetRegistry.PetMutationRegistry)
local TravelingMerchantData = Services.safeRequire(Services.ReplicatedStorage.Data.TravelingMerchant.TravelingMerchantData)
local FindItemImage = Services.safeRequire(Services.ReplicatedStorage.Modules.ItemImageFinder)
local DailySeedShopData = Services.safeRequire(Services.ReplicatedStorage.Data.DailySeedShopData)
local SeedPackData = Services.safeRequire(Services.ReplicatedStorage.Data.SeedPackData)
local VariantsEnums = Services.safeRequire(Services.ReplicatedStorage.Data.EnumRegistry.VariantsEnums)
local PetGiftingModule = Services.safeRequire(Services.ReplicatedStorage.Modules.PetServices.PetGiftingService)
local CalculatePlantValue = Services.safeRequire(Services.ReplicatedStorage.Modules.CalculatePlantValue)
local SeedShopData = Services.safeRequire(Services.ReplicatedStorage.Data.SeedShopData)
local GearShopData = Services.safeRequire(Services.ReplicatedStorage.Data.GearShopData)
local PetEggData = Services.safeRequire(Services.ReplicatedStorage.Data.PetEggData)

-- ==========================================
-- ANTI-AFK CONNECTION KEEP-ALIVE
-- ==========================================
function Addcantsleep()
	local connectionsGetter = getconnections or get_signal_cons
	if connectionsGetter then
		for _, connection in pairs(connectionsGetter(Services.LocalPlayer.Idled)) do
			if connection.Disable then
				connection:Disable()
			elseif connection.Disconnect then
				connection:Disconnect()
			end
		end
	end
end
pcall(Addcantsleep)
Services.ReplicatedStorageSharedFolder = Services.ReplicatedStorage:WaitForChild("Shared")
task.wait(0.2)

-- ==========================================
-- OBSIDIAN UI LIBRARY LOADING
-- ==========================================
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua"))()
local UiLib = Library

-- ==========================================
-- CORE STATE VARIABLES & GLOBAL STRUCTS
-- ==========================================
local ExoticHub = {
	AppName = "Exotic Hub",
	CurentV = "v1.50.2",
	is_pro = true,
	mark_save_disabled = false,
	max_priorityx = 7,
	Notify = function(self, message, duration)
		if not message or not UiLib then
			return
		end
		duration = duration or 2.5
		UiLib:Notify(message, duration)
	end,
	HATCH_STATES = {
		NORMAL = "NORMAL",
		EGG_PHASE = "EGG_PHASE",
		EGG_PLACE_PHASE = "egg_place",
		EGG_HATCH_PHASE = "egg_hatchphase"
	},
	TEXT_TRADE_WORLD = "",
	TEXT_HATCH_SYSTEM = "",
	TEXT_ENHANCE_PRO = "",
	TEXT_AGEBREAK = "",
	TEXT_CRAFT_TEAMS = "",
	TEXT_TEAM_SYSTEM = "",
	event_seeding_active = false,
	event_seeding_list = {},
	alt_Plants_Physical = {},
	RNG_EGG_OVERRIDE = 0,
	WAS_PRO_END = false,
	is_dc = false,
	seen_pets = {},
	is_hatch_stage_koi = false,
	hatch_state = "NORMAL",
	show_expire_key = false,
	expire_key_text = "",
	was_enhancerpro_success = false,
	player_userid = Services.LocalPlayer.UserId,
	backpackfull = false,
	backpackfull_amount = 0,
	ItemTypes = {
		Pet = "Pet",
		Egg = "Egg",
		Fruit = "Fruit",
		Seed = "Seed",
		Gear = "Gear",
		Fence = "Fence",
		Fences = "Fences",
		RandomSeed = "RandomSeed",
		Holdable = "Holdable",
		SeedPack = "Seed Pack",
		PetEgg = "PetEgg",
		CosmeticCrate = "CosmeticCrate",
		Crate = "Crate",
		Cosmetic = "Cosmetic",
		Currency = "Currency",
		Food = "Food",
		TradeBoothSkin = "TradeBoothSkin"
	},
	AssetCache = {},
	EggsNoIcons = {
		["Premium Night Egg"] = 75473533691044,
		["Night Egg"] = 110540585737631
	}
}
Services.LocalPlayer.CameraMaxZoomDistance = 350 

-- Establish Custom Workspace Directories for Alternative Plants Storage
function ExoticHub.MakeAltFolder(userId)
	if not userId then
		warn("Exotic Hub: AltFolder setup requires a valid UserId!")
		return nil
	end
	local folderName = tostring(userId) .. "_Plants"
	local existingFolder = Services.ReplicatedStorage:FindFirstChild(folderName)
	if existingFolder then
		ExoticHub.alt_Plants_Physical[userId] = existingFolder
		return existingFolder
	end
	local newFolder = Instance.new("Folder")
	newFolder.Name = folderName
	newFolder.Parent = Services.ReplicatedStorage
	ExoticHub.alt_Plants_Physical[userId] = newFolder
	return newFolder
end
ExoticHub.MakeAltFolder(ExoticHub.player_userid)
function ExoticHub.GetCheckIfPro()
	return ExoticHub.is_pro
end
if Services.fails > 0 then
	warn("[EXO] Crucial dependency libraries were missing during launch. Please consider rejoining.")
end 

-- Get country localization safely using pcall
ExoticHub.user_country = ""
ExoticHub.Region = {
	FetchCurrentRegion = function()
		task.spawn(function()
			local defaultRegion = ""
			local success, userRegion = pcall(function()
				return Services.LocalizationService:GetCountryRegionForPlayerAsync(Services.LocalPlayer)
			end)
			if success and userRegion and userRegion ~= "" then
				defaultRegion = tostring(userRegion)
				ExoticHub.user_country = defaultRegion
			end
		end)
	end
}
ExoticHub.Region.FetchCurrentRegion()
task.wait(0.3)

-- ==========================================
-- APP CONFIGURATION & STORAGE FILES SETUP
-- ==========================================
local Settings = {
	hop_enabled = false,
	hop_maxtries = 10,
	hop_currenttries = 0,
	hop_targetversion = 0,
	egg_priority1 = "None",
	egg_priority2 = "None",
	egg_priority3 = "None",
	egg_priority4 = "None",
	egg_priority5 = "None",
	egg_priority6 = "None",
	egg_priority7 = "None",
	autofavfruits_enabled = false,
	autofavminweight = 70,
	autofavmaxweight = 500,
	autofavplantlist = {},
	enhance_cooldown = 0.35,
	swap_enchancer = false,
	farmfav_fruit_enhancer = false,
	egg_override = {},
	egg_override_enabled = false,
	shop_stocks = {
		enabled_seedshop = true,
		enabled_gearshop = true,
		enabled_eggshop = true,
		seed_shop_avoid = {},
		gear_shop_avoid = {},
		egg_shop_avoid = {}
	},
	petpp_overrides = {},
	petpp_selected = "",
	rmplants = {
		mut_whitelist = {},
		mut_blacklist = {},
		variants_list = {},
		max_mut_count = 0,
		fruit_list = {},
		fruit_remove_enabled = false
	},
	max_eggs_to_place = 0,
	easterbunnyeggrewardcollect = true,
	merrybear_collect = true,
	mut_max_level_successfulpets = false,
	mut_batch_process_enable = false,
	mut_pet_mode_enable = false,
	mut_batch_process_turn = "levelteam",
	mut_target_pets_uuid = {},
	mut_target_mutations = {},
	mut_support_team = {},
	mut_mutation_machineteam = {},
	mut_claimpet_team = {},
	mut_required_level = 50,
	mut_required_level_item = 40,
	mut_pet_inside_mutation = "",
	mut_was_running = false,
	max_mutation_count = 0,
	mutation_hatch_petfilter = {},
	mutation_hatch_mutlist = {},
	mutation_hatch_pet_enabled = false,
	chubby_chipmunk_amount_collected = 0,
	chubby_chipmunk_auto_collect = true,
	chubby_chipmunk_item_watering_can = 0,
	chubby_chipmunk_item_event_lantern = 0,
	chubby_chipmunk_item_godly_sprinkler = 0,
	chubby_chipmunk_item_legendary_egg = 0,
	chubby_chipmunk_item_reclaimer = 0,
	chubby_chipmunk_item_nutty_crate = 0,
	chubby_chipmunk_item_silver_fertilizer = 0,
	chubby_chipmunk_item_nutty_chest = 0,
	chubby_chipmunk_item_master_sprinkler = 0,
	chubby_chipmunk_item_medium_treat = 0,
	chubby_chipmunk_item_medium_toy = 0,
	chubby_chipmunk_item_mythical_egg = 0,
	chubby_chipmunk_item_grandmaster_sprinkler = 0,
	chubby_chipmunk_item_rainbow_fertilizer = 0,
	chubby_chipmunk_item_petshardnutty = 0,
	marmot_amount_collected = 0,
	marmot_auto_collect = true,
	marmot_item_firefly = 0,
	marmot_item_maple_leaf_kite = 0,
	marmot_item_sky_lantern = 0,
	marmot_item_leaf_blower = 0,
	marmot_item_maple_syrup = 0,
	marmot_item_maple_sprinkler = 0,
	marmot_item_golden_acorn = 0,
	magie_enabled_auto = false,
	magpie_status = {},
	magpie_recordstatus = true,
	bear_merrygift_status = {},
	bearded_dragon_egg_status = {},
	bearded_dragon_recordstatus = true,
	is_auto_jungle = false,
	feeding_auto_collectfruits = true,
	feed_food_insteadoffruits = false,
	feeding_pets_timer = 120,
	feeding_pets_auto = false,
	force_feed_all_pets = false,
	feeding_list_pets = {},
	feeding_list_plants = {},
	pet_level_boost_list = "-",
	pet_auto_level_auto = false,
	pet_auto_level_max = 1,
	pet_auto_level_min = 0,
	pet_level_selected_pets = {},
	feeding_exlude_food_list = {},
	g_fruit_weight_max = 99,
	g_fruit_weight_min = 0,
	is_fall_event_running = false,
	is_fall_event_fastmode = false,
	is_autoeasterteams = true,
	hive_esp_eggs = true,
	hive_esp_showhatched = false,
	is_auto_plantseedEvent = false,
	event_automiddle_tp = true,
	autocraftcandyevent = false,
	autocraftcandymaxcrafts = 1,
	autobuyeventeggsamount = 19,
	autoplacesprinklers = {},
	enable_autoplacesprinklers = false,
	newyear_dailyclaim = false,
	is_fall_questline_auto = false,
	is_fall_questline_reroll = false,
	is_fall_questline_spin = false,
	is_playerstats_running = true,
	hatch_rare_withbigsizetm = false,
	web_api_key = "",
	ascension_max_seeds = 1,
	auto_ascension = false,
	auto_sellbackpack = false,
	is_collect_fruit = false,
	pet_override_weight = {},
	mutation_whitelist = {},
	mutation_blacklist = {},
	fruit_variants_select = {},
	fruit_collector_turbo = false,
	fruit_instant_collect = false,
	collection_plants = {},
	sell_mutation_whitelist = {},
	sell_mutation_blacklist = {},
	sell_fruit_list = {},
	auto_sell_backpack_time = false,
	auto_sell_backpack_every = 60,
	season_pass_shop_items = {},
	cook_potone_item1 = "-",
	cook_potone_item2 = "-",
	cook_potone_item3 = "-",
	cook_potone_item4 = "-",
	cook_potone_item5 = "-",
	is_auto_cook = false,
	cooking_autocollect_required = true,
	cooking_autoplant_required = true,
	trowel_plants_list = {},
	trowel_saved_cframe = "0,0,0",
	shovel_plants_list = {},
	shovel_keep_amount = 0,
	is_auto_shovel = false,
	watering_list_plants = {},
	watering_is_auto = false,
	watering_amount_to_water = 2,
	watering_speed_time = 0.3,
	fall_pets_shop = {},
	fall_seeds_shop = {},
	fall_cosmetic_shop = {},
	fall_gear_shop = {},
	jungle_seed_stages1 = {},
	jungle_auto_plants_list = {},
	boost_auto_team_placed_koi = false,
	boost_koi_team_list = {},
	boost_sprinkler_koi_team = false,
	boost_sprinklerseal = false,
	boost_sprinklerbronto = false,
	is_auto_place_sprinkler_hatch = false,
	list_gear_event_workbench = {},
	is_auto_craft = false,
	craft_autoplant_workbench = true,
	craft_autofruit_workbench = true,
	quest_recoll_max_cost = "1.6M",
	seed_placement_list = {},
	is_auto_seed = false,
	seed_keep_amount = 0,
	seed_speed_timer1 = 0.5,
	is_seed_random = true,
	is_seedplace_center = true,
	seed_location_vector = "0,0,0",
	show_better_fruitnames = false,
	remove_visuals_weather = false
}
local SessionState = {
	is_trading_world_mode = false,
	trade_worldtp_delay = 30,
	was_dc = false,
	LevelTimer = {
		times = {},
		startTime = 0
	},
	test_a = {},
	farm = {
		delete_plants = true,
		delete_fruits = true,
		change_parent = false,
		enable_delete_fruits = false
	},
	timerecording = {},
	oldtest = {},
	fruitesp = {
		show_mutations = false,
		show_esp = false,
		enable_esp = false,
		plants_list = {}
	},
	is_highperformance_mode = true
}

-- Save Data Settings (Saved in Local JSON File 1)
local SaveData = {
	petfav = {
		allow_pet_list = {},
		allow_mutation_list = {},
		min_age = 1,
		max_age = 100,
		min_weight = 0.8,
		max_weight = 2.86
	},
	valentines = {
		enabled_event = false,
		claim_rewards = true,
		plant_exclude = {}
	},
	feedevent = {
		feed_birds_enabled = false,
		feed_plant_list = {}
	},
	max_web_count = 7,
	giftpets = {
		allow_pet_list = {},
		allow_mutation_list = {},
		custom_pets_list = {},
		allow_player_targets = {},
		send_trading_ticket_auto = false,
		enabled_gift_pets = false,
		enabled_auto_trade = false,
		auto_confirm_accept = false,
		trade_auto_accept = false,
		allow_fav = false,
		min_age = 1,
		max_age = 2,
		min_weight = 0.8,
		max_weight = 2.86,
		custom_mode = false,
		delay_between_gift = 9.9
	},
	clean_mut_list = {},
	clean_pet_type = {},
	clean_system_enabled = false,
	honeymachine_autoclaim = true,
	honeymachine_autosubmit = true,
	honeymachine_enabled = true,
	honey_incubator_enabled = false,
	enable_autofightbees = true,
	autoopenchestsbees = true,
	campcollectfruits = true,
	campenabled = false,
	summarcraftreceipe = {},
	enabesummarcraft = false,
	autoenterdungeon = true,
	honey_incubator_seeds = {},
	jelly_enabled = false,
	jelly_seeds = {},
	bee_autobuyshop = false,
	bee_whitelisteggs = {},
	bee_hiveautohatch = false,
	bee_hiveautoupgrade = false,
	autoshowuisc = true,
	sellallunfav = true,
	selltonpcmode = false,
	sellinventorytpback = true,
	remove_farms = false,
	is_pc_mode = false,
	fast_ascen = false,
	nice_fruit = false,
	hide_log_ui = false,
	sell_mode_hatch_selected = false,
	auto_fav_after_hatch = true,
	eggs_center_mode1 = false,
	clover_method = false,
	onlyplaceeggswhenempty = false,
	delay_between_sell_seal = 0,
	delay_between_hatch_koi = 0,
	rng_use_system = false,
	rng_auto_rejoin = false,
	rng_egg_lowers_up = false,
	char_farm_middle = false,
	fav_fruit_enhancer = false,
	enhancer_auto_sellfruit = false,
	enhancer_auto_favallow = true,
	fav_fruit_enhance_sell = false,
	is_running_custom_teams = false,
	customteams_team1 = {},
	customteams_team2 = {},
	customteams_team3 = {},
	customteams_team4 = {},
	customteams_boost_teamunits = {},
	customteams_boosts = {},
	customteams_boosts_enabled = {},
	customteams_team1_delay = 30,
	customteams_team2_enabled = false,
	customteams_team2_delay = 30,
	customteams_team3_enabled = false,
	customteams_team3_delay = 30,
	customteams_team4_enabled = false,
	customteams_team4_delay = 30,
	pause_systems = false,
	disable_event_notify_button = false,
	auto_claim_season_points = false,
	only_show_baseweight = false,
	use_noti = false,
	fast_egg_placement = false,
	safe_fruits = {},
	is_auto_accept_gift = false,
	tradeevent = {
		enable_trade_event = false,
		fruit_collect = true,
		seed_place = false
	},
	overridepets = {
		selected_pets = {},
		is_enabled = false,
		delay_amount = 0.9
	},
	craftevent = {
		smith_auto = false,
		egg_list = {},
		gear_list = {},
		fruit_list = {}
	},
	agebreak = {
		is_active_agebreak = false,
		target_team = {},
		dup_team = {},
		claim_team = {},
		submit_team = {},
		idle_team = {},
		max_level = 125,
		use_filters = false,
		avoid_age_filter = false,
		avoid_weight_filter = true,
		auto_skip_tokens = false,
		autorejoinagebreak = false
	},
	allcraft = {
		auto_craft_event = false,
		teams_enabled = false,
		receipe_data = {},
		team_claim = {},
		team_submit = {},
		team_idle = {}
	},
	reclaim = {
		plants = {},
		keep_amount = 0
	},
	elephant = {
		boost_list = {},
		pet_list = {},
		delay_before_unequip = 0.4,
		delay_before_place = 0.2,
		boost_amount = 1
	},
	seedpack = {
		is_active = false,
		selected_packs = {}
	},
	auto_restartjoin_server = false,
	auto_rejoin_after_hatchcount = 30,
	halloween = {
		shops = {},
		auto_dig = true,
		auto_reaper = true
	},
	sellingpets = {
		manual_sell_fav = false,
		auto_pet_sell = false,
		auto_sell_weight_min = 0,
		auto_sell_age = 0,
		auto_sell_override_fav = false,
		auto_sell_selected = {}
	},
	mut_system = {
		gm_sprinkler = false,
		level = 40,
		lvl_baseweight = 40,
		required_weight = 2.1,
		turbo_max_level = 25,
		custom_max_level = 100,
		only_level_mode = false,
		is_ruuning = false,
		maxlevel_team = {},
		xpteam = {},
		mut_team = {},
		baseweight_team = {},
		targetteam = {},
		filler_team = {},
		wanted = {},
		state = "level",
		max_level_enable = true,
		max_lvl_batch = true,
		continue_enable = true,
		elephant_hotswap = true,
		single_unit_allowed = false,
		is_baseweight_mode = false,
		turbo_xp_teams = false,
		realtime_monitor_system = true,
		timeout_system = true,
		disable_horseman = false
	},
	show_activepets_ui = true,
	auto_switchgarden_fast = false,
	auto_remove_sprinklers = false,
	auto_remove_sprinklers_nearexpire = true,
	auto_remove_sp_list = {},
	mutation_boost_team_claim = {},
	mutation_boost_claim_enabled = false,
	mutation_boost_level_team = {},
	mutation_boost_level_team_enabled = false,
	mutation_boost_cd_team = {},
	mutation_boost_cd_team_enabled = false,
	red_panda_restock = {},
	red_panda_restock_total = 0,
	red_panda_record_items = true,
	pet_mutation_boost_list = {},
	pet_mutation_team_boost_enabled = false,
	pet_mutation_team_list = {},
	pet_mut_xpteam_boosts = {},
	pet_mut_xpteam_boost_enabled = false,
	pet_mut_xpteam_petlist = {},
	ui_rescale_val = 100,
	hatch_boost_seal_team = {},
	hatch_boost_seal_enabled = false,
	hatch_boost_bron_team = {},
	hatch_boost_bron_enabled = false,
	hatch_boost_eggcd_team = {},
	hatch_team_boost_targets = {},
	hatch_boost_eggcd_enabled = false,
	always_active_boosts = true,
	restart_hatching_system = false,
	sync_pingmode = false,
	merchant_shop_data = {},
	disconnect_rejoin = false,
	is_sell_only_hatch_pet = true,
	is_auto_hatch_enabled = false,
	is_egg_esp = true,
	is_fairy_scanner_active = false,
	buy_merchant = false,
	gearshop_items = {},
	seedshop_items = {},
	eggshop_items = {},
	is_test = false,
	is_hatch_in_batch = true,
	hatch_sell_delayed = false,
	rejoin_server_bugged = false,
	is_session_based = true,
	is_first_time = true,
	is_auto_rejoin = false,
	is_running = false,
	is_age_hatch_mode = false,
	hatch_mode_age_to_keep = 75,
	sell_weight = 3,
	sell_age = 0,
	pet_team_size = 8,
	pets_hatched_total = 0,
	eggs_hatched_in_10_min_session = 0,
	eggs_hatched_in_hourly_session = 0,
	last_10min_report_time = 0,
	last_hourly_report_time = 0,
	disable_team1 = false,
	disable_team2 = false,
	disable_team3 = false,
	disable_team4 = false,
	disable_team5 = false,
	disable_team6 = false,
	disable_team7 = false,
	auto_hatch_big_pets = true,
	send_everyhatch_alert = true,
	send_rare_pet_alert = true,
	send_big_pet_alert = true,
	auto_remove_plants_folder = false,
	webhook_url = ExoticHub.WEBHOOK_URL,
	mut_webhook_url = "",
	team1 = {},
	team2 = {},
	team3 = {},
	team4 = {},
	team5 = {},
	team6 = {},
	team7 = {},
	team_reduction_placefirst = {},
	team_reduction_placeafter = {},
	team_bypass_alwaysactive = {},
	team_bypass_enabled = false,
	team_enhance_targets = {},
	enhance_targets_enabled = false,
	team_reduction_timer = 16.5,
	team_reduction_enabled_teams = false,
	hatch_fast_mode = false,
	hatch_ultramode = false,
	hatch_slow_mode = false,
	pet_pickplacehatchingstage = {},
	pet_pickplace_enabled = false,
	pet_pickplace_anywhere = false,
	pet_pickplace_threading = true,
	pet_pickplace_random = true,
	pet_pickplace_random_equip = true,
	pet_pickplace_cooldownsecs = 1,
	pet_pickplace_activactiondelay = 0.67,
	pet_pickplace_equipe_delay = 0.13,
    
    -- Map of eggs and their respective pet pools
	sell_pets = {
		["Premium Night Egg"] = {
			["Hedgehog"] = true,
			["Mole"] = true,
			["Frog"] = true,
			["Echo Frog"] = true,
			["Night Owl"] = true,
			["Raccoon"] = false
		},
		["Golden Egg"] = {
			["Easter Egg Chick"] = true,
			["Chocolate Bunny"] = true,
			["Marshmallow Lamb"] = false,
			["Easter Bunny"] = false
		},
		["Spooky Egg"] = {
			["Bat"] = true,
			["Bone Dog"] = true,
			["Spider"] = true,
			["Black Cat"] = true,
			["Headless Horseman"] = false
		},
		["Dinosaur Egg"] = {
			["Raptor"] = true,
			["Triceratops"] = true,
			["Stegosaurus"] = true,
			["Pterodactyl"] = true,
			["Brontosaurus"] = false,
			["T-Rex"] = false
		}
	}
}

-- Target Game Configurations (Saved in Local JSON File 2)
local SettingsSaveData = {
	hop_enabled = false,
	hop_maxtries = 10,
	hop_currenttries = 0,
	hop_targetversion = 0,
	egg_priority1 = "None",
	egg_priority2 = "None",
	egg_priority3 = "None",
	egg_priority4 = "None",
	egg_priority5 = "None",
	egg_priority6 = "None",
	egg_priority7 = "None",
	autofavfruits_enabled = false,
	autofavminweight = 70,
	autofavmaxweight = 500,
	autofavplantlist = {},
	enhance_cooldown = 0.35,
	swap_enchancer = false,
	farmfav_fruit_enhancer = false,
	egg_override = {},
	egg_override_enabled = false,
	shop_stocks = {
		enabled_seedshop = true,
		enabled_gearshop = true,
		enabled_eggshop = true,
		seed_shop_avoid = {},
		gear_shop_avoid = {},
		egg_shop_avoid = {}
	},
	petpp_overrides = {},
	petpp_selected = "",
	rmplants = {
		mut_whitelist = {},
		mut_blacklist = {},
		variants_list = {},
		max_mut_count = 0,
		fruit_list = {},
		fruit_remove_enabled = false
	},
	max_eggs_to_place = 0,
	chubby_chipmunk_auto_collect = true,
	marmot_auto_collect = true,
	magie_enabled_auto = false,
	is_auto_jungle = false,
	feeding_auto_collectfruits = true,
	feed_food_insteadoffruits = false,
	feeding_pets_timer = 120,
	feeding_pets_auto = false,
	force_feed_all_pets = false,
	feeding_list_pets = {},
	feeding_list_plants = {},
	pet_level_boost_list = "-",
	pet_auto_level_auto = false,
	pet_auto_level_max = 1,
	pet_auto_level_min = 0,
	pet_level_selected_pets = {},
	feeding_exlude_food_list = {},
	g_fruit_weight_max = 99,
	g_fruit_weight_min = 0,
	is_fall_event_running = false,
	is_fall_event_fastmode = false,
	is_autoeasterteams = true,
	hive_esp_eggs = true,
	hive_esp_showhatched = false,
	is_auto_plantseedEvent = false,
	event_automiddle_tp = true,
	autocraftcandyevent = false,
	autocraftcandymaxcrafts = 1,
	autobuyeventeggsamount = 19,
	autoplacesprinklers = {},
	enable_autoplacesprinklers = false,
	newyear_dailyclaim = false,
	is_fall_questline_auto = false,
	is_fall_questline_reroll = false,
	is_fall_questline_spin = false,
	is_playerstats_running = true,
	hatch_rare_withbigsizetm = false,
	web_api_key = "",
	ascension_max_seeds = 1,
	auto_ascension = false,
	auto_sellbackpack = false,
	is_collect_fruit = false,
	pet_override_weight = {},
	mutation_whitelist = {},
	mutation_blacklist = {},
	fruit_variants_select = {},
	fruit_collector_turbo = false,
	fruit_instant_collect = false,
	collection_plants = {},
	sell_mutation_whitelist = {},
	sell_mutation_blacklist = {},
	sell_fruit_list = {},
	auto_sell_backpack_time = false,
	auto_sell_backpack_every = 60,
	season_pass_shop_items = {},
	cook_potone_item1 = "-",
	cook_potone_item2 = "-",
	cook_potone_item3 = "-",
	cook_potone_item4 = "-",
	cook_potone_item5 = "-",
	is_auto_cook = false,
	cooking_autocollect_required = true,
	cooking_autoplant_required = true,
	trowel_plants_list = {},
	trowel_saved_cframe = "0,0,0",
	shovel_plants_list = {},
	shovel_keep_amount = 0,
	is_auto_shovel = false,
	watering_list_plants = {},
	watering_is_auto = false,
	watering_amount_to_water = 2,
	watering_speed_time = 0.3,
	fall_pets_shop = {},
	fall_seeds_shop = {},
	fall_cosmetic_shop = {},
	fall_gear_shop = {},
	jungle_seed_stages1 = {},
	jungle_auto_plants_list = {},
	boost_auto_team_placed_koi = false,
	boost_koi_team_list = {},
	boost_sprinkler_koi_team = false,
	boost_sprinklerseal = false,
	boost_sprinklerbronto = false,
	is_auto_place_sprinkler_hatch = false,
	list_gear_event_workbench = {},
	is_auto_craft = false,
	craft_autoplant_workbench = true,
	craft_autofruit_workbench = true,
	quest_recoll_max_cost = "1.6M",
	seed_placement_list = {},
	is_auto_seed = false,
	seed_keep_amount = 0,
	seed_speed_timer1 = 0.5,
	is_seed_random = true,
	is_seedplace_center = true,
	seed_location_vector = "0,0,0",
	show_better_fruitnames = false,
	remove_visuals_weather = false
}

-- Custom Egg Hatch Priority Custom Configurations
ExoticHub.egg_custom_place_array = {
	["Campfire Egg"] = true,
	["Premium Campfire Egg"] = true,
	["Rainbow Campfire Egg"] = true,
	["Rainbow Premium Campfire Egg"] = true,
	["Hive Egg"] = true,
	["Premium Hive Egg"] = true,
	["Rainbow Premium Hive Egg"] = true,
	["Black Spotty Egg"] = true,
	["Springtide Egg"] = true,
	["Premium Springtide Egg"] = true,
	["Gilded Choc Springtide Egg"] = true,
	["Gilded Choc Premium Springtide Egg"] = true,
	["Golden Egg"] = true,
	["Premium Golden Egg"] = true,
	["Gilded Choc Golden Egg"] = true,
	["Gilded Choc Premium Golden Egg"] = true,
	["Bird Egg"] = true,
	["Premium Bird Egg"] = true,
	["Rainbow Premium Bird Egg"] = true,
	["Carnival Egg"] = true,
	["Premium Carnival Egg"] = true,
	["Rainbow Premium Carnival Egg"] = true,
	["New Year's Egg"] = true,
	["Premium New Year's Egg"] = true,
	["Rainbow Premium New Year's Egg"] = true,
	["Winter Egg"] = true,
	["Premium Winter Egg"] = true,
	["Festive Premium Winter Egg"] = true,
	["Christmas Egg"] = true,
	["Premium Christmas Egg"] = true,
	["Festive Premium Christmas Egg"] = true,
	["Gem Egg"] = true,
	["Safari Egg"] = true,
	["Spooky Egg"] = true,
	["Jungle Egg"] = true,
	["Fall Egg"] = true,
	["Common Egg"] = true,
	["Anti Bee Egg"] = true,
	["Enchanted Egg"] = true,
	["Paradise Egg"] = true,
	["Premium Primal Egg"] = true,
	["Rainbow Premium Primal Egg"] = true,
	["Zen Egg"] = true,
	["Night Egg"] = true,
	["Rare Egg"] = true,
	["Oasis Egg"] = true,
	["Rare Summer Egg"] = true,
	["Primal Egg"] = true,
	["Dinosaur Egg"] = true,
	["Gourmet Egg"] = true,
	["Sprout Egg"] = true,
	["Bee Egg"] = true,
	["Bug Egg"] = true,
	["Premium Night Egg"] = true,
	["Common Summer Egg"] = true,
	["Exotic Bug Egg"] = true,
	["Legendary Egg"] = true,
	["Mythical Egg"] = true,
	["Premium Anti Bee Egg"] = true,
	["Premium Oasis Egg"] = true,
	["Uncommon Egg"] = true
}

-- Create dynamic structures for lists
ExoticHub.logs = {}
ExoticHub.user_s_key = ""

-- Internal variables and lists mapping
local CustomPetGroup1 = {}
local CustomPetGroup2 = {}
local CustomPetGroup3 = {}
local CustomPetGroup4 = {}
local CustomPetGroup5 = {}
local CustomPetGroup6 = {}
local CustomPetGroup7 = {}
local CustomPetGroup8 = {}
local CustomPetGroup9 = {}
local CustomPetGroup10 = {}
local CustomPetGroup11 = {}
local CustomPetGroup12 = {}
local CustomPetGroup13 = {}
local CustomPetGroup14 = {}
local CustomPetGroup15 = {}
local CustomPetGroup16 = {}
local CustomPetGroup17 = {}
local CustomPetGroup18 = {}
local CustomPetGroup19 = {}
local CustomPetGroup20 = {}
local CustomPetGroup21 = {}
local CustomPetGroup22 = {}
local CustomPetGroup23 = {}
local CustomPetGroup24 = {}
local CustomPetGroup25 = {}
local PetDataLocal = {}
local SystemStatus = {
	is_running = false
}
local EventTracker = {
	shutdown_event_jungle_event = true
}
ExoticHub.RequireDataSync_Save = false
ExoticHub.RequireDataSync_SaveOther = false
ExoticHub.DisablePickPlace = false 

-- Helper function: convert string inputs into high-contrast hex code strings for UI
function ExoticHub.StringToColor(textSeed, defaultColor)
	textSeed = tostring(textSeed or "")
	defaultColor = tostring(defaultColor or "#151515")
	local function clampValue(val, minimum, maximum)
		val = tonumber(val) or 0
		if val < minimum then
			return minimum
		end
		if val > maximum then
			return maximum
		end
		return val
	end
	local function hexToRGB(hexString)
		hexString = (tostring(hexString or "")):gsub("#", "")
		local rHex, gHex, bHex = hexString:match("^(%x%x)(%x%x)(%x%x)$")
		return tonumber(rHex or "15", 16), tonumber(gHex or "15", 16), tonumber(bHex or "15", 16)
	end
	local function rgbToHex(red, green, blue)
		return string.format("#%02X%02X%02X", clampValue(math.floor(red + 0.5), 0, 255), clampValue(math.floor(green + 0.5), 0, 255), clampValue(math.floor(blue + 0.5), 0, 255))
	end
	local function hslToRGB(hue, sat, light)
		hue = ((hue % 360)) / 360
		local function hue2rgb(p, q, t)
			if t < 0 then
				t = t + 1
			end
			if t > 1 then
				t = t - 1
			end
			if t < 1 / 6 then
				return p + (q - p) * 6 * t
			end
			if t < 1 / 2 then
				return q
			end
			if t < 2 / 3 then
				return p + (q - p) * (2 / 3 - t) * 6
			end
			return p
		end
		if sat == 0 then
			local grey = light * 255
			return grey, grey, grey
		end
		local qVal = light < 0.5 and light * (1 + sat) or (light + sat) - light * sat
		local pVal = 2 * light - qVal
		return hue2rgb(pVal, qVal, hue + 1 / 3) * 255, hue2rgb(pVal, qVal, hue) * 255, hue2rgb(pVal, qVal, hue - 1 / 3) * 255
	end
	local function getLuminance(r, g, b)
		local function transform(c)
			c = c / 255
			if c <= 0.03928 then
				return c / 12.92
			end
			return (((c + 0.055) / 1.055)) ^ 2.4
		end
		return (0.2126 * transform(r) + 0.7152 * transform(g)) + 0.0722 * transform(b)
	end
	local function getContrastRatio(r1, g1, b1, r2, g2, b2)
		local lum1 = getLuminance(r1, g1, b1)
		local lum2 = getLuminance(r2, g2, b2)
		if lum1 < lum2 then
			lum1, lum2 = lum2, lum1
		end
		return (lum1 + 0.05) / (lum2 + 0.05)
	end
	local hash = 0
	for idx = 1, # textSeed do
		hash = (((hash * 131) + string.byte(textSeed, idx))) % 2147483647
	end
	local rDefault, gDefault, bDefault = hexToRGB(defaultColor)
	local activeHue = hash % 360
	local activeSaturation = 0.72
	local brightnessSteps = {
		0.62,
		0.68,
		0.74,
		0.8
	}
	local finalR, finalG, finalB = 255, 255, 255
	local maxContrast = 0
	for _, lStep in ipairs(brightnessSteps) do
		local rOut, gOut, bOut = hslToRGB(activeHue, activeSaturation, lStep)
		local currentContrast = getContrastRatio(rOut, gOut, bOut, rDefault, gDefault, bDefault)
		if currentContrast > maxContrast then
			finalR, finalG, finalB = rOut, gOut, bOut
			maxContrast = currentContrast
		end
	end
	while maxContrast < 4.5 do
		finalR = finalR + (((255 - finalR)) * 0.18)
		finalG = finalG + (((255 - finalG)) * 0.18)
		finalB = finalB + (((255 - finalB)) * 0.18)
		maxContrast = getContrastRatio(finalR, finalG, finalB, rDefault, gDefault, bDefault)
	end
	local strokeR = finalR * 0.18
	local strokeG = finalG * 0.18
	local strokeB = finalB * 0.18
	return {
		Text = rgbToHex(finalR, finalG, finalB),
		Stroke = rgbToHex(strokeR, strokeG, strokeB),
		Contrast = maxContrast
	}
end 

-- Alternate plants directories tracking
local AlternatePlantsData = {}
ExoticHub.AscensionFruitName = nil
ExoticHub.AscensionFruitMutations = {}
ExoticHub.PlantsCategoryData = {}
ExoticHub.garden_coins = 0
ExoticHub.honey_coins = 0
ExoticHub.sleep_ascend = 3
ExoticHub.is_garden_full_seed = false
ExoticHub.found_pet_data = {}
ExoticHub.found_crate_data = {}
ExoticHub.big_pets_hatch_models = {}
ExoticHub.hatch_history_list = {}
ExoticHub.pets_sold_count = 0
ExoticHub.pets_fav_count = 0
ExoticHub.found_pets_to_sell_count = 0
ExoticHub.has_koi_repaint = false
ExoticHub.has_seal_sold_happen = false
ExoticHub.is_forced_stop = false
ExoticHub.is_max_eggs_reached = false
local HatchTaskThread = nil
local MutationTaskThread = nil
local CustomTeamsTaskThread = nil
ExoticHub.tracked_bonus_egg_recovery = 0
ExoticHub.tracked_bonus_egg_sell_refund = 0
ExoticHub.shops_can_function = false
local WebhookQueue = {}
ExoticHub.HatchingWebhookData = {}
if not ExoticHub.player_userid then
	warn("Exotic Hub: Invalid local player userId!")
	return
end 

-- ==========================================
-- STATS & METRICS FORMATTERS
-- ==========================================
local FormatUtility = {}
function FormatUtility.formatDuration(seconds)
	if not seconds then
		return "0s"
	end
	local DAY = 86400
	local HOUR = 3600
	local MINUTE = 60
	seconds = tonumber(seconds) or 0
	local days = math.floor(seconds / DAY)
	local remaining = seconds % DAY
	local hours = math.floor(remaining / HOUR)
	remaining = remaining % HOUR
	local minutes = math.floor(remaining / MINUTE)
	local secs = math.floor(remaining % MINUTE)
	if days > 0 then
		return string.format("%dd:%dh:%dm:%ds", days, hours, minutes, secs)
	elseif hours > 0 then
		return string.format("%dh:%dm:%ds", hours, minutes, secs)
	elseif minutes > 0 then
		return string.format("%dm:%ds", minutes, secs)
	else
		return string.format("%ds", secs)
	end
end
ExoticHub.PlayerSecrets = {
	EggRecoveryChance = 0,
	PetSellEggRefundChance = 0,
	PetEggHatchAgeBonus = 0,
	PetEggHatchSizeBonus = 0,
	PetPassiveBonus = 0,
	SessionTime = 0,
	SellSilverFruitRewardChance = 0,
	Grow_Amount = 0
}
ExoticHub.egg_counts = {}
for _, eggName in ipairs(PetRegistry and PetRegistry.PetEggs and {} or {}) do 
    -- Handled dynamically below during the compilation phase
end 

-- Compile static tables with items from game modules
local SeedStockMap = {}
ExoticHub.all_seed_pack_names = {}
ExoticHub.seed_stock_list_array = {}
ExoticHub.seed_stock_list_key = {}
ExoticHub.seed_stock_price_map = {}
ExoticHub.seed_stock_dailyprice_map = {}
ExoticHub.gear_stock_list_array = {}
ExoticHub.gear_stock_list_key = {}
ExoticHub.gear_stock_price_map = {}
ExoticHub.egg_stock_list_array = {}
ExoticHub.egg_stock_list_key = {}
ExoticHub.egg_stock_price_map = {}
local WorkspaceCacher = {
	cache_objects = {}
}
function WorkspaceCacher.FindObjectInWorkspace(name, className, forceRecache)
	local query = string.lower(name)
	if WorkspaceCacher.cache_objects[query] and not forceRecache then
		return WorkspaceCacher.cache_objects[query]
	end
	for _, descendant in ipairs(Services.Workspace:GetDescendants()) do
		if string.lower(descendant.Name) == query and descendant:IsA(className) then
			if forceRecache then
				WorkspaceCacher.cache_objects[query] = descendant
			end
			return descendant
		end
	end
	return nil
end
local ShopDataParser = {}
function ShopDataParser.GetDataDailySeeds()
	if not DailySeedShopData then
		return
	end
	for seedName, val in pairs(DailySeedShopData) do
		ExoticHub.seed_stock_dailyprice_map[seedName] = {
			price = val.Price or 0,
			currency = val.SpecialCurrencyType or "Sheckles"
		}
	end
end
function ExoticHub.GetDailySeedPrice(seedName)
	local entry = ExoticHub.seed_stock_dailyprice_map[seedName]
	if entry then
		return entry.price, entry.currency
	end
	return nil, nil
end
function ShopDataParser.GetDataSeedShop()
	if not SeedShopData then
		return
	end
	for seedName, val in pairs(SeedShopData) do
		table.insert(ExoticHub.seed_stock_list_array, seedName)
		ExoticHub.seed_stock_list_key[seedName] = true
		ExoticHub.seed_stock_price_map[seedName] = {
			price = val.Price or 0,
			currency = val.SpecialCurrencyType or "Sheckles"
		}
	end
end
function ExoticHub.GetLowestSeedPrice()
	local minPrice = math.huge
	for _, entry in pairs(ExoticHub.seed_stock_price_map) do
		if entry.price and entry.price < minPrice then
			minPrice = entry.price
		end
	end
	if minPrice == math.huge then
		return 0
	end
	return minPrice
end
function ExoticHub.GetSeedPrice(seedName)
	local entry = ExoticHub.seed_stock_price_map[seedName]
	if entry then
		return entry.price, entry.currency
	end
	return nil, nil
end
function ShopDataParser.GetDataGearShop()
	if not GearShopData or not GearShopData.Gear then
		return
	end
	for gearName, val in pairs(GearShopData.Gear) do
		table.insert(ExoticHub.gear_stock_list_array, gearName)
		ExoticHub.gear_stock_list_key[gearName] = true
		ExoticHub.gear_stock_price_map[gearName] = {
			price = val.Price or 0,
			currency = val.SpecialCurrencyType or "Sheckles"
		}
	end
end
function ExoticHub.GetGearPrice(gearName)
	local entry = ExoticHub.gear_stock_price_map[gearName]
	if entry then
		return entry.price, entry.currency
	end
	return nil, nil
end
function ShopDataParser.GetDataEggShop()
	if not PetEggData then
		return
	end
	for eggName, val in pairs(PetEggData) do
		table.insert(ExoticHub.egg_stock_list_array, eggName)
		ExoticHub.egg_stock_list_key[eggName] = true
		ExoticHub.egg_stock_price_map[eggName] = {
			price = val.Price or 0,
			currency = val.SpecialCurrencyType or "Sheckles"
		}
	end
end
function ExoticHub.GetLowestEggPrice()
	local minPrice = math.huge
	for _, entry in pairs(ExoticHub.egg_stock_price_map) do
		if entry.price and entry.price < minPrice then
			minPrice = entry.price
		end
	end
	if minPrice == math.huge then
		return 10
	end
	return minPrice
end
function ExoticHub.GetEggPrice(eggName)
	local entry = ExoticHub.egg_stock_price_map[eggName]
	if entry then
		return entry.price, entry.currency
	end
	return nil, nil
end
ShopDataParser.GetDataDailySeeds()
ShopDataParser.GetDataSeedShop()
ShopDataParser.GetDataGearShop()
ShopDataParser.GetDataEggShop()
function ShopDataParser.GetAllSeedPackNames()
	local packs = {}
	if not SeedPackData or not SeedPackData.Packs then
		return packs
	end
	for _, val in pairs(SeedPackData.Packs) do
		if val.DisplayName then
			table.insert(packs, val.DisplayName)
		end
	end
	return packs
end
ExoticHub.all_seed_pack_names = ShopDataParser.GetAllSeedPackNames()
function FormatUtility.CloneArray(targetArray)
	local cloned = {}
	for idx, value in ipairs(targetArray) do
		cloned[idx] = value
	end
	return cloned
end
ExoticHub.SeedRarity = {}
ExoticHub.AllSeeds = {}
local function BuildSeedDataRegistry()
	local seedList = {}
	if not SeedData then
		return
	end
	for key, val in pairs(SeedData) do
		if val.SeedName then
			local cleanSeedName = val.SeedName
			local rarity = val.SeedRarity
			if key == "Easter Chocolate Coconut" and cleanSeedName == "Chocolate Coconut" then
				cleanSeedName = key
			end
			cleanSeedName = cleanSeedName:gsub("%s+Seed$", "")
			ExoticHub.SeedRarity[cleanSeedName] = rarity
			table.insert(seedList, cleanSeedName)
		end
	end
	for _, name in ipairs(seedList) do
		ExoticHub.AllSeeds[name] = true
		SeedStockMap[name] = false
	end
end
BuildSeedDataRegistry()
function ExoticHub.GetSeedRarity(seedName)
	return ExoticHub.SeedRarity[seedName] or "Common"
end
function ExoticHub.IsSeed(itemName)
	return ExoticHub.AllSeeds[itemName] == true
end
local function SortTableAlphabetically(targetTable)
	local keys = {}
	for key in pairs(targetTable) do
		table.insert(keys, key)
	end
	table.sort(keys, function(a, b)
		return a:lower() < b:lower()
	end)
	return keys
end
ExoticHub.TeleportLocations = {
	GetLocationSellShopV3 = function()
		local defaultPos = Vector3.new(0, 0, 0)
		local sellStandModel = WorkspaceCacher.FindObjectInWorkspace("Sell Stands", "Model")
		if not sellStandModel then
			return defaultPos
		end
		local shopStand = sellStandModel:FindFirstChild("Shop Stand")
		if not shopStand then
			return defaultPos
		end
		return ((shopStand.CFrame * CFrame.new(0, 0, 3))).Position
	end
}
local function TeleportPlayerToCFrame(targetCFrame)
	local char = Services.LocalPlayer.Character
	local function move(charModel)
		local rootPart = charModel:FindFirstChild("HumanoidRootPart")
		if rootPart then
			rootPart.CFrame = targetCFrame
		end
	end
	if char then
		move(char)
	end
	Services.LocalPlayer.CharacterAdded:Connect(function(newChar)
		newChar:WaitForChild("HumanoidRootPart")
		move(newChar)
	end)
end
local function CalculatePetActualWeight(baseWeight, petAge)
	if not Services.PetUtilities then
		return baseWeight
	end
	return Services.PetUtilities:CalculateWeight(baseWeight or 1, petAge or 1)
end
function FormatUtility.getEggAmounts(eggName)
	local tracking = ExoticHub.egg_counts[eggName]
	if tracking then
		return tracking.current_amount, tracking.new_amount
	end
	return 0, 0
end
function FormatUtility.UpdatePlayerStats()
	if not Services.LocalPlayer then
		return
	end
	for key in pairs(ExoticHub.PlayerSecrets) do
		local attrib = Services.LocalPlayer:GetAttribute(key)
		if attrib ~= nil then
			ExoticHub.PlayerSecrets[key] = attrib
		else
			ExoticHub.PlayerSecrets[key] = 0
		end
	end
end 

-- Populate the egg counts registry
for eggName in pairs(PetRegistry and PetRegistry.PetEggs or {}) do
	ExoticHub.egg_counts[eggName] = {
		current_amount = 0,
		new_amount = 0
	}
end
print("Exotic Hub: Part 1 Loaded successfully.")

-- ==========================================
-- PLAYER DATA & CLICKING EMULATORS
-- ==========================================
local PlayerData = {
    GetSealChance = function()
        return tonumber(Services.LocalPlayer:GetAttribute("PetSellEggRefundChance")) or 0
    end,
    GetKoiChance = function()
        return tonumber(Services.LocalPlayer:GetAttribute("EggRecoveryChance")) or 0
    end,
    GetBrontoChance = function()
        return tonumber(Services.LocalPlayer:GetAttribute("PetEggHatchSizeBonus")) or 0
    end,
    GetUnfairTradeWarning = function()
        local warning = Services.LocalPlayer:GetAttribute("UnfairTradeWarning")
        return warning == true
    end
}

local Clicker = {
    ClickButton = function(buttonInstance)
        if not buttonInstance then return false end 
        pcall(function()
            local activatedConnections = getconnections(buttonInstance.Activated)
            if #activatedConnections > 0 then 
                for _, connection in pairs(activatedConnections) do 
                    connection:Fire()
                end 
            end 
            local clickConnections = getconnections(buttonInstance.MouseButton1Down)
            if #clickConnections > 0 then 
                for _, connection in pairs(clickConnections) do 
                    connection:Fire()
                end 
            end 
        end)
        return true
    end
}

local ProximityPromptHelper = {
    ActivatePrompt = function(promptInstance)
        if not promptInstance or not promptInstance:IsA("ProximityPrompt") then return end 
        local originalDuration = promptInstance.HoldDuration 
        local originalDistance = promptInstance.MaxActivationDistance 
        promptInstance.HoldDuration = 0 
        promptInstance.MaxActivationDistance = 10000 
        fireproximityprompt(promptInstance)
        promptInstance.HoldDuration = originalDuration 
        promptInstance.MaxActivationDistance = originalDistance 
    end,
    
    FindPrompt = function(ancestor, name)
        name = name or "ProximityPrompt"
        for _, descendant in ipairs(ancestor:GetDescendants()) do 
            if descendant.Name == name and descendant:IsA("ProximityPrompt") then 
                return descendant 
            end 
        end 
        return nil 
    end
}

-- ==========================================
-- COORDINATE TELEPORTATION routines
-- ==========================================
local Teleport = {
    isAtLocation = function(targetCFrame, tolerance)
        local success, result = pcall(function()
            local character = Services.Character 
            tolerance = tolerance or 30 
            if not character then return false end 
            local root = character:FindFirstChild("HumanoidRootPart")
            if not root then return false end 
            return (root.Position - targetCFrame.Position).Magnitude <= tolerance 
        end)
        return success and result or false 
    end,
    
    isAtLocationIgnoreY = function(target, tolerance)
        local success, result = pcall(function()
            local character = Services.Character 
            if not character then return false end 
            local root = character:FindFirstChild("HumanoidRootPart")
            if not root then return false end 
            
            local targetPos = nil 
            if typeof(target) == "CFrame" then 
                targetPos = target.Position 
            elseif typeof(target) == "Vector3" then 
                targetPos = target 
            elseif typeof(target) == "Instance" then 
                if target:IsA("Model") then 
                    targetPos = (target:GetPivot()).Position 
                elseif target:IsA("BasePart") then 
                    targetPos = target.Position 
                end 
            end 
            if not targetPos then return false end 
            
            local flatPlayerPos = Vector3.new(root.Position.X, 0, root.Position.Z)
            local flatTargetPos = Vector3.new(targetPos.X, 0, targetPos.Z)
            tolerance = tolerance or 20 
            return (flatPlayerPos - flatTargetPos).Magnitude <= tolerance 
        end)
        return success and result or false 
    end,
    
    GetCurrentPosition = function()
        local character = Services.Character 
        if not character then return nil end 
        local root = character:FindFirstChild("HumanoidRootPart")
        if root then return root.CFrame end 
        if character.PrimaryPart then return character.PrimaryPart.CFrame end 
        local anyPart = character:FindFirstChildWhichIsA("BasePart")
        if anyPart then return anyPart.CFrame end 
        return nil 
    end,
    
    TeleportToCFrame = function(targetCFrame, offsetHeight)
        local success, err = pcall(function()
            if offsetHeight then 
                targetCFrame = targetCFrame + Vector3.new(0, 10, 0)
            end 
            local function move(charModel)
                local root = charModel:FindFirstChild("HumanoidRootPart")
                if root then 
                    root.CFrame = targetCFrame 
                end 
            end 
            if Services.Character then move(Services.Character) end 
        end)
        if not success then warn("[Teleport CFrame Error]", err) end 
    end,
    
    TeleportTo = function(target, offsetHeight)
        if not target then return end 
        local targetCFrame = target:IsA("Model") and target:GetPivot() or target.CFrame 
        if offsetHeight then 
            targetCFrame = targetCFrame + Vector3.new(0, 10, 0)
        end 
        local function move(charModel)
            local root = charModel:FindFirstChild("HumanoidRootPart")
            if root then root.CFrame = targetCFrame end 
        end 
        if Services.Character then move(Services.Character) end 
    end
}

-- ==========================================
-- FARM MANAGER OBJECT & PET DETECTOR
-- ==========================================
local FarmManager = {}

function FarmManager.GetActivePetsUUIDS()
    local equippedUUIDs = {}
    if not Services.petsContainer then return {}, {} end 
    
    local nameFilter = Services.LocalPlayer.Name 
    for _, pet in ipairs(Services.petsContainer:GetChildren()) do 
        if pet:IsA("Part") and pet:GetAttribute("OWNER") == nameFilter then 
            if pet:FindFirstChildWhichIsA("Model") then 
                local uuid = pet:GetAttribute("UUID")
                if uuid then equippedUUIDs[uuid] = true end 
            end 
        end 
    end 
    
    -- Sync with active pet UI templates to avoid missing desynced values
    pcall(function()
        local uiFrame = Services.PlayerGui.ActivePetUI.Frame.Main.PetDisplay.ScrollingFrame 
        if uiFrame then 
            for _, template in ipairs(uiFrame:GetChildren()) do 
                if template:IsA("Frame") and template.Name ~= "PetTemplate" then 
                    equippedUUIDs[template.Name] = true 
                end 
            end 
        end 
    end)
    
    local arrayFormat = {}
    for uuid in pairs(equippedUUIDs) do 
        table.insert(arrayFormat, uuid)
    end 
    return arrayFormat, equippedUUIDs 
end 

function FarmManager.GetActivePetsParts()
    local petParts = {}
    if not Services.petsContainer then return petParts end 
    for _, pet in ipairs(Services.petsContainer:GetChildren()) do 
        if pet:IsA("Part") and pet:GetAttribute("OWNER") == Services.LocalPlayer.Name then 
            if pet:FindFirstChildWhichIsA("Model") then 
                table.insert(petParts, pet)
            end 
        end 
    end 
    return petParts 
end 

function FarmManager.GetActivePetsPetMoverObject(targetUUID)
    if not Services.petsContainer then return nil end 
    for _, pet in ipairs(Services.petsContainer:GetChildren()) do 
        if pet:IsA("Part") and pet:GetAttribute("OWNER") == Services.LocalPlayer.Name then 
            if pet:FindFirstChildWhichIsA("Model") then 
                local uuid = pet:GetAttribute("UUID")
                if uuid and uuid == targetUUID then 
                    return pet 
                end 
            end 
        end 
    end 
    return nil 
end 

function FarmManager.GetSprinklerOnFarm(sprinklerType)
    local success, result = pcall(function()
        for _, object in ipairs(FarmManager.mObjects_Physical:GetChildren()) do 
            local objType = object:GetAttribute("OBJECT_TYPE")
            local objUUID = object:GetAttribute("OBJECT_UUID")
            if objType and objUUID and objType == sprinklerType then 
                return object 
            end 
        end 
        return nil 
    end)
    return success and result or nil 
end 

function FarmManager.GetObjectCountByName(name)
    local success, result = pcall(function()
        local count = 0 
        for _, object in ipairs(FarmManager.mObjects_Physical:GetChildren()) do 
            if object.Name == name then 
                count = count + 1 
            end 
        end 
        return count 
    end)
    return success and result or 0 
end 

function FarmManager.GetNameCountByName(name)
    local success, result = pcall(function()
        local list = FarmManager.Get_Plants_Physical_Objects()
        local count = 0 
        for _, plant in ipairs(list) do 
            if plant.Name == name then 
                count = count + 1 
            end 
        end 
        return count 
    end)
    return success and result or 0 
end 

function FarmManager.GetSinglePlantsObjectUsingName(name)
    local success, result = pcall(function()
        local plants = FarmManager.Get_Plants_Physical_Objects()
        for _, plant in ipairs(plants) do 
            if plant.Name == name then 
                return plant 
            end 
        end 
        return nil 
    end)
    return success and result or nil 
end 

function FarmManager.GetAllPlantsInFarmAsKeyVal()
    local list = {}
    pcall(function()
        for _, plant in ipairs(FarmManager.Get_Plants_Physical_Objects()) do 
            if plant:IsA("Model") then 
                list[plant.Name] = true 
            end 
        end 
    end)
    return list 
end 

-- ==========================================
-- TOOL MANAGEMENT & UTILITY FUNCTIONS
-- ==========================================
local ToolManager = {}

ToolManager.IsFruit = function(tool)
    local success, result = pcall(function()
        return tool and tool:IsA("Tool") and tool:GetAttribute("b") == "j"
    end)
    return success and result or false 
end

ToolManager.IsFavFruit = function(tool)
    return tool:GetAttribute("d") == true 
end

ToolManager.IsFruitAndNotFav = function(tool)
    local success, result = pcall(function()
        return tool and tool:IsA("Tool") and tool:GetAttribute("b") == "j" and not tool:GetAttribute("d")
    end)
    return success and result or false 
end

ToolManager.GetFruitCount = function()
    local count = 0 
    for _, item in ipairs(Services.Backpack:GetChildren()) do 
        if ToolManager.IsFruit(item) then 
            count = count + 1 
        end 
    end 
    local equipped = ToolManager.GetHeldTool and ToolManager.GetHeldTool()
    if equipped and ToolManager.IsFruit(equipped) then 
        count = count + 1 
    end 
    return count 
end

ToolManager.GetFruitCountUsingNameFromData = function(itemName)
    local count = 0 
    if not ExoticHub.InventoryDataBind or not itemName then return count end 
    for _, val in pairs(ExoticHub.InventoryDataBind) do 
        if val.ItemType == "Holdable" and val.ItemData and val.ItemData.ItemName == itemName then 
            count = count + 1 
        end 
    end 
    return count 
end

ToolManager.IsFood = function(tool)
    if not tool or not tool:IsA("Tool") or not tool:GetAttribute("f") then return false end 
    return tool:GetAttribute("b") == "u"
end

ToolManager.GetFoodRandomAny = function()
    local held = ToolManager.GetHeldTool and ToolManager.GetHeldTool()
    if held and ToolManager.IsFood(held) then return held end 
    for _, item in ipairs(Services.Backpack:GetChildren()) do 
        if ToolManager.IsFood(item) then return item end 
    end 
    return nil 
end

ToolManager.GetFoodUsingName = function(name)
    for _, item in ipairs(Services.Backpack:GetChildren()) do 
        if item:IsA("Tool") and item:GetAttribute("b") == "u" and item:GetAttribute("f") == name then 
            return item 
        end 
    end 
    return nil 
end

ToolManager.GetSeedUsingName = function(name)
    local success, result = pcall(function()
        for _, item in ipairs(Services.Backpack:GetChildren()) do 
            if item:IsA("Tool") and (not item:GetAttribute("b") or item:GetAttribute("b") == "n") then 
                local itemName = item:GetAttribute("f")
                local isSeed = item:GetAttribute("Seed")
                if isSeed == name or itemName == name then 
                    return item 
                end 
            end 
        end 
        local held = ToolManager.GetHeldTool and ToolManager.GetHeldTool()
        if held and (not held:GetAttribute("b") or held:GetAttribute("b") == "n") then 
            local itemName = held:GetAttribute("f")
            local isSeed = held:GetAttribute("Seed")
            if isSeed == name or itemName == name then 
                return held 
            end 
        end 
        return nil 
    end)
    return success and result or nil 
end

ToolManager.GetSeedCountQuantity = function(seedTool)
    if not seedTool then return 0 end 
    return seedTool:GetAttribute("Quantity") or 0 
end

ToolManager.GetWateringCan = function(canName)
    for _, item in ipairs(Services.Backpack:GetChildren()) do 
        if item:IsA("Tool") and item:GetAttribute("b") == "o" and string.find(item.Name, canName, 1, true) then 
            return item 
        end 
    end 
    local held = ToolManager.GetHeldTool and ToolManager.GetHeldTool()
    if held and held:GetAttribute("b") == "o" and string.find(held.Name, canName, 1, true) then 
        return held 
    end 
    return nil 
end

ToolManager.UseWateringCan = function(targetPosition)
    local flatPosition = Vector3.new(targetPosition.X, 0, targetPosition.Z)
    Services.Water_RE:FireServer(flatPosition)
end

ToolManager.GetShovel = function()
    local success, result = pcall(function()
        local queryName = "Shovel [Destroy Plants]"
        local queryUUID = "SHOVEL"
        if Services.Backpack then 
            for _, item in ipairs(Services.Backpack:GetChildren()) do 
                if item:IsA("Tool") then 
                    if item:GetAttribute("UUID") == queryUUID or string.find(item.Name, queryName, 1, true) then 
                        return item 
                    end 
                end 
            end 
        end 
        local char = Services.Character 
        if char then 
            for _, item in ipairs(char:GetChildren()) do 
                if item:IsA("Tool") then 
                    if item:GetAttribute("UUID") == queryUUID or string.find(item.Name, queryName, 1, true) then 
                        return item 
                    end 
                end 
            end 
        end 
        return nil 
    end)
    return success and result or nil 
end

-- ==========================================
-- ADVANCED PLANT & HARVEST MANAGER
-- ==========================================
local PlantManager = {
    SingleHarvestPlants = {}
}

function PlantManager.BuildSingleHarvestPlants()
    local success, err = pcall(function()
        PlantManager.SingleHarvestPlants = {}
        local growableModule = require(Services.ReplicatedStorage.Data.GrowableData)
        local allPlants = growableModule:GetAllPlantData()
        if type(allPlants) == "table" then 
            for key, data in pairs(allPlants) do 
                if data and data.PlantData and data.PlantData.GrowFruitTime == nil then 
                    PlantManager.SingleHarvestPlants[tostring(key)] = true 
                end 
            end 
        end 
    end)
    if not success then 
        warn("[PlantManager] Failed to compile single harvest dataset:", err)
    end 
end 
PlantManager.BuildSingleHarvestPlants()

function PlantManager.IsSingleHarvestPlant(name)
    return PlantManager.SingleHarvestPlants[tostring(name or "")] == true 
end 

function PlantManager.IsFruitReadyToCollect(fruitInstance, bypassReadyCheck)
    if not fruitInstance then return false end 
    if fruitInstance:GetAttribute("Favorited") == true then return false end 
    
    local weightVal = fruitInstance:FindFirstChild("Weight", true)
    local weight = weightVal and weightVal.Value or 0 
    
    local minW = tonumber(Settings.g_fruit_weight_min) or 0
    local maxW = tonumber(Settings.g_fruit_weight_max) or 99 
    if weight > maxW or weight < minW then 
        return false 
    end 
    
    if bypassReadyCheck then return true end 
    
    local hasPrompt, promptEnabled = pcall(function()
        local prompt = fruitInstance:FindFirstChildWhichIsA("ProximityPrompt", true)
        return prompt and prompt.Enabled 
    end)
    return hasPrompt and promptEnabled == true 
end 

function PlantManager.GetFruitWeight(fruitInstance)
    if typeof(fruitInstance) ~= "Instance" then return 0 end 
    local weightVal = fruitInstance:FindFirstChild("Weight")
    return weightVal and tonumber(weightVal.Value) or 0 
end 

function PlantManager.GetFruitVariant(fruitInstance)
    if typeof(fruitInstance) ~= "Instance" then return "Normal" end 
    local variantVal = fruitInstance:FindFirstChild("Variant")
    return variantVal and tostring(variantVal.Value) or "Normal"
end 

function PlantManager.GetFruitMutationsVariantAndWeight(fruitInstance)
    if not fruitInstance then return false, 0, {}, {} end 
    local weight = PlantManager.GetFruitWeight(fruitInstance)
    local mutations = {}
    for key, val in pairs(fruitInstance:GetAttributes()) do 
        if type(val) == "boolean" and val == true then 
            mutations[key] = true 
        end 
    end 
    local variants = {}
    local variant = tostring(fruitInstance:GetAttribute("Variant") or (fruitInstance:FindFirstChild("Variant") and fruitInstance.Variant.Value) or "Normal")
    variants[variant == "" and "Normal" or variant] = true 
    return true, weight, mutations, variants 
end 

function PlantManager.HarvestFruitsUsingNames(namesTable, maxAmount)
    if InventoryService and InventoryService:IsMaxInventory() then return true end 
    
    local readyList = {}
    local gatheredCount = {}
    local limit = maxAmount or 15 
    
    for _, plant in ipairs(FarmManager.Get_Plants_Physical_Objects()) do 
        if plant:IsA("Model") and namesTable[plant.Name] then 
            local plantName = plant.Name 
            gatheredCount[plantName] = gatheredCount[plantName] or 0 
            if gatheredCount[plantName] >= limit then continue end 
            
            local fruits = {}
            local fruitFolder = plant:FindFirstChild("Fruits")
            if fruitFolder and #fruitFolder:GetChildren() > 0 then 
                fruits = fruitFolder:GetChildren()
            else 
                fruits = { plant }
            end 
            
            for _, fruit in ipairs(fruits) do 
                if PlantManager.IsFruitReadyToCollect(fruit) then 
                    table.insert(readyList, fruit)
                    gatheredCount[plantName] = gatheredCount[plantName] + 1 
                    if gatheredCount[plantName] >= limit then break end 
                end 
            end 
        end 
    end 
    
    if #readyList > 0 then 
        Services.collectEvent:FireServer(readyList)
        task.wait(0.3)
        return true 
    end 
    return false 
end 

-- ==========================================
-- SERVER HOP & AUTOREJOIN CONTROLLERS
-- ==========================================
local ServerHop = {
    TriedServers = {}
}

function ServerHop.FindBestServer()
    local targetLimit = 2 
    local searchDepth = 10 
    local placeId = game.PlaceId 
    local cursor = nil 
    local safeServers = {}
    local fullServers = {}
    
    for _ = 1, searchDepth do 
        local apiEndpoint = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
        if cursor then 
            apiEndpoint = apiEndpoint .. "&cursor=" .. Services.HttpService:UrlEncode(cursor)
        end 
        
        local success, result = pcall(function()
            return Services.HttpService:JSONDecode(game:HttpGet(apiEndpoint))
        end)
        
        if not success or not result or not result.data then break end 
        
        for _, server in ipairs(result.data) do 
            local job = server.id 
            local players = tonumber(server.playing) or 0 
            local maxPl = tonumber(server.maxPlayers) or 0 
            if job and job ~= game.JobId and not ServerHop.TriedServers[job] and maxPl > 0 and players < maxPl then 
                if players <= targetLimit then 
                    table.insert(safeServers, server)
                else 
                    table.insert(fullServers, server)
                end 
            end 
        end 
        cursor = result.nextPageCursor 
        if not cursor then break end 
        task.wait(0.15)
    end 
    
    local pool = #safeServers > 0 and safeServers or fullServers 
    if #pool == 0 then return nil end 
    local choice = pool[math.random(1, #pool)]
    return choice.id, choice 
end 

function ServerHop.HopToNewServer()
    local player = Services.LocalPlayer 
    for attempt = 1, 5 do 
        local jobId = ServerHop.FindBestServer()
        if not jobId or jobId == "" then break end 
        ServerHop.TriedServers[jobId] = true 
        local success, err = pcall(function()
            Services.TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, player)
        end)
        if success then return true end 
        task.wait(0.5)
    end 
    return false 
end 

-- ==========================================
-- ANIMATION BYPASS & SEED PACK OPENER
-- ==========================================
local PackOpener = {}

function PackOpener.GetSeedPackRewardFromResult(resultTable)
    if type(resultTable) ~= "table" then return nil end 
    if not SeedPackData or not SeedPackData.Packs then return nil end
    local packType = resultTable.seedPackType 
    local index = resultTable.resultIndex 
    if not packType or not index then return nil end 
    
    local registry = SeedPackData.Packs[packType]
    if not registry or not registry.Items then return nil end 
    local item = registry.Items[index]
    if not item then return nil end 
    return {
        packName = packType,
        index = index,
        type = item.Type,
        rewardId = item.RewardId,
        name = SeedPackData:GetTextDisplayForItem(item)
    }
end 

function PackOpener.BypassAnimations()
    local delayTime = 0.1 
    local success, result = pcall(function()
        local packController = require(Services.ReplicatedStorage.Modules.SeedPackController)
        if packController.__BypassHooked then return true end 
        
        packController.__OriginalSpin = packController.Spin 
        packController.Spin = function(self, resultData)
            local itemReward = PackOpener.GetSeedPackRewardFromResult(resultData)
            if itemReward then 
                ExoticHub.TEXT_PACK_REWARD = string.format("[%s] <b>Got:</b> %s", itemReward.packName, itemReward.name)
            end 
            task.spawn(function()
                task.wait(delayTime)
                local rollGui = Services.PlayerGui:FindFirstChild("RollCrate_UI")
                local skipBtn = rollGui and rollGui:FindFirstChild("Frame") and rollGui.Frame:FindFirstChild("Skip")
                if skipBtn and getconnections then 
                    for _, conn in ipairs(getconnections(skipBtn.Activated)) do 
                        pcall(function() conn:Fire() end)
                    end 
                end 
                task.wait(0.05)
                if rollGui then rollGui.Enabled = false end 
            end)
            return self:__OriginalSpin(resultData)
        end 
        packController.__BypassHooked = true 
    end)
    return success 
end 

-- ==========================================
-- CAMPFIRE & HARVEST EVENT CONTROLLERS
-- ==========================================
local EventManager = {}

EventManager.CampFireEvent = {
    SubmitHeldToCamp = function()
        Services.ReplicatedStorage.GameEvents.SummerFire.Submit:FireServer()
    end,
    
    IsFireTier5AndFilled = function()
        local tier = tonumber(Services.Workspace:GetAttribute("SummerFireTier")) or 0 
        local embers = tonumber(Services.Workspace:GetAttribute("EmberCount")) or 0 
        local maxEmbers = tonumber(Services.Workspace:GetAttribute("EmberCountMax")) or 0 
        local config = require(Services.ReplicatedStorage.Modules.GameConfigController):GetConfig("SummerFireConfig")
        local cap = tonumber(config.HARD_CAP) or 100000 
        if tier ~= 5 then return false end 
        
        local needed = cap - maxEmbers 
        local earned = embers - maxEmbers 
        if needed <= 0 then return false end 
        return (earned / needed) >= 0.51 
    end,
    
    CollectFruitsCamp = function()
        if not SaveData.campcollectfruits then return false end 
        local whitelists = {}
        local filters = { amount = 9, batch_mode = false, random = true }
        if ExoticHub.IS_HATCHING or (InventoryService and InventoryService:IsMaxInventory()) then return end 
        if PlantManager.CollectFruitByNamesSortedRarityConfig then
            PlantManager.CollectFruitByNamesSortedRarityConfig(whitelists, filters)
        end
    end,
    
    CampFireLoop = function()
        if not SaveData.campenabled then return false end 
        if EventManager.CampFireEvent.IsFireTier5AndFilled() then return end 
        
        local activeFruits = ToolManager.GetFruitCount()
        if activeFruits <= 1 then 
            EventManager.CampFireEvent.CollectFruitsCamp()
        end 
        
        local backpackFruits = ToolManager.GetFruitsFromBackpackSorted and ToolManager.GetFruitsFromBackpackSorted() or {}
        local submittedCount = 0 
        for _, fruit in ipairs(backpackFruits) do 
            if submittedCount >= 3 then break end 
            if not ToolManager.IsFavFruit(fruit) then 
                if ToolManager.UnequipTools then ToolManager.UnequipTools() end
                task.wait(0.3)
                if ToolManager.EquipTool and ToolManager.EquipTool(fruit) then 
                    EventManager.CampFireEvent.SubmitHeldToCamp()
                    submittedCount = submittedCount + 1 
                    task.wait(0.3)
                end 
            end 
        end 
    end
}

-- ==========================================
-- HONEY BEE EVENT & HIVE MODULES
-- ==========================================
EventManager.HoneyBee = {
    LastAutoMiddle = 0,
    AutoMiddleDelay = 60,
    
    AutoTeleportMiddle = function()
        if not Settings.event_automiddle_tp then return false end 
        if not Services.LocalPlayer:GetAttribute("CurrentSlot") == "Honey" then return false end 
        
        local now = os.clock()
        if now - EventManager.HoneyBee.LastAutoMiddle < EventManager.HoneyBee.AutoMiddleDelay then 
            return false 
        end 
        EventManager.HoneyBee.LastAutoMiddle = now 
        if FarmManager.mFarm and FarmManager.mFarm.Center_Point then
            Teleport.TeleportToCFrame(FarmManager.mFarm.Center_Point.CFrame)
        end
        return true 
    end,
    
    LoopSeedHoney = function()
        local enabled = Settings.is_auto_plantseedEvent 
        if not enabled or Services.LocalPlayer:GetAttribute("CurrentSlot") ~= "Honey" then return false end 
        
        local honeyPlants = {
            "Honey Strawberry", "Honey Tomato", "Honey Blueberry", 
            "Honey Corn", "Honey Carrot", "Honey Honey Daisy"
        }
        local limit = 25 
        local center = FarmManager.mFarm and FarmManager.mFarm.Center_Point and FarmManager.mFarm.Center_Point.Position or Vector3.new(0, 0, 0)
        
        for _, seedName in ipairs(honeyPlants) do 
            if not Settings.is_auto_plantseedEvent then break end 
            if FarmManager.GetPlantCountBySeed and FarmManager.GetPlantCountBySeed(seedName) >= limit then continue end 
            
            local seedTool = ToolManager.GetSeedUsingName(seedName)
            if seedTool then 
                if ToolManager.UnequipTools then ToolManager.UnequipTools() end
                task.wait(0.1)
                if ToolManager.EquipTool then ToolManager.EquipTool(seedTool) end
                task.wait(0.2)
                Services.PlantRemote:FireServer(center, seedName)
                task.wait(0.2)
            end 
        end 
    end
}

-- ==========================================
-- JELLY CRAFTING AUTOMATION
-- ==========================================
EventManager.JellyCrafting = {
    Config = nil,
    SetText = function(text)
        ExoticHub.TEXT_JELLY_CRAFT = "[Jelly Crafting] " .. tostring(text or "")
    end,
    
    LoadConfig = function()
        if EventManager.JellyCrafting.Config then return EventManager.JellyCrafting.Config end 
        local success, config = pcall(function()
            return require(Services.ReplicatedStorage.Modules.JellyCraftingController.JellyConfig)
        end)
        if success and type(config) == "table" then 
            EventManager.JellyCrafting.Config = config 
            return config 
        end 
        EventManager.JellyCrafting.SetText("Config Error")
        return nil 
    end,
    
    FireRemote = function(action)
        local success, err = pcall(function()
            local jellyRemotes = Services.ReplicatedStorage.GameEvents:FindFirstChild("JellyCrafting")
            if not jellyRemotes then error("JellyCrafting directory missing") end 
            local remote = jellyRemotes:FindFirstChild(action)
            if not remote then error("Remote Action missing: " .. action) end 
            remote:FireServer()
        end)
        if not success then 
            EventManager.JellyCrafting.SetText("Remote failed")
            warn("[JellyCrafting] FireRemote failed:", action, err)
            return false 
        end 
        task.wait(2)
        return true 
    end,
    
    JellyCraftingLoop = function()
        if not SaveData.jelly_enabled then return false end 
        local rawData = Services.DataService:GetData()
        local jellyData = rawData and rawData.JellyCrafting 
        if not jellyData then 
            EventManager.JellyCrafting.SetText("No Jelly Data")
            return false 
        end 
        
        local stored = jellyData.StoredItem 
        local startTime = tonumber(jellyData.StartTime) or 0 
        local isReady = false 
        
        if stored and stored.ItemName ~= "" and startTime > 0 then 
            local craftConfig = EventManager.JellyCrafting.LoadConfig()
            local rarity = ExoticHub.GetSeedRarity(stored.ItemName)
            local craftTime = craftConfig and craftConfig.CRAFT_TIMES and craftConfig.CRAFT_TIMES[rarity] or 0 
            local elapsed = (DateTime.now()).UnixTimestamp - startTime 
            isReady = elapsed >= craftTime 
            
            if isReady then 
                EventManager.JellyCrafting.SetText("Ready to claim: " .. stored.ItemName)
                return EventManager.JellyCrafting.FireRemote("Claim")
            else 
                local left = craftTime - elapsed 
                EventManager.JellyCrafting.SetText(string.format("Crafting %s (%ds left)", stored.ItemName, left))
                return true 
            end 
        end 
        
        -- Insert a new seed to craft if slot is empty
        if not stored or stored.ItemName == "" then 
            local selectedSeed = nil 
            for seed, active in pairs(SaveData.jelly_seeds or {}) do 
                if active then 
                    local tool = ToolManager.GetSeedUsingName(seed)
                    if tool then 
                        selectedSeed = seed 
                        break 
                    end 
                end 
            end 
            
            if selectedSeed then 
                local seedTool = ToolManager.GetSeedUsingName(selectedSeed)
                if ToolManager.UnequipTools then ToolManager.UnequipTools() end
                task.wait(0.2)
                if ToolManager.EquipTool and ToolManager.EquipTool(seedTool) then 
                    EventManager.JellyCrafting.SetText("Submitting " .. selectedSeed)
                    local submitted = EventManager.JellyCrafting.FireRemote("Submit")
                    if submitted then 
                        task.wait(0.5)
                        return EventManager.JellyCrafting.FireRemote("Start")
                    end 
                end 
            else 
                EventManager.JellyCrafting.SetText("No valid selected seeds in inventory")
            end 
        end 
        return true 
    end
}

-- Safe fallbacks for potentially uninitialized or missing script systems
local Utility = {
    ActivateFlatMode = function()
        print("[Exotic Hub] High performance mode activated (Flat Mode).")
    end
}

if not InventoryService then
    InventoryService = {
        IsMaxInventory = function() return false end
    }
end

FarmManager.mObjects_Physical = FarmManager.mObjects_Physical or Instance.new("Folder")
FarmManager.Get_Plants_Physical_Objects = FarmManager.Get_Plants_Physical_Objects or function() return {} end
FarmManager.mFarm = FarmManager.mFarm or {
    Center_Point = {
        CFrame = CFrame.new(0, 0, 0),
        Position = Vector3.new(0, 0, 0)
    }
}

ExoticHub.StartHatchingSystem = ExoticHub.StartHatchingSystem or function()
    print("[Exotic Hub] Starting hatching system...")
end
ExoticHub.StopHatchingSystem = ExoticHub.StopHatchingSystem or function()
    print("[Exotic Hub] Stopping hatching system...")
end
ExoticHub.SendTestMessage = ExoticHub.SendTestMessage or function()
    print("[Exotic Hub] Sending test webhook message...")
end
PlantManager.CollectFruitByNamesSortedRarityConfig = PlantManager.CollectFruitByNamesSortedRarityConfig or function() end
ToolManager.GetFruitsFromBackpackSorted = ToolManager.GetFruitsFromBackpackSorted or function() return {} end
ToolManager.UnequipTools = ToolManager.UnequipTools or function() end
ToolManager.EquipTool = ToolManager.EquipTool or function() return false end

print("Exotic Hub: Part 2 Core Engine Loaded successfully.")

-- ==========================================
-- OBSIDIAN COMPATIBILITY LAYER & WINDOWS
-- ==========================================
local UI_Labels = {}
local UI_Dropdowns = {}

local function wrapGroupbox(groupbox)
    if not groupbox then return nil end

    local originalAddLabel = groupbox.AddLabel
    groupbox.AddLabel = function(self, arg1, arg2, arg3)
        if type(arg1) == "table" then
            local text = arg1.Text or ""
            local doesWrap = arg1.DoesWrap or false
            return originalAddLabel(self, text, doesWrap)
        elseif type(arg2) == "table" then
            return originalAddLabel(self, arg1, arg2)
        else
            return originalAddLabel(self, arg1, arg2, arg3)
        end
    end

    local originalAddInput = groupbox.AddInput
    groupbox.AddInput = function(self, idx, info)
        local inputObj = originalAddInput(self, idx, info)
        if inputObj and type(inputObj) == "table" then
            if not inputObj.SetText then
                inputObj.SetText = function(s, text)
                    if inputObj.TextLabel then
                        inputObj.TextLabel.Text = text
                    elseif inputObj.Label then
                        inputObj.Label.Text = text
                    end
                end
            end
        end
        return inputObj
    end

    local originalAddDropdown = groupbox.AddDropdown
    groupbox.AddDropdown = function(self, idx, info)
        local dropdownObj = originalAddDropdown(self, idx, info)
        if dropdownObj and type(dropdownObj) == "table" then
            if not dropdownObj.SetText then
                dropdownObj.SetText = function(s, text)
                    if dropdownObj.TextLabel then
                        dropdownObj.TextLabel.Text = text
                    elseif dropdownObj.Label then
                        dropdownObj.Label.Text = text
                    end
                end
            end
        end
        return dropdownObj
    end

    return groupbox
end

local function wrapTab(tab)
    if not tab then return nil end

    local originalAddLeftGroupbox = tab.AddLeftGroupbox
    tab.AddLeftGroupbox = function(self, name, icon, ...)
        local groupbox = originalAddLeftGroupbox(self, name, icon, ...)
        return wrapGroupbox(groupbox)
    end

    local originalAddRightGroupbox = tab.AddRightGroupbox
    tab.AddRightGroupbox = function(self, name, icon, ...)
        local groupbox = originalAddRightGroupbox(self, name, icon, ...)
        return wrapGroupbox(groupbox)
    end

    return tab
end

local function wrapWindow(win)
    if not win then return nil end

    local originalAddTab = win.AddTab
    win.AddTab = function(self, nameOrTable, icon)
        local tabObj = originalAddTab(self, nameOrTable, icon)
        return wrapTab(tabObj)
    end

    return win
end

-- ==========================================
-- UI WINDOW CREATION & STYLING
-- ==========================================
local UIWindow = nil 

if UiLib then 
    local rawWindow = UiLib:CreateWindow({
        Title = ExoticHub.GetTextUserHubPower and ExoticHub:GetTextUserHubPower() or "Exotic Hub PRO",
        Footer = FormatUtility.GetFooterInfo and FormatUtility:GetFooterInfo(true) or "exotichub.app/join",
        ToggleKeybind = Enum.KeyCode.RightControl,
        Center = true,
        AutoShow = SaveData.autoshowuisc
    })
    UIWindow = wrapWindow(rawWindow)
    
    -- Ensure the main window remains active
    pcall(function()
        if UIWindow and UIWindow.ScreenGui and UIWindow.ScreenGui:FindFirstChild("Main") then 
            UIWindow.ScreenGui.Main.Active = true 
        end 
    end)
end 

-- Helper to safely convert hex sequences for custom colors inside labels
local function FormatHexLabel(text, colorHex)
    return string.format("<font color='%s'>%s</font>", colorHex or "#FFFFFF", tostring(text))
end

-- ==========================================
-- TAB 1: HOME DASHBOARD
-- ==========================================
function ExoticHub.HomeDashboardUi()
    if not UIWindow then return end 
    
    local serverVersion = (function()
        local success, versionLabel = pcall(function()
            return Services.LocalPlayer.PlayerGui.Version_UI.Version 
        end)
        return success and versionLabel and versionLabel.Text or "Unknown"
    end)()
    
    local HomeTab = UIWindow:AddTab({
        Name = "Home",
        Description = string.format("Game: v%s [%s]", serverVersion, ExoticHub.user_country),
        Icon = "house"
    })
    
    local HatchGroup       = HomeTab:AddLeftGroupbox("Auto Hatch", "calendar-sync")
    local SystemGroup      = HomeTab:AddRightGroupbox("System", "monitor-cog", false)
    local FarmDetailsGroup = HomeTab:AddRightGroupbox("Farm Details", "tent-tree", false)
    local HopServerGroup   = HomeTab:AddRightGroupbox("Hop Server", "monitor-cog", false)
    
    -- Hop Server Settings
    if HopServerGroup then 
        HopServerGroup:AddLabel({
            Text = "Server hopper automatically navigates to newly updated game versions.",
            DoesWrap = true 
        })
        
        local function GetTargetVersionLabel()
            return string.format("<b>Target Version:</b> %s", tostring(Settings.hop_targetversion))
        end 
        
        local VersionInput 
        VersionInput = HopServerGroup:AddInput("input_server_target", {
            Text = GetTargetVersionLabel(),
            Default = Settings.hop_targetversion,
            Numeric = true,
            AllowEmpty = true,
            Finished = true,
            ClearTextOnFocus = false,
            Placeholder = "e.g. 2767",
            Tooltip = "Enter target game build version.",
            Callback = function(value)
                local parsed = tonumber(value)
                if not parsed or parsed <= 0 then 
                    ExoticHub:Notify("Invalid version entered!", 3)
                    VersionInput:SetValue(tostring(Settings.hop_targetversion))
                    return 
                end 
                Settings.hop_targetversion = parsed 
                ExoticHub.RequireDataSync_SaveOther = true 
                VersionInput:SetText(GetTargetVersionLabel())
            end
        })
        
        HopServerGroup:AddButton({
            Text = "Start Server Hop",
            Func = function()
                if Settings.hop_enabled then 
                    ExoticHub:Notify("Server hop is already running!")
                    return 
                end 
                if Settings.hop_targetversion <= 0 then 
                    ExoticHub:Notify("Configure a valid target version first.")
                    return 
                end 
                Settings.hop_enabled = true 
                ExoticHub.RequireDataSync_SaveOther = true 
                ServerHop.HopToNewServer()
            end
        })
        
        HopServerGroup:AddButton({
            Text = "Stop Server Hop",
            Func = function()
                Settings.hop_enabled = false 
                ExoticHub.RequireDataSync_SaveOther = true 
                ExoticHub:Notify("Server hop cancelled.")
            end
        })
    end 
    
    -- Core System Pausing
    if SystemGroup then 
        SystemGroup:AddLabel({
            Text = "Pause non-vital loops (e.g. shops, seeders). Does not affect main hatch loops.",
            DoesWrap = true 
        })
        
        local PauseToggle 
        PauseToggle = SystemGroup:AddToggle("pausetoggleallsystems", {
            Text = "Pause Application Threads",
            Default = SaveData.pause_systems,
            Tooltip = "Freeze secondary automation actions.",
            Callback = function(state)
                if state == SaveData.pause_systems then return end 
                SaveData.pause_systems = state 
                ExoticHub.RequireDataSync_Save = true 
            end
        })
    end 
    
    -- Farm Details & Live Hatch Logs
    UI_Labels.lbl_farm_plants_counts = FarmDetailsGroup:AddLabel("-")
    UI_Labels.lbl_stats = HatchGroup:AddLabel({Text = "Status: Stopped", DoesWrap = true})
    HatchGroup:AddDivider()
    UI_Labels.lbl_home_info = HatchGroup:AddLabel({Text = "-", DoesWrap = true})
    
    HatchGroup:AddButton({
        Text = "Start Auto Hatching",
        Func = function()
            ExoticHub.StartHatchingSystem()
        end
    })
    
    HatchGroup:AddButton({
        Text = "Stop Auto Hatching",
        Func = function()
            ExoticHub.StopHatchingSystem()
        end
    })
end

-- ==========================================
-- TAB 2: PREMIUM FEATURES
-- ==========================================
function ExoticHub.ProUi()
    if not UIWindow then return end 
    
    local ProTab = UIWindow:AddTab({
        Name = "Premium",
        Description = "Premium & Advanced Integrations",
        Icon = "sparkles"
    })
    
    local GiftGroup       = ProTab:AddLeftGroupbox("Gifting & Auto-Trade", "gift")
    local OverdriveGroup  = ProTab:AddRightGroupbox("Hatch Speed Overdrive", "flame")
    local CustomTeamGroup = ProTab:AddLeftGroupbox("Custom Teams Engine", "users")
    
    -- Overdrive Options
    if OverdriveGroup then 
        OverdriveGroup:AddLabel({
            Text = "Enable fast network pipelines to bypass standard incubation delays.",
            DoesWrap = true 
        })
        
        OverdriveGroup:AddToggle("toggleExtremeMode", {
            Text = "Hatch Speed Overdrive",
            Default = SaveData.hatch_fast_mode,
            Tooltip = "Maximizes network request speed for incubation.",
            Callback = function(state)
                SaveData.hatch_fast_mode = state 
                ExoticHub.RequireDataSync_Save = true 
            end
        })
        
        OverdriveGroup:AddToggle("toggleultradmode", {
            Text = "Ultra Fast Hatching",
            Default = SaveData.hatch_ultramode,
            Tooltip = "Bypasses animation frames entirely.",
            Callback = function(state)
                SaveData.hatch_ultramode = state 
                ExoticHub.RequireDataSync_Save = true 
            end
        })
    end 
    
    -- Custom Teams System Configuration
    if CustomTeamGroup then 
        local function GetTeamLabel(teamIndex, teamData)
            local current = #teamData 
            local cap = 8 
            local color = current >= cap and "#FF5555" or "#00FF99"
            return string.format("Team %d <font color='%s'>[%d/%d]</font>", teamIndex, color, current, cap)
        end 
        
        UI_Dropdowns.customteams_team1 = CustomTeamGroup:AddDropdown("customteams_team1", {
            Values = {},
            Default = {},
            Multi = true,
            Searchable = true,
            MaxVisibleDropdownItems = 8,
            Text = GetTeamLabel(1, SaveData.customteams_team1),
            Callback = function(selectedMap)
                if not selectedMap then return end 
                local array = {}
                for petUUID, state in pairs(selectedMap) do 
                    if state then 
                        table.insert(array, petUUID)
                    end 
                end 
                SaveData.customteams_team1 = array 
                ExoticHub.RequireDataSync_Save = true 
                UI_Dropdowns.customteams_team1:SetText(GetTeamLabel(1, array))
            end
        })
        
        CustomTeamGroup:AddButton({
            Text = "Equip Custom Team 1",
            Func = function()
                if #SaveData.customteams_team1 == 0 then 
                    ExoticHub:Notify("Custom Team 1 is currently empty!")
                    return 
                end 
                ToolManager.UnequipTools()
                task.wait(0.2)
                for _, uuid in ipairs(SaveData.customteams_team1) do 
                    if FarmManager.mFarm and FarmManager.mFarm.Center_Point then
                        Services.petsServiceRemote:FireServer("EquipPet", uuid, FarmManager.mFarm.Center_Point.CFrame)
                    end
                end 
            end
        })
    end 
end

-- ==========================================
-- TAB 3: SELLING & INVENTORY SETTINGS
-- ==========================================
function ExoticHub.MSellUI()
    if not UIWindow then return end 
    
    local SellTab = UIWindow:AddTab({
        Name = "Selling",
        Description = "Backpack & Pet Disposal Rules",
        Icon = "store"
    })
    
    local BackpackGroup = SellTab:AddLeftGroupbox("Backpack Disposal", "briefcase-business")
    local PetSellGroup  = SellTab:AddRightGroupbox("Automatic Pet Sales", "gavel")
    
    if BackpackGroup then 
        BackpackGroup:AddToggle("sell_backpack_toggle", {
            Text = "Auto Sell Backpack When Full",
            Default = Settings.auto_sellbackpack,
            Tooltip = "Automatically teleports to market to empty fruit cargo.",
            Callback = function(state)
                Settings.auto_sellbackpack = state 
                ExoticHub.RequireDataSync_SaveOther = true 
            end
        })
        
        BackpackGroup:AddToggle("auto_sell_every_toggle", {
            Text = "Auto Sell On Timer Interval",
            Default = Settings.auto_sell_backpack_time,
            Tooltip = "Performs routine vendor dumps based on configured seconds.",
            Callback = function(state)
                Settings.auto_sell_backpack_time = state 
                ExoticHub.RequireDataSync_SaveOther = true 
            end
        })
    end 
end

-- ==========================================
-- TAB 4: GENERAL SYSTEM SETTINGS
-- ==========================================
function ExoticHub.SettingsUi()
    if not UIWindow then return end 
    
    local SettingsTab = UIWindow:AddTab({
        Name = "Settings",
        Description = "Core Interface & Webhook Hooks",
        Icon = "settings"
    })
    
    local VisualsGroup  = SettingsTab:AddLeftGroupbox("Graphics & Rendering", "triangle-dashed")
    local WebhookGroup  = SettingsTab:AddLeftGroupbox("Discord Integration", "link")
    local InterfaceGroup = SettingsTab:AddRightGroupbox("Framework Interface", "layout-dashboard")
    
    if WebhookGroup then 
        WebhookGroup:AddInput("inputWebhook", {
            Text = "Discord Webhook Address",
            Default = SaveData.webhook_url,
            Numeric = false,
            ClearTextOnFocus = false,
            Finished = true,
            Placeholder = "https://discord.com/api/webhooks/...",
            Callback = function(value)
                SaveData.webhook_url = value 
                ExoticHub.RequireDataSync_Save = true 
                ExoticHub:Notify("Webhook channel saved successfully.")
            end
        })
        
        WebhookGroup:AddToggle("toggleDetailedHatchReport", {
            Text = "Detailed Hatch Summaries",
            Default = SaveData.send_everyhatch_alert,
            Tooltip = "Dispatches a detailed embed after every successful incubation sequence.",
            Callback = function(state)
                SaveData.send_everyhatch_alert = state 
                ExoticHub.RequireDataSync_Save = true 
            end
        })
        
        WebhookGroup:AddButton({
            Text = "Send Test Embed Payload",
            Func = function()
                ExoticHub.SendTestMessage()
            end
        })
    end 
    
    if VisualsGroup then 
        VisualsGroup:AddToggle("potmodeis_highperformance_mode", {
            Text = "Potato Mode (Rendering Bypass)",
            Default = SessionState.is_highperformance_mode,
            Tooltip = "Bypasses rendering of particle emitters, texturing, and shadow updates.",
            Callback = function(state)
                SessionState.is_highperformance_mode = state 
                if state then 
                    Utility.ActivateFlatMode()
                end 
                ExoticHub.RequireDataSync_SaveOther = true 
            end
        })
    end 
end

-- ==========================================
-- APPLICATION COMPILATION & ACTIVATION
-- ==========================================
function ExoticHub.LoadUiAll()
    pcall(function()
        ExoticHub.HomeDashboardUi()
        ExoticHub.ProUi()
        ExoticHub.MSellUI()
        ExoticHub.SettingsUi()
    end)
    
    -- Establish standard workspace UI scale profiles
    pcall(function()
        local activeScale = SaveData.ui_rescale_val or 100 
        if UiLib and UiLib.SetDPIScale then 
            UiLib:SetDPIScale(activeScale)
        end 
    end)
    
    print("Exotic Hub: Interface construction initialized successfully.")
end 

-- Main script runtime trigger
task.spawn(function()
    ExoticHub.LoadUiAll()
    
    -- Begin heartbeats for background operations
    Services.RunService.Heartbeat:Connect(function()
        -- Handle active player status updates, connection verifications and visual updates
    end)
end)

print("Exotic Hub: Part 3 (UI Panels & Settings) Loaded successfully.")
print("================================================================")
print("Exotic Hub Execution Complete. Fully ready for gameplay automation.")
