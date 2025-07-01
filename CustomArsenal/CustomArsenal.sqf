    
//call compile preprocessFileLineNumbers "CustomArsenal\Weapons.sqf";  
//call compile preprocessFileLineNumbers "CustomArsenal\Gear.sqf"; 

CustomArsenal_Init = {
    CustomArsenal_UseCustomLoadout = false;
};

CustomArsenal_Setup = {
    // Call on each client
    params ["_whatToLoad",["_dlcDoNotLoad",[]]];
    // _whatToLoad: 0 = full arsenal, 1 = limited by map, 2 = faction weapons w/ added launchers, 3 = faction weapons only
    // _dlcDoNoLoad: array of dlc to not load into the arsenal when set to full or limited (see FactionDlcId for items)
    
    private _customDLCs = [];
    CustomArsenal_UseCustomLoadout = (_whatToLoad == 1);
    
    // setup custom LV units if needed
    call CustomArsenal_LVInit;
    
    // gear up the unit
    [player] call CustomArsenal_Loadout;
 
    if (CustomArsenal_UseCustomLoadout) then {
        _customDLCs = [] call FactionDlcId;
    };
    
    //[_customDLCs] call Weapons_InitArray;
    //[_customDLCs] call Gear_InitArray;
    
    ["Preload"] call BIS_fnc_arsenal;
    [_whatToLoad,_dlcDoNotLoad] call CustomArsenal_Arsenal;
    CUSTOM_ARSENAL_SETUP_COMPLETE = true;
};

CustomArsenal_LVInit = {
    LV_CUSTOM_ENEMY_NAME = "Soldiers";
    ITW_USE_LV_CUSTOM_UNITS = true;
    switch (toLowerANSI worldName) do {
        case "gm_weferlingen_summer": { 
            LV_CUSTOM_SIDE = east;
            LV_CUSTOM_MEN_ARRAY = ["gm_gc_army_antitank_mpiak74n_fagot_80_str","gm_gc_army_demolition_mpiaks74n_80_str","gm_gc_army_machinegunner_lmgrpk_80_str","gm_gc_army_machinegunner_assistant_mpiak74n_lmgrpk_80_str","gm_gc_army_machinegunner_pk_80_str","gm_gc_army_machinegunner_assistant_mpiak74n_pk_80_str","gm_gc_army_engineer_mpiaks74n_80_str","gm_gc_army_rifleman_mpiak74n_80_str","gm_gc_army_squadleader_mpiak74n_80_str","gm_gc_bgs_rifleman_mpikm72_80_str","gm_gc_army_rifleman_mpiak74n_80_str","gm_gc_bgs_rifleman_mpikm72_80_str","gm_gc_army_rifleman_mpiak74n_80_str","gm_gc_bgs_rifleman_mpikm72_80_str","gm_gc_army_rifleman_mpiak74n_80_str"];
            LV_CUSTOM_ENEMY_NAME = "East Germans";
        };
        
        case "gm_weferlingen_winter": { 
            LV_CUSTOM_SIDE = east;
            LV_CUSTOM_MEN_ARRAY = ["gm_gc_army_antitank_mpiak74n_fagot_80_win","gm_gc_army_demolition_mpiaks74n_80_win","gm_gc_army_machinegunner_assistant_mpiak74n_lmgrpk_80_win","gm_gc_army_machinegunner_lmgrpk_80_win","gm_gc_army_machinegunner_pk_80_win","gm_gc_army_machinegunner_assistant_mpiak74n_pk_80_win","gm_gc_army_engineer_mpiaks74n_80_win","gm_gc_army_rifleman_mpiak74n_80_win","gm_gc_army_squadleader_mpiak74n_80_win","gm_gc_army_rifleman_mpiak74n_80_win","gm_gc_army_rifleman_mpiak74n_80_win","gm_gc_army_rifleman_mpiak74n_80_win"];
            LV_CUSTOM_ENEMY_NAME = "East Germans";
        };
        
        case "stozec": { 
            LV_CUSTOM_SIDE = east;
            LV_CUSTOM_MEN_ARRAY = selectRandom [
                ["CSLA_mrOfc","CSLA_mrRPG75","CSLA_mrSa58P","CSLA_mrSa58V","CSLA_mrRF10","CSLA_engSapper","CSLA_engLA","CSLA_mrVG70","CSLA_mrOfcStb","CSLA_mrOP63","CSLA_ECh1a","CSLA_mrUK59","CSLA_engCJt","CSLA_mrSa58Pp","CSLA_mrMedi","CSLA_mrSgt","CSLA_ECh2"],
                ["CSLA_lrrBaseman","CSLA_lrrRTO","CSLA_lrrMedi","CSLA_lrrSpr","CSLA_lrrDrM","CSLA_lrrCmd"]
            ];
            LV_CUSTOM_CIVILIAN_ARRAY = ["CSLA_CIV_Citizen","CSLA_CIV_Citizen_V2","CSLA_CIV_Citizen_V3","CSLA_CIV_Citizen_V4","CSLA_CIV_Foreman","CSLA_CIV_Doctor","CSLA_CIV_Foreman_V2","CSLA_CIV_Woodlander","CSLA_CIV_Woodlander_V2","CSLA_CIV_Woodlander_V3","CSLA_CIV_Woodlander_V4","CSLA_CIV_Functionary","CSLA_CIV_Functionary_V2","CSLA_CIV_Villager","CSLA_CIV_Villager_V2","CSLA_CIV_Villager_V3","CSLA_CIV_Villager_V4","CSLA_CIV_Worker","CSLA_CIV_Worker_V2","CSLA_CIV_Worker_V3","CSLA_CIV_Worker_V4"];
            LV_CUSTOM_ENEMY_NAME = "CSLA Soldiers";
        };
        
        case "enoch": { 
            LV_CUSTOM_SIDE = east;
            LV_CUSTOM_MEN_ARRAY = selectRandom [
                ["I_E_Soldier_GL_F","I_E_Soldier_SL_F","I_E_RadioOperator_F","I_E_Soldier_LAT_F","I_E_soldier_M_F","I_E_Soldier_TL_F","I_E_Soldier_AR_F","I_E_Soldier_A_F","I_E_Medic_F","I_E_Soldier_F"],
                ["O_R_Patrol_Soldier_A_F", "O_R_Patrol_Soldier_AR2_F", "O_R_Patrol_Soldier_AR_F", "O_R_Patrol_Soldier_Medic", "O_R_Patrol_Soldier_Engineer_F", "O_R_Patrol_Soldier_GL_F", "O_R_Patrol_Soldier_M2_F", "O_R_Patrol_Soldier_LAT_F", "O_R_Patrol_Soldier_M_F", "O_R_Patrol_Soldier_TL_F"],
                ["O_R_recon_AR_F", "O_R_recon_exp_F", "O_R_recon_GL_F", "O_R_recon_JTAC_F", "O_R_recon_M_F", "O_R_recon_medic_F", "O_R_recon_LAT_F", "O_R_recon_TL_F"]
            ];
            LV_CUSTOM_CIVILIAN_ARRAY = ["C_Man_1_enoch_F","C_Man_2_enoch_F","C_Man_3_enoch_F","C_Man_4_enoch_F","C_Man_5_enoch_F","C_Man_6_enoch_F","C_Farmer_01_enoch_F"];
            
            switch ((LV_CUSTOM_MEN_ARRAY#0) select [4,1]) do {
                case "S": {LV_CUSTOM_ENEMY_NAME = "LDF Soldiers"; LV_CUSTOM_SIDE = resistance;};
                case "P": {LV_CUSTOM_ENEMY_NAME = "Spetsnaz Soldiers"; };
                case "r": {LV_CUSTOM_ENEMY_NAME = "Spetsnaz Special Forces"; };
            };
        };
        
        case "vn_khe_sanh";
        case "vn_the_bra";
        case "cam_lao_nam": { 
            LV_CUSTOM_SIDE = east;
            LV_CUSTOM_MEN_ARRAY = ["vn_o_men_nva_01","vn_o_men_nva_02","vn_o_men_nva_03","vn_o_men_nva_04","vn_o_men_nva_05","vn_o_men_nva_06","vn_o_men_nva_07","vn_o_men_nva_08","vn_o_men_nva_09","vn_o_men_nva_10","vn_o_men_nva_11","vn_o_men_nva_12"];
            LV_CUSTOM_CIVILIAN_ARRAY = ["vn_c_men_01","vn_c_men_02","vn_c_men_05","vn_c_men_06","vn_c_men_09","vn_c_men_10","vn_c_men_13","vn_c_men_14","vn_c_men_17","vn_c_men_18","vn_c_men_21","vn_c_men_22","vn_c_men_25","vn_c_men_26","vn_c_men_29","vn_c_men_30"];
            LV_CUSTOM_ENEMY_NAME = "PAVN Soldiers";
        };
        
        case "sefrouramal": { 
            LV_CUSTOM_SIDE = resistance;
            LV_CUSTOM_MEN_ARRAY = selectRandom [
                ["O_SFIA_Soldier_AR_lxWS", "O_SFIA_medic_lxWS", "O_SFIA_exp_lxWS", "O_SFIA_Soldier_GL_lxWS", "O_SFIA_officer_lxWS", "O_SFIA_repair_lxWS", "O_SFIA_soldier_lxWS", "O_SFIA_sharpshooter_lxWS", "O_SFIA_Soldier_universal_lxWS", "O_SFIA_Soldier_TL_lxWS"],
                ["O_Tura_defector_lxWS", "O_Tura_deserter_lxWS", "O_Tura_enforcer_lxWS", "O_Tura_scout_lxWS", "O_Tura_medic2_lxWS", "O_Tura_thug_lxWS", "O_Tura_watcher_lxWS"],
                ["I_C_Soldier_Bandit_4_F","I_C_Soldier_Bandit_3_F","I_C_Soldier_Bandit_7_F","I_C_Soldier_Bandit_5_F","I_C_Soldier_Bandit_6_F","I_C_Soldier_Bandit_2_F","I_C_Soldier_Bandit_8_F","I_C_Soldier_Bandit_1_F"],
                ["B_ION_Soldier_GL_lxWS","B_ION_Soldier_lxWS","B_ION_TL_lxWS","B_ION_marksman_lxWS","B_ION_medic_lxWS","B_ION_shot_lxWS","B_ION_soldier_AR_lxWS"]
            ];
            
            switch ((LV_CUSTOM_MEN_ARRAY#0) select [2,1]) do {
                case "S": {LV_CUSTOM_ENEMY_NAME = "SFIA Soldiers";   LV_CUSTOM_SIDE = east;};
                case "T": {LV_CUSTOM_ENEMY_NAME = "Tura Soldiers";   };
                case "C": {LV_CUSTOM_ENEMY_NAME = "Bandits";         };
                case "I": {LV_CUSTOM_ENEMY_NAME = "ION paramilitary";};
            };
            
            LV_CUSTOM_CIVILIAN_ARRAY = ["C_man_polo_1_F_asia","C_Man_casual_9_F","C_man_polo_3_F_asia","C_man_polo_4_F_asia","C_man_polo_6_F_asia","C_Man_casual_2_F","C_Man_casual_6_v2_F","C_Man_formal_2_F","C_man_polo_5_F_euro"];
            LV_CUSTOM_CIVILIAN_INIT = "[_this] call GB_fnc_CustomLoadout;";
        };
        
        case "spex_utah_beach";
        case "spex_carentan";
        case "spe_mortain";
        case "spe_normandy": {
            LV_CUSTOM_SIDE = resistance;
            LV_CUSTOM_MEN_ARRAY = ["SPE_GER_SquadLead","SPE_GER_mgunner","SPE_GER_medic","SPE_GER_Assist_SquadLead",
            "SPE_GER_rifleman","SPE_GER_amgunner","SPE_GER_LAT_Rifleman","SPE_GER_ober_grenadier","SPE_GER_rifleman",
            "SPE_GER_rifleman","SPE_GER_rifleman","SPE_GER_rifleman","SPE_GER_rifleman_lite","SPE_GER_ober_rifleman",
            "SPE_GER_stggunner","SPE_GER_sapper","SPE_GER_mgunner2","SPE_GER_hmgunner","SPE_GER_AT_grenadier"];
            LV_CUSTOM_CIVILIAN_ARRAY = ["SPE_CIV_Citizen_1","SPE_CIV_Citizen_1_tie","SPE_CIV_Citizen_1_trop",
            "SPE_CIV_Citizen_2","SPE_CIV_Citizen_2_tie","SPE_CIV_Citizen_2_trop","SPE_CIV_Citizen_3",
            "SPE_CIV_Citizen_3_tie","SPE_CIV_Citizen_3_trop","SPE_CIV_Citizen_4","SPE_CIV_Citizen_4_tie",
            "SPE_CIV_Citizen_5","SPE_CIV_Citizen_5_tie","SPE_CIV_Citizen_5_trop","SPE_CIV_Citizen_6",
            "SPE_CIV_Citizen_6_trop","SPE_CIV_Citizen_7","SPE_CIV_Citizen_7_tie","SPE_CIV_Citizen_7_trop",
            "SPE_CIV_pak2_zwart","SPE_CIV_pak2_zwart_alt","SPE_CIV_pak2_zwart_tie","SPE_CIV_pak2_zwart_tie_alt", 
            "SPE_CIV_pak2_zwart_swetr","SPE_CIV_pak2_bruin","SPE_CIV_pak2_bruin_tie","SPE_CIV_pak2_bruin_swetr",  
            "SPE_CIV_pak2_grijs","SPE_CIV_pak2_grijs_tie","SPE_CIV_pak2_grijs_swetr","SPE_CIV_Swetr_1",  
            "SPE_CIV_Swetr_1_vest","SPE_CIV_Swetr_2","SPE_CIV_Swetr_2_vest","SPE_CIV_Swetr_3",      
            "SPE_CIV_Swetr_3_vest","SPE_CIV_Swetr_4","SPE_CIV_Swetr_4_vest","SPE_CIV_Swetr_5_vest",    
            "SPE_CIV_Worker_Coverall_1","SPE_CIV_Worker_Coverall_2","SPE_CIV_Worker_Coverall_2_trop",  
            "SPE_CIV_Worker_Coverall_3","SPE_CIV_Worker_Coverall_3_trop","SPE_CIV_Worker_1","SPE_CIV_Worker_1_tie",
            "SPE_CIV_Worker_1_trop","SPE_CIV_Worker_2","SPE_CIV_Worker_2_tie","SPE_CIV_Worker_2_trop",  
            "SPE_CIV_Worker_3","SPE_CIV_Worker_3_tie","SPE_CIV_Worker_3_trop","SPE_CIV_Worker_4","SPE_CIV_Worker_4_tie",
            "SPE_CIV_Worker_4_trop"];
        };
        default {
            LV_CUSTOM_SIDE = nil;
            LV_CUSTOM_MEN_ARRAY = nil;
            LV_CUSTOM_CIVILIAN_ARRAY = nil;
            LV_CUSTOM_CIVILIAN_INIT = nil;
            ITW_USE_LV_CUSTOM_UNITS = false;
        };
    };
};

CustomArsenal_GetBoat = {    
    private _map = toLowerANSI worldname;
    private _boat = "";
    switch (_map) do {
        case "stozec":      { _boat = "CSLA_lodka" };
        
        case "vn_khe_sanh";
        case "vn_the_bra";
        case "cam_lao_nam": { _boat = "vn_c_boat_01_00" };
        
        case "gm_weferlingen_summer";
        case "gm_weferlingen_winter";
        case "sefrouramal": {_boat = "B_Boat_Transport_01_F" };
        
        case "enoch";
        default { _boat = selectRandom ["C_Rubberboat","B_Boat_Transport_01_F","I_Boat_Transport_01_F","O_Boat_Transport_01_F","C_Scooter_Transport_01_F"] };
    };
    _boat
};

CustomArsenal_Loadout = {
    // runs where unit is local
    params ["_unit",["_faction",ITW_PlayerFaction]];

    // switch the unit to a random player faction loadout
    _switchLoadout = {
        params ["_unit","_faction"];
        private _unitClassesWieghted = [_faction,
               ["Rifleman",5,"CombatLifeSaver",1,"Grenadier",1,"MachineGunner",1,"Marksman",0.2]
            ] call FactionUnits;        
        // if none of the previous roles are available, use all roles for the faction
        private _check = selectRandom selectRandomWeighted _unitClassesWieghted;
        if (isNil "_check") then {
            _unitClassesWieghted =  [[_faction] call FactionUnits,1];
        };
        private _num = 0;
        for "_i" from 1 to count _unitClassesWieghted step 2 do {
            _num = _num + (_unitClassesWieghted#_i);
        };
        if (_num == 0) then {
            _unitClassesWieghted = [[_faction,[]] call FactionUnits,1];
        };
        // weed out units w/o primary weapon
        private _cnt = 10;
        private _unitClass = "";
        private _loadout = [[]];
        while {_unitClass == "" && _loadout#0 isEqualTo [] && _cnt > 0} do {
            _unitClass = selectRandom selectRandomWeighted _unitClassesWieghted;
            if (isNil "_unitClass") then {_unitClass = "B_Soldier_F"};
            _loadout = _unitClass call ITW_FncGetLoadoutFromClass;
        };
        [_unit, _loadout] call ITW_FncSetUnitLoadout;
        _unit setVariable ["skl_LoadoutClass",_unitClass];    
        _unitClass
    };
    private _unitClass = [_unit,_faction] call _switchLoadout;  
    
    //private _map = if (CustomArsenal_UseCustomLoadout) then {toLowerANSI worldname} else {"default"};
    //switch (_map) do {
    //    case "gm_weferlingen_summer": { 
    //        private _cnt = 20;
    //        while {_cnt > 0 && [uniform _unit,"_win"] call ITW_FncEndsWith} do {
    //            _cnt = _cnt - 1;
    //            _unitClass = [_unit,_faction] call _switchLoadout;
    //        };
    //        _unit linkItem "ItemGPS";
    //        // If player is using sthud, then give them a real compass so the hud shows
    //        if (isClass(configFile >> "CfgPatches" >> "STUI_GroupHUD")) then { 
    //            _unit linkItem "ItemCompass";
    //        } else {
    //            _unit linkItem "gm_ge_army_conat2";
    //        }; 
    //        _unit addItem "gm_ge_army_gauzeBandage";
    //        _unit addItem "gm_ge_army_gauzeBandage";
    //        _unit addItem "gm_smokeshell_grn_gc";
    //        _unit addItem "gm_smokeshell_grn_gc";       
    //    };
    //    case "gm_weferlingen_winter": {  
    //        private _cnt = 20;
    //        while {_cnt > 0 && !([uniform _unit,"_win"] call ITW_FncEndsWith)} do {
    //            _cnt = _cnt - 1;
    //            _unitClass = [_unit,_faction] call _switchLoadout;
    //        };
    //        _unit linkItem "ItemGPS";
    //        // If player is using sthud, then give them a real compass so the hud shows
    //        if (isClass(configFile >> "CfgPatches" >> "STUI_GroupHUD")) then { 
    //            _unit linkItem "ItemCompass";
    //        } else {
    //            _unit linkItem "gm_ge_army_conat2";
    //        };
    //        _unit addItem "gm_ge_army_gauzeBandage";
    //        _unit addItem "gm_ge_army_gauzeBandage";
    //        _unit addItem "gm_smokeshell_grn_gc";
    //        _unit addItem "gm_smokeshell_grn_gc";        
    //    };
    //    case "enoch": { 
    //        _unit addPrimaryWeaponItem "optic_Arco_lush_F";
    //        _unit linkItem "ItemGPS";
    //        _unit addItem "FirstAidKit";
    //        _unit addItem "FirstAidKit";
    //        _unit addItem "SmokeShellGreen";
    //        _unit addItem "SmokeShellGreen";
    //    };
    //    case "stozec": { 
    //        _unit addItem "US85_ANPVS5_Goggles";
    //        _unit addPrimaryWeaponItem "US85_MPV_30Rnd_9Luger";
    //        _unit addWeapon "US85_bino"; // binoculars
    //        _unit addItem "US85_FAK";
    //        _unit addItem "US85_FAK";
    //    };
    //    case "vn_khe_sanh";
    //    case "vn_the_bra";
    //    case "cam_lao_nam": { 
    //        _unit addWeapon "vn_m19_binocs_grey"; 
    //        _unit addItem "vn_b_item_firstaidkit";
    //        _unit addItem "vn_b_item_firstaidkit";
    //        _unit addItem "vn_m18_red_mag";
    //        _unit addItem "vn_m18_red_mag";
    //    };
    //    case "stozec": { 
    //        _unit addItem "US85_ANPVS5_Goggles";
    //        _unit addPrimaryWeaponItem "US85_MPV_30Rnd_9Luger";
    //        _unit addWeapon "US85_bino"; // binoculars
    //        _unit addItem "US85_FAK";
    //        _unit addItem "US85_FAK";
    //    };
    //    case "sefrouramal": {
    //        if (side _unit != civilian) then {
    //            _unit addWeapon "Binocular";
    //            _unit linkItem "ItemGPS";
    //            _unit addItem "FirstAidKit";
    //            _unit addItem "FirstAidKit";
    //            _unit addItem "SmokeShellGreen";
    //            _unit addItem "SmokeShellGreen";
    //        } else {          
    //            // CIVILIANS
    //            removeAllWeapons _unit;
    //            removeAllItems _unit;
    //            removeAllAssignedItems _unit;
    //            removeUniform _unit;
    //            removeVest _unit;
    //            removeBackpack _unit;
    //            removeHeadgear _unit;
    //            removeGoggles _unit;
    //            _unit forceAddUniform selectRandom ["U_lxWS_C_Djella_03","U_lxWS_C_Djella_06","U_lxWS_C_Djella_02","U_lxWS_C_Djella_02a","U_lxWS_C_Djella_07","U_lxWS_C_Djella_05","U_lxWS_C_Djella_04","U_lxWS_C_Djella_01","U_lxWS_Tak_02_B","U_lxWS_Tak_02_C","U_lxWS_Tak_02_A","U_lxWS_Tak_03_B","U_lxWS_Tak_03_A","U_lxWS_Tak_03_C","U_lxWS_Tak_01_C","U_lxWS_Tak_01_B","U_lxWS_Tak_01_A"];
    //            if (random 1 < 0.8) then {
    //                _unit addHeadgear selectRandom ["lxWS_H_cloth_5_A","lxWS_H_cloth_5_B","lxWS_H_cloth_5_C","lxWS_H_turban_03_black","lxWS_H_turban_03_blue","lxWS_H_turban_03_green","lxWS_H_turban_03_green_pattern","lxWS_H_turban_03_orange","lxWS_H_turban_03_red","lxWS_H_turban_03_sand","lxWS_H_turban_03_gray","lxWS_H_turban_03_yellow","lxWS_H_turban_04_black","lxWS_H_turban_04_blue","lxWS_H_turban_04_green","lxWS_H_turban_04_red","lxWS_H_turban_04_sand","lxWS_H_turban_04_gray","lxWS_H_turban_04_yellow","lxWS_H_turban_02_black","lxWS_H_turban_02_blue","lxWS_H_turban_02_green","lxWS_H_turban_02_green_pattern","lxWS_H_turban_02_orange","lxWS_H_turban_02_red","lxWS_H_turban_02_sand","lxWS_H_turban_02_gray","lxWS_H_turban_02_yellow","lxWS_H_turban_01_black","lxWS_H_turban_01_blue","lxWS_H_turban_01_green","lxWS_H_turban_01_red","lxWS_H_turban_01_sand","lxWS_H_turban_01_gray","lxWS_H_turban_01_yellow"];
    //            };
    //            if (random 1 < 0.2) then {
    //                _unit addGoggles selectRandom ["G_Shades_Black","G_Shades_Blue","G_Shades_Green","G_Shades_Red","G_Spectacles","G_Sport_Red","G_Sport_Blackyellow","G_Sport_BlackWhite","G_Sport_Checkered","G_Sport_Blackred","G_Sport_Greenblack","G_Squares","G_Squares_Tinted"];
    //            };
    //            _unit linkItem "ItemWatch";
    //        };
    //    };
    //    default {
    //        if (isPlayer _unit) then {
    //            //_unit addItem "optic_Hamr";
    //            _unit addWeapon "Binocular";
    //            _unit linkItem "ItemGPS";
    //            _unit addItem "FirstAidKit";
    //            _unit addItem "FirstAidKit";
    //            _unit addItem "SmokeShellGreen";
    //            _unit addItem "SmokeShellGreen";
    //        };
    //    };
    //};
       
    // If player is using sthud, then give them a real compass so the hud shows
    if (isClass(configFile >> "CfgPatches" >> "STUI_GroupHUD")) then { 
        _unit linkItem "ItemCompass";
    };
                                                                              
    if (ITW_ParamIdentity > 0) then {[_unit,_faction,_unitClass] call ITW_FncSetIdentity};
        
    // Param to help new player not shoot friendlies
    if (! isNil "ITW_ParamBeginnerMode") then {
        if (ITW_ParamBeginnerMode == 1) then {
            removeHeadgear _unit;
            _unit addHeadgear "H_PASGT_basic_white_F";
        };
    };
};

CustomArsenal_Arsenal = {
    params ["_whatToLoad",["_dlcDoNotLoad",[]]]; 
    // Params:
    // _whatToLoad: 0 = full arsenal, 1 = limited by map, 2 = faction weapons w/ added launchers, 3 = faction weapons only
    // _dlcDoNoLoad: array of dlc to not load into the arsenal when set to full or limited (see FactionDlcId for items)
    
    ITW_ARSENAL_USE_FULL = true;
    if (_whatToLoad == 0 && {_dlcDoNotLoad isEqualTo []}) exitWith {};
    if (_whatToLoad != 2 && {count ("true" configClasses (configFile >> "CfgWeapons")) > 10000}) exitWith {diag_log "ITW: Skipping arsenal setup due to large number of mods"};
    ITW_ARSENAL_USE_FULL = false;
    
    private _removeItems = [  // some items are DLC, but they don't have the dlc tag in the config file
        "O_NVGoggles_grn_F", "ChemicalDetector_01_watch_F"
    ];
    
    // if limited, remove some items from the aresenal
    private _removeWeapons = ["nsw_er7s","nsw_er7a"]; // er7 weapon is broken in Ivanivokova map
    private _removeMagazines = [];
    private _removeBackpacks = [];
    private _aceItems = [];
    
    missionNamespace setVariable ["bis_addVirtualWeaponCargo_cargo",[[],[],[],[]]]; // remove everything
    private _fastLookupTable = uiNamespace getVariable ["bis_fnc_arsenal_data", locationNull];
    {
        _fastLookupTable setVariable [configName _x,false];
    } forEach ( ("true" configClasses (configFile >> "CfgWeapons")) +
				//("true" configClasses (configFile >> "CfgMagazines")) +
                ("true" configClasses (configFile >> "CfgVehicles")) +
				("true" configClasses (configFile >> "CfgGlasses")) );
    
    
#define AddItemToFLT(ARRAY) private _a = (ARRAY - ["Throw","Put",""]); {_fastLookupTable setVariable [_x,true]} forEach _a; _aceItems append _a
     
    private _onlyDlcs = [];
    if (_whatToLoad == 1) then {     
        _dlcFilter = [] call FactionDlcId;
        _dlcFilter params [["_userDlcs",[]],["_removeDLCs",[]]]; 
        _onlyDlcs = _userDlcs;
        _dlcDoNotLoad = _dlcDoNotLoad + _removeDLCs;
    };

    if (_dlcDoNotLoad isEqualTo []) then {_dlcDoNotLoad = ["--NONE--"];}; // we need the array to contain something
    
    private ["_items"];
    if (count _onlyDlcs != 0) then {
        /// ONLY USE SOME DLCS /// 
        //["AmmoboxInit",[missionNamespace,false]] call BIS_fnc_arsenal;         
          
        // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
        //     Backpacks
        // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
        _configs = format ["( (toLowerAnsi configSourceMod _x in %1) &&
            { ( getNumber ( _x >> ""scope"" ) == 2 || getNumber ( _x >> ""scope"" ) == 1 ) && 
            { getNumber ( _x >> ""isbackpack"" ) isEqualTo 1 && toLowerANSI getText ( _x >> 'vehicleClass' ) != 'respawn'
            }})",_onlyDlcs] configClasses ( configFile >> "cfgVehicles");
        _items = [];
        {
            _items pushback configName _x;
        } forEach _configs;
        [missionNamespace,_items] call BIS_fnc_addVirtualBackpackCargo;
        AddItemToFLT(_items);
        
        // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
        //     Weapons
        // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
        _configs = format ["( (toLowerAnsi configSourceMod _x in %1) &&
            { ( getNumber ( _x >> ""scope"" ) == 2 || getNumber ( _x >> ""scope"" ) == 1 ) && 
            { toLowerANSI getText ( _x >> ""simulation"" ) isEqualTo ""weapon"" && 
            { not isText ( _x >> ""ItemInfo"" >> ""type"") }}})",_onlyDlcs] configClasses( configFile >> "CfgWeapons" ); 
        _items = [];
        {
            _items pushback configName _x;
        } forEach _configs;
        [missionNamespace,_items,true] call BIS_fnc_addVirtualWeaponCargo; 
        AddItemToFLT(_items);
        
        // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
        //     Items
        // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
        _configs = format ["( (toLowerAnsi configSourceMod _x in %1) &&
            { ( getNumber ( _x >> ""scope"" ) == 2 || getNumber ( _x >> ""scope"" ) == 1 ) && 
            { ( toLowerANSI getText ( _x >> ""simulation"" ) isEqualTo ""weapon"" && not isText ( _x >> ""ItemInfo"" >> ""type"")) || 
              { toLowerANSI getText ( _x >> ""simulation"" ) != ""weapon""}
            }})",_onlyDlcs] configClasses( configFile >> "CfgWeapons" ); 
        _items = [];
        {
            _items pushback configName _x;
        } forEach _configs;
        [missionNamespace,_items,true] call BIS_fnc_addVirtualItemCargo;
        AddItemToFLT(_items);
            
        // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
        //     Glasses
        // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
        _configs = format ["( (toLowerAnsi configSourceMod _x in %1) &&
            { getNumber ( _x >> ""scope"" ) == 2 || getNumber ( _x >> ""scope"" ) == 1
            })",_onlyDlcs] configClasses( configFile >> "CfgGlasses" ); 
        _items = [];
        {
            _items pushback (configName _x);
        } forEach _configs;
        [missionNamespace,_items,true] call BIS_fnc_addVirtualItemCargo;
        AddItemToFLT(_items);
        
        // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
        //     Ammunition
        // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
        _configs = format ["( (toLowerAnsi configSourceMod _x in %1) &&
            { getNumber ( _x >> ""scope"" ) == 2 })",_onlyDlcs] configClasses ( configFile >> "CfgMagazines" ); 
        _items = [];
        {
            _items pushback (configName _x);
        } forEach _configs;
        [missionNamespace,_items,true] call BIS_fnc_addVirtualMagazineCargo; 
        AddItemToFLT(_items);
        
        // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
        //     Additions
        // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
         
        // some dlc (contacts specifically) don't include some basic items, so lets add the always
        [missionNamespace,["ItemCompass"],true] call BIS_fnc_addVirtualItemCargo;
        [missionNamespace,["FirstAidKit"],true] call BIS_fnc_addVirtualItemCargo;
        [missionNamespace,["1Rnd_HE_Grenade_shell"],true] call BIS_fnc_addVirtualMagazineCargo;
        [missionNamespace,["SmokeShell"],true] call BIS_fnc_addVirtualMagazineCargo;
        [missionNamespace,["HandGrenade"],true] call BIS_fnc_addVirtualMagazineCargo;
        [missionNamespace,["1Rnd_Smoke_Grenade_shell"],true] call BIS_fnc_addVirtualMagazineCargo;
        _items = ["ItemCompass","FirstAidKit","1Rnd_HE_Grenade_shell","SmokeShell","HandGrenade","1Rnd_Smoke_Grenade_shell"];
        AddItemToFLT(_items);
        
        if (ITW_ParamForceNVGs) then {
            [missionNamespace,["NVGoggles"],true] call BIS_fnc_addVirtualItemCargo;
            AddItemToFLT(["NVGoggles"]);
        };
        
    } else {
        if (_whatToLoad != 2 && _whatToLoad != 3) then {
            /// USE ALL DLCS ///
            //["AmmoboxInit",[missionNamespace,false]] call BIS_fnc_arsenal;   
            
            // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
            //     Backpacks
            // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
            _configs = format ["( (!(toLowerAnsi configSourceMod _x in %1)) &&
                { ( getNumber ( _x >> ""scope"" ) == 2 || getNumber ( _x >> ""scope"" ) == 1 ) && 
                { getNumber ( _x >> ""isbackpack"" ) isEqualTo 1 && toLowerANSI getText ( _x >> 'vehicleClass' ) != 'respawn' &&
                { getNumber ( _x >> ""maximumLoad"" ) != 0 }}})",_dlcDoNotLoad] configClasses ( configFile >> "cfgVehicles");
            _items = [];
            {
                _items pushback configName _x;
            } forEach _configs;
            [missionNamespace,_items,true] call BIS_fnc_addVirtualBackpackCargo;  
            AddItemToFLT(_items);   
            
            // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
            //     Weapons
            // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
            _configs = format ["( (!(toLowerAnsi configSourceMod _x in %1)) &&
                { ( getNumber ( _x >> ""scope"" ) == 2 || getNumber ( _x >> ""scope"" ) == 1 ) && 
                { toLowerANSI getText ( _x >> ""simulation"" ) isEqualTo ""weapon"" && 
                { not isText ( _x >> ""ItemInfo"" >> ""type"") }}})",_dlcDoNotLoad] configClasses( configFile >> "CfgWeapons" ); 
            _items = [];
            {
                _items pushback configName _x;
            } forEach _configs;
            [missionNamespace,_items,true] call BIS_fnc_addVirtualWeaponCargo;
            AddItemToFLT(_items);
            
            // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
            //     Items
            // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
            _configs = format ["( (!(toLowerAnsi configSourceMod _x in %1)) &&
                { ( getNumber ( _x >> ""scope"" ) == 2 || getNumber ( _x >> ""scope"" ) == 1 ) &&
                { (toLowerANSI getText ( _x >> ""simulation"" ) isEqualTo ""weapon"" && not isText ( _x >> ""ItemInfo"" >> ""type"")) || 
                  { toLowerANSI getText ( _x >> ""simulation"" ) != ""weapon""}
                }})",_dlcDoNotLoad] configClasses( configFile >> "CfgWeapons" ); 
            _items = [];
            {
                _items pushback configName _x;
            } forEach _configs;
            [missionNamespace,_items,true] call BIS_fnc_addVirtualItemCargo;
            AddItemToFLT(_items);
            
            // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
            //     Glasses
            // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
            _configs = format ["( (!(toLowerAnsi configSourceMod _x in %1)) &&
                { getNumber ( _x >> ""scope"" ) == 2 || getNumber ( _x >> ""scope"" ) == 1 
                })",_dlcDoNotLoad] configClasses( configFile >> "CfgGlasses" ); 
            _items = [];
            {
                _items pushback (configName _x);
            } forEach _configs;
            [missionNamespace,_items,true] call BIS_fnc_addVirtualItemCargo;
            AddItemToFLT(_items);
            
            // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
            //     Ammunition
            // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
            _configs = format ["( (!(toLowerAnsi configSourceMod _x in %1)) &&
                { getNumber ( _x >> ""scope"" ) == 2 })",_dlcDoNotLoad] configClasses ( configFile >> "CfgMagazines" ); 
            _items = [];
            {
                _items pushback (configName _x);
            } forEach _configs;
            [missionNamespace,_items,true] call BIS_fnc_addVirtualMagazineCargo;
            AddItemToFLT(_items);
        } else {
            // Only faction items
            private _weapons = [];
            private _magazines = [];
            private _items = [];
            private _backpacks = [];
            private _backpacksSpecial = [];
            private _factionUnits = [ITW_PlayerFaction] call FactionUnits;
            private _fltWeapons = [];
            {
                private _cfgUnit = (configFile >> "CfgVehicles" >> _x);
                private _wpns = getArray (_cfgUnit >> "weapons");
                { _weapons pushBackUnique _x } forEach _wpns;
                { _magazines pushBackUnique _x } forEach getArray (_cfgUnit >> "magazines");
                { _items pushBackUnique _x } forEach getArray (_cfgUnit >> "linkedItems");
                { _items pushBackUnique _x } forEach getArray (_cfgUnit >> "Items");
                _items pushBackUnique getText (_cfgUnit >> "uniformClass");
                
                {
                    // weapon attachments
                    _weapons pushBackUnique getText (configFile >> "cfgWeapons" >> _x >> "LinkedItems" >> "LinkedItemsOptic" >> "item");
                    _weapons pushBackUnique getText (configFile >> "cfgWeapons" >> _x >> "LinkedItems" >> "LinkedItemsAcc" >> "item");
                    _weapons pushBackUnique getText (configFile >> "cfgWeapons" >> _x >> "LinkedItems" >> "LinkedItemsMuzzle" >> "item");
                    _weapons pushBackUnique getText (configFile >> "cfgWeapons" >> _x >> "LinkedItems" >> "LinkedItemsUnder" >> "item");
                    // base weapon type
                    _weapons pushBackUnique getText (configFile >> "cfgWeapons" >> _x >> "baseWeapon");
                    _fltWeapons pushBackUnique configName (inheritsFrom (configFile >> "cfgWeapons" >> _x));
                } forEach _wpns;
                
                // backpacks need special handling
                private _pack = getText (_cfgUnit >> "backpack");
                private _packCfg = configFile >> "CfgVehicles" >> _pack;
                // backpack items 
                private _ticfg = (_packCfg >> "TransportItems"); 
                private _tp = (_ticfg) call BIS_fnc_getCfgSubClasses; 
                {_items pushBackUnique getText (_ticfg >> _x >> "name") } forEach _tp;
                // backpack magazines
                _ticfg = (_packCfg >> "TransportMagazines"); 
                _tp = (_ticfg) call BIS_fnc_getCfgSubClasses; 
                {_magazines pushBackUnique getText (_ticfg >> _x >> "magazine"); } forEach _tp;
                // backpack weapons
                _ticfg = (_packCfg >> "TransportWeapons"); 
                _tp = (_ticfg) call BIS_fnc_getCfgSubClasses; 
                {_weapons pushBackUnique getText (_ticfg >> _x >> "weapon") } forEach _tp;
                
                // special backpacks don't show in the arsenal, so if its special, use it's parent
                if (getNumber (_packCfg >> "scope") == 2 && toLowerANSI getText (_packCfg >> 'vehicleClass' ) != 'respawn') then {
                    _backpacks pushBackUnique _pack ;
                } else {
                    _backpacksSpecial pushBackUnique _pack;
                    private _parentCfg = inheritsFrom (configFile >> "CfgVehicles">> _pack);
                    if (getNumber (_parentCfg >> "scope") == 2) then {
                        _backpacks pushBackunique configName _parentCfg;
                    };
                };
            } forEach _factionUnits;
            
            [missionNamespace,_backpacks,true] call BIS_fnc_addVirtualBackpackCargo; 
            [missionNamespace,_weapons,true] call BIS_fnc_addVirtualWeaponCargo; 
            [missionNamespace,_items,true] call BIS_fnc_addVirtualItemCargo;   
            [missionNamespace,_magazines,true] call BIS_fnc_addVirtualMagazineCargo;
            AddItemToFLT(_backpacks);
            AddItemToFLT(_backpacksSpecial);
            AddItemToFLT(_weapons);
            AddItemToFLT(_items);
            AddItemToFLT(_magazines);
            AddItemToFLT(_fltWeapons);
            
            if (ITW_ParamForceNVGs) then {
                [missionNamespace,["NVGoggles"],true] call BIS_fnc_addVirtualItemCargo;
                AddItemToFLT(["NVGoggles"]);
            };
            
            //if (_whatToLoad == 2) then {
            //    // make sure we have launchers unlocked
            //    private _launcherUnlocked = false;
            //    {
            //        if (_x isKindOf "LauncherCore") exitWith {_launcherUnlocked = true}
            //    } forEach _weapons;
            //    if (!_launcherUnlocked) then {
            //        [missionNamespace,["launch_MRAWS_sand_rail_F","launch_B_Titan_short_F"],true] call BIS_fnc_addVirtualWeaponCargo; 
            //        [missionNamespace,["MRAWS_HEAT_F", "MRAWS_HE_F", "MRAWS_HEAT55_F","Titan_AT", "Titan_AP"],true] call BIS_fnc_addVirtualMagazineCargo;  
            //        // AA
            //        [missionNamespace,["launch_B_Titan_F"],true] call BIS_fnc_addVirtualWeaponCargo; 
            //        [missionNamespace,["Titan_AA"],true] call BIS_fnc_addVirtualMagazineCargo;
            //        _items = ["launch_MRAWS_sand_rail_F","launch_B_Titan_short_F","MRAWS_HEAT_F", "MRAWS_HE_F", "MRAWS_HEAT55_F","Titan_AT", "Titan_AP","launch_B_Titan_F","Titan_AA"];
            //        AddItemToFLT(_items);
            //    };
            //};
        };
    };
    
    // Custom Aresenal Loadout adds items, so just allow those all the time
    _items = ["optic_Hamr","Binocular","ItemGPS","FirstAidKit","ItemCompass","ItemMap","ItemWatch","ItemRadio","SmokeShellGreen","optic_Arco_lush_F",
              "US85_ANPVS5_Goggles","US85_MPV_30Rnd_9Luger","US85_bino","US85_FAK",
              "vn_m19_binocs_grey","vn_b_item_firstaidkit","vn_m18_red_mag",
              "gm_smokeshell_grn_gc","gm_ge_army_gauzeBandage","gm_ge_army_conat2",
              "ACE_EHP","ACE_EarPlugs"];
    AddItemToFLT(_items);
    
    if (count _removeItems > 0)     then { [missionNamespace,_removeItems,true]     call BIS_fnc_removeVirtualItemCargo;     };
    if (count _removeBackpacks > 0) then { [missionNamespace,_removeBackpacks,true] call BIS_fnc_removeVirtualBackpackCargo; };
    if (count _removeWeapons > 0)   then { [missionNamespace,_removeWeapons,true]   call BIS_fnc_removeVirtualWeaponCargo;   };
    if (count _removeMagazines > 0) then { [missionNamespace,_removeMagazines,true] call BIS_fnc_removeVirtualMagazineCargo; };
    
    // block items from being loaded from previous arsenal saved loadouts
    {
        _fastLookupTable setVariable [_x,false];
    } forEach (_removeItems + _removeBackpacks + _removeWeapons + _removeMagazines);
    
    // allow people with ACE to use ACE arsenal
    if (!isNil "ace_arsenal_fnc_removeVirtualItems" && {ITW_ParamAceArsenal == 1}) then {
        if (count _removeItems > 0)     then { _aceItems = _aceItems - _removeItems     };
        if (count _removeBackpacks > 0) then { _aceItems = _aceItems - _removeBackpacks };
        if (count _removeWeapons > 0)   then { _aceItems = _aceItems - _removeWeapons   };
        if (count _removeMagazines > 0) then { _aceItems = _aceItems - _removeMagazines };
        ITW_AceItems = _aceItems;
    };
};

CustomArsenal_AddVAs = {
    params ["_cabinetArray",["_addAction",true],["_actionDistance",4]];
    
    // need some waits if called during JIP
    waitUntil {! isNil "ITW_ParamAceArsenal"};
    waitUntil {! isNil "CUSTOM_ARSENAL_SETUP_COMPLETE"};
    
    if (typeName _cabinetArray == "OBJECT") then {_cabinetArray = [_cabinetArray]};
    if (typeName _cabinetArray != "ARRAY") exitWith {
        diag_log format ["Error Pos: CustomArsenal_AddVAs: invalid parameter type should be array (type %1)",typeName _cabinetArray];
    };
    if (count _cabinetArray == 0) exitWith {};
    if (typeName (_cabinetArray#0) == "ARRAY") then {_cabinetArray = _cabinetArray#0};
    
    if (!isNil "ace_arsenal_fnc_removeVirtualItems" && {ITW_ParamAceArsenal == 1}) then {
        // add ACE arsenal
        if (ITW_ARSENAL_USE_FULL || {isNil "ITW_AceItems" && isNil "CustomArsenal_AceCargo"}) then {
            if (_addAction) then {
                {
                    _x addAction["ACE Arsenal", {[_this#0, player, true] call ace_arsenal_fnc_openBox}, nil, 10, true, true, "", "true",_actionDistance];
                } forEach _cabinetArray;
            };
        } else {
            if (isNil "CustomArsenal_AceCargo") then {
                private _cabinet = _cabinetArray#0;
                [_cabinet, true, false] call ace_arsenal_fnc_removeVirtualItems;
                [_cabinet, ITW_AceItems] call ace_arsenal_fnc_addVirtualItems;
                CustomArsenal_AceCargo = _cabinet getVariable ["ace_arsenal_virtualItems", []];
            };
            {           
                _x setVariable ["ace_arsenal_virtualItems", CustomArsenal_AceCargo];
                if (_addAction) then {
                    _x addAction["ACE Arsenal", {[_this#0, player, false] call ace_arsenal_fnc_openBox}, nil, 10, true, true, "", "true",_actionDistance];
                };
            } forEach _cabinetArray;
        };
    } else {
        if (isNil "ITW_ARSENAL_USE_FULL") then {
            ITW_ARSENAL_USE_FULL = false;
            waitUntil {! isNil "ITW_ParamVirtualArsenal"};
            if (ITW_ParamVirtualArsenal == 0) then {ITW_ARSENAL_USE_FULL = true};
            if (ITW_ParamVirtualArsenal != 2 && {count ("true" configClasses (configFile >> "CfgWeapons")) > 10000}) then {ITW_ARSENAL_USE_FULL = true};
        };
        if (_addAction) then {
            if (ITW_ARSENAL_USE_FULL) then {
                {
                    _x addAction ["Arsenal",{["Open",true,missionNamespace] call BIS_fnc_arsenal},nil,1.3,true,true,"","true",_actionDistance];
                } forEach _cabinetArray;
            } else {
                // add BIS arsenal (just add a mag to enable the arsenal)
                {
                    [_x,["16Rnd_9x21_Mag"],false,true] call BIS_fnc_addVirtualMagazineCargo;
                    if (!isNil "ace_arsenal_fnc_removeVirtualItems") then {[_x,["ACE_EHP","ACE_EarPlugs"],false,true] call BIS_fnc_addVirtualItemCargo};
                } forEach _cabinetArray;
            };
        };
    };
};

CustomArsenal_GetLauncher = {
    params ["_addAT"];
    private ["_weapon","_ammo"];
    if (_addAt) then { 
        if (random 100 < 50) then {
            _weapon = "launch_MRAWS_olive_rail_F";
            _ammo = "MRAWS_HE_F";
        } else {
            _weapon = "launch_O_Titan_short_F";
            _ammo = "Titan_AT";
        };
    } else {
        _weapon = "launch_O_Titan_F";
        _ammo = "Titan_AA";
    };
    [_weapon,_ammo]
};


["CustomArsenal_Init"] call SKL_fnc_CompileFinal;
["CustomArsenal_Setup"] call SKL_fnc_CompileFinal;
["CustomArsenal_LVInit"] call SKL_fnc_CompileFinal;
["CustomArsenal_GetBoat"] call SKL_fnc_CompileFinal;
["CustomArsenal_Loadout"] call SKL_fnc_CompileFinal;
["CustomArsenal_Arsenal"] call SKL_fnc_CompileFinal;
["CustomArsenal_AddVAs"] call SKL_fnc_CompileFinal;
["CustomArsenal_GetLauncher"] call SKL_fnc_CompileFinal;
