
params ["_enemyFaction",["_playerFaction","ALL_NON_ENEMY_FACTIONS"],["_options",[]]];

private _playerFactionIsAllNonEnemy = false;
if (_playerFaction isEqualTo "ALL_NON_ENEMY_FACTIONS") then {_playerFaction = ["BLU_F","CIV_F"];_playerFactionIsAllNonEnemy=true};
// VEHICLE_ARRAYS_COMPLETE will be true upon completion
diag_log "Vehicle Arrays Processing Started";

private _validOptions = [
    "EnsureQuadBike",     // ensure quadbike array is not empty
    "EnsureCarTransport", // ensure EnsureCarTransport is not empty
    "EnsureSupports",     // ensure ammoClasses, fuelClasses, and repairClasses is not empty
    "EnsureBoats",        // ensure at least one boat type
    "NoTrucks"            // remove large trucks from the carClasses & carTransportClasses
];

{
    private _opt = _x;
    if !(_opt in _validOptions) then {
        private _found = "";
        private _optLower = toLowerANSI _opt;
        {
            if (_optLower == toLowerANSI _x) exitWith {
                _found = _x;
            };
        } forEach _validOptions;
        if (_found isEqualTo "") then {
            private _msg = format ["ERROR: VehiclesArrays.sqf: invalid option %1",_opt];
            diag_log _msg;
            [_msg,"ERROR"] call BIS_fnc_guiMessage;
        } else {
            _options set [_forEachIndex,_found];
        };
    };
} forEach _options;

#define MIN_CARGO_SEATS_FOR_TRANSPORT 6
#define MIN_ABS_CARGO_SEATS_FOR_TRANSPORT 4

//va_airports = [];  //airports array in form [ilsPosition,ilsDirection,ilsTaxiOff,ilsTaxiIn] (see Arma_3_Dynamic_Airport_Configuration)

// Car, Heli, Tank, Apc, Plane all are subdivided into
//  va_pXxxxClassesAttack
//  va_pXxxxClassesTransport
//  va_pXxxxClassesDual
// and for va_eXxxx as well

va_pOfficerClasses = [];
va_pCarClasses = [];
va_pQuadBikeClasses = [];
va_pTankClasses = [];
va_pApcClasses = [];
va_pArtyClasses = [];
va_pMortarClasses = [];
va_pHeliClasses = [];
va_pPlaneClasses = [];
va_pShipClasses = [];
va_pFuelClasses = [];
va_pRepairClasses = [];
va_pAmmoClasses = [];
va_pGenericNames = [];
va_pLanguage = [];
va_pUAVClasses = [];
va_pInfClassesForWeights = [];
va_pInfClassWeights = [];
va_pStaticClasses = [];
va_pAAClasses = [];
va_pDriverlessVehicles = [];
va_pAllVehicles = [];

va_eOfficerClasses = [];
va_eCarClasses = [];
va_eQuadBikeClasses = [];
va_eTankClasses = [];
va_eApcClasses = [];
va_eArtyClasses = [];
va_eMortarClasses = [];
va_eHeliClasses = [];
va_ePlaneClasses = [];
va_eShipClasses = [];
va_eFuelClasses = [];
va_eRepairClasses = [];
va_eAmmoClasses = [];
va_eGenericNames = [];
va_eLanguage = [];
va_eUAVClasses = [];
va_eInfClassesForWeights = [];
va_eInfClassWeights = [];
va_eStaticClasses = [];
va_eAAClasses = [];

va_cOfficerClasses = [];
va_cCarClasses = [];
va_cQuadBikeClasses = [];
va_cHeliClasses = [];
va_cPlaneClasses = [];
va_cShipClasses = [];
va_cGenericNames = [];
va_cLanguage = [];
va_cUAVClasses = [];
va_cRepairClasses = [];
va_cAmmoClasses = [];
va_cFuelClasses = [];
 
#define SIDE_NONE      -1
#define SIDE_EAST       0		
#define SIDE_WEST       1		
#define SIDE_RESISTANCE 2
#define SIDE_CIVILIAN   3
private _sideFix = {
    // CSLA DLC has the vehicle side as a string, which is wrong  
    params ["_cfgName","_sideStr"];
    _side = 
        switch (toLowerANSI _sideStr) do {
            case "teast": {SIDE_EAST};
            default {
                diag_log format ["Invalid vehicle side: %1 %2",_cfgName,_sideStr];
                SIDE_NONE
            };
        };
    _side
};

private _playerFactions = [_playerFaction] call FactionConvertToBaseList;
private _enemyFactions = [_enemyFaction] call FactionConvertToBaseList;
private _civFactions = [ITW_CivFaction] call FactionConvertToBaseList;
private _playerSideNum = [_playerFactions,true] call FactionSideNum;
private _enemySideNum = [_enemyFactions,true]  call FactionSideNum;
private _dlcOkay = true;
//([] call FactionDlcId) params ["_customDLCs","_removeDlcs"];
if (isNil "ITW_VehicleDlcs") then {ITW_VehicleDlcs = []};
private _customDLCs = [];
{
    if (typeName _x == "STRING") then {
        _customDLCs pushBack toLowerANSI _x;
    };
} forEach ITW_VehicleDlcs;

{
    private _cfgName = configName _x;
    private _cfg = (configFile >> "CfgVehicles" >> _cfgName);
    
    if (_cfgName isKindOf "Wreck_Base" || 
        { toUpperANSI ((_cfg >> "vehicleClass") call BIS_fnc_getCfgData)   find "WRECKS" >= 0 ||
        { toUpperANSI ((_cfg >> "editorCategory") call BIS_fnc_getCfgData) find "WRECKS" >= 0
        }}) then {continue};
    
    private _cfgFaction = (toUpperANSI ((_cfg >> "faction") call BIS_fnc_getCfgData));
    private _isGlobalCivFaction = if ((_cfgFaction find "CIV_") == 0) then {true} else {false};
    private ["_isPlayerFaction","_isEnemyFaction","_isCivFaction"];
    switch (ITW_ParamVehicles) do {
        case 0: {
            // full
            _isPlayerFaction = !_isGlobalCivFaction;
            _isEnemyFaction  = !_isGlobalCivFaction;
            _isCivFaction = _isGlobalCivFaction;
        };
        case 1: { 
            // side       
            private _cfgSide = ((_cfg >> "side") call BIS_fnc_getCfgData);
            if (typeName _cfgSide != "SCALAR") then {_cfgSide = [_cfgName,_cfgSide] call _sideFix};    
            _isPlayerFaction = if (_cfgSide in _playerSideNum) then {true} else {false};
            _isEnemyFaction  = if (_cfgSide in _enemySideNum ) then {true} else {false};
            _isCivFaction = _isGlobalCivFaction;
        };
        case 2: {
            // selected DLC
            private _dlc = toLowerANSI configSourceMod _cfg;
            if (/*!(_dlc in _removeDLCs) AND */((count _customDLCs == 0) OR (_dlc in _customDLCs))) then {
                private _cfgSide = ((_cfg >> "side") call BIS_fnc_getCfgData);       
                if (typeName _cfgSide != "SCALAR") then {_cfgSide = [_cfgName,_cfgSide] call _sideFix};    
                _isPlayerFaction = _cfgSide in _playerSideNum;
                _isEnemyFaction  = _cfgSide in _enemySideNum ;
                _isCivFaction    = _cfgSide == 3/* civilian*/;
            } else {
                _dlcOkay = false;
                _isPlayerFaction = false;
                _isEnemyFaction  = false;
                _isCivFaction = false;
            };
        };
        default {
            // faction
            _isPlayerFaction = _cfgFaction in _playerFactions;
            _isEnemyFaction  = _cfgFaction in _enemyFactions;
            _isCivFaction    = _cfgFaction in _civFactions;
        };
    };
    if (_playerFactionIsAllNonEnemy) then {
        _isPlayerFaction = !_isEnemyFaction;
        if (((_cfgFaction find "CIV_") == 0) or (_cfgFaction == "Default")) then { 
            // civilian vehicle or wreck
            _isPlayerFaction = false;
        }; 
    };

    if (_isEnemyFaction || _isPlayerFaction || _isCivFaction) then {
        if (getNumber (_cfg >> "isUav") != 0) exitWith {};  // no uav/ugv
        
        private _exit = false;
        {
            if (_cfgName isEqualTo _x) exitWith {_exit = true};
        } forEach ["vn_o_static_rsna75","CUP_WV_B_CRAM","CUP_WV_B_RAM_Launcher","CUP_WV_B_SS_Launcher"];        
        if (_exit) exitWith {};
        
        {
            if (_cfgName isKindOf _x) exitWith {_exit = true};
        } forEach ["Building","gm_searchlight_base","gm_biber_base"];
        if (_exit) exitWith {};
        
        if (_cfgName isKindOf 'Man') then {	                
            if ( ["officer", _cfgName, false] call BIS_fnc_inString ) then {
                if (_isPlayerFaction) then {
                    va_pOfficerClasses pushBack _cfgName;
                };
                if (_isEnemyFaction) then {
                    va_eOfficerClasses pushBack _cfgName;
                };
                if (_isCivFaction) then {
                    va_cOfficerClasses pushBack _cfgName;
                };
            };
        } else {
            if (getNumber(_cfg >> "hasDriver") == -1) then {
                // ignore driverless vehicles:    if (_isPlayerFaction) then {va_pDriverlessVehicles pushBackUnique _cfgName}; 
                continue
            };
            _checkSubcats = true;
            if (_cfgName isKindOf 'Car') then {				
                _edSubcat = ((_cfg >> "editorSubcategory") call BIS_fnc_getCfgData);
                if (!isNil "_edSubcat") then {
                    if (_edSubcat == "EdSubcat_Drones") then {
                        
                    } else {
                        if (["apc", _edSubcat, false] call BIS_fnc_inString) then {
                            if (_isPlayerFaction) then {
                                va_pApcClasses pushBackUnique _cfgName;
                            } else {
                                if (_isCivFaction) then {
                                    va_eApcClasses pushBackUnique _cfgName;
                                };
                            };
                        } else {
                            if (_cfgName isKindOf "Quadbike_01_base_F" || {_cfgName isKindOf "Motorcycle" || {_cfgName isKindOf "vn_bicycle_base" || {_cfgName isKindOf "gm_wheeled_bicycle_base"}}}) then {
                                if (_isPlayerFaction) then {
                                    va_pQuadBikeClasses pushBackUnique _cfgName;
                                    
                                } else {
                                    if (_isEnemyFaction) then {
                                        va_eQuadBikeClasses pushBackUnique _cfgName;
                                    } else {
                                        if (_isCivFaction) then {
                                            va_cQuadBikeClasses pushBackUnique _cfgName;
                                        };
                                    };
                                };
                            } else {
                                if (_isPlayerFaction) then {
                                    va_pCarClasses pushBackUnique _cfgName;
                                    
                                } else {
                                    if (_isEnemyFaction) then {
                                        va_eCarClasses pushBackUnique _cfgName;
                                    } else {
                                        if (_isCivFaction) then {
                                            va_cCarClasses pushBackUnique _cfgName;
                                        };
                                    };
                                };
                                _checkSubcats = false;	 
                            };
                        };
                    };
                };	
                _pVars = [va_pRepairClasses, va_pAmmoClasses, va_pFuelClasses];
                _eVars = [va_eRepairClasses, va_eAmmoClasses, va_eFuelClasses];
                _cVars = [va_cRepairClasses, va_cAmmoClasses, va_cFuelClasses];
                {
                    if (getNumber (_cfg >> _x) > 100 ) then {
                        if (_isPlayerFaction) then {
                            (_pVars select _forEachIndex) pushBackUnique _cfgName;
                        };
                        if (_isEnemyFaction) then {
                            (_eVars select _forEachIndex) pushBackUnique _cfgName;
                        };
                        if (_isCivFaction) then {
                            (_cVars select _forEachIndex) pushBackUnique _cfgName;
                        };
                    };
                } forEach ["transportRepair","transportAmmo","transportFuel"];                
            } else {
                if (_cfgName isKindOf 'Tank') then {
                    _edSubcat = ((_cfg >> "editorSubcategory") call BIS_fnc_getCfgData);
                    if (
                        !(["artillery", _edSubcat, false] call BIS_fnc_inString) &&
                        {!(["aa", _edSubcat, false] call BIS_fnc_inString) &&
                        {!(_cfgName isKindOf "gm_biber_base")
                    }}) then {
                        if (_isPlayerFaction) then {
                            if (["apc", _edSubcat, false] call BIS_fnc_inString) then {
                                va_pApcClasses pushBackUnique _cfgName;
                            } else {
                                va_pTankClasses pushBackUnique _cfgName;
                            };
                        };
                        if (_isEnemyFaction) then {
                            if (["apc", _edSubcat, false] call BIS_fnc_inString) then {
                                va_eApcClasses pushBackUnique _cfgName;
                            } else {
                                va_eTankClasses pushBackUnique _cfgName;
                            };
                        };
                        _checkSubcats = false;
                    };					
                };
            };
            if (_checkSubcats) then {
                _pVars = [va_pMortarClasses, va_pStaticClasses, va_pStaticClasses, va_pStaticClasses, va_pStaticClasses, va_pStaticClasses];
                _eVars = [va_eMortarClasses, va_eStaticClasses, va_eStaticClasses, va_eStaticClasses, va_eStaticClasses, va_eStaticClasses];
                {						
                    if (_cfgName isKindOf _x) exitWith {  
                        if (_isPlayerFaction) then {
                            (_pVars select _forEachIndex) pushBackUnique _cfgName;
                        };
                        if (_isEnemyFaction) then {
                            (_eVars select _forEachIndex) pushBackUnique _cfgName;
                        };
                        _checkSubcats = false;
                    };
                } forEach ["StaticMortar", "StaticMGWeapon", "StaticGrenadeLauncher", "StaticCannon", "StaticAAWeapon", "gm_staticWeapon_base"];	
            };
            if (_checkSubcats) then {
                _edSubcat = ((_cfg >> "editorSubcategory") call BIS_fnc_getCfgData);
                if (!isNil "_edSubcat") then {                        
                    _pVars = [va_pArtyClasses, va_pAAClasses, va_pTankClasses, va_pApcClasses, va_pHeliClasses, va_pPlaneClasses, va_pShipClasses, va_pUAVClasses];
                    _eVars = [va_eArtyClasses, va_eAAClasses, va_eTankClasses, va_eApcClasses, va_eHeliClasses, va_ePlaneClasses, va_eShipClasses, va_eUAVClasses];
                    _cVars = [[], [], [], [], va_cHeliClasses, va_cPlaneClasses, va_cShipClasses, va_cUAVClasses];
                    {						
                        if ( [_x, _edSubcat, false] call BIS_fnc_inString ) exitWith {
                            if (_isPlayerFaction) then {
                                (_pVars select _forEachIndex) pushBackUnique _cfgName;
                            };
                            if (_isEnemyFaction) then {
                                (_eVars select _forEachIndex) pushBackUnique _cfgName;
                            };
                            if (_isCivFaction && {!((_cVars select _forEachIndex) isEqualTo [])} ) then {
                                (_cVars select _forEachIndex) pushBackUnique _cfgName;
                            };
                        };
                    } forEach ["artillery", "aa", "tank", "apc", "helicopter", "plane", "boat", "drone"];					
                };
            };
        };
    };
} forEach ("(getNumber (_x >> 'scope') == 2) || {(getNumber (_x >> 'scope') == 1) && (getNumber (_x >> 'scopeCurator') == 2)}" configClasses (configFile / "CfgVehicles"));

if ("EnsureCarTransport" in _options) then {
    if (va_eCarTransportClasses isEqualTo []) then { 
        va_eCarTransportClasses = ["I_G_Van_01_fuel_F", "O_G_Van_01_fuel_F", "O_G_Van_01_fuel_F", "B_G_Offroad_01_repair_F", "B_G_Van_01_transport_F", "C_Van_01_fuel_F", "C_Offroad_01_comms_F", "C_Offroad_01_repair_F", "C_Van_02_serviva_F", "C_Truck_02_fuel_F", "C_Truck_02_box_F", "C_Truck_02_transport_F", "C_Truck_02_covered_F","C_Hatchback_01_sport_F"]; 
    };
    if (va_pCarTransportClasses isEqualTo []) then { 
        va_pCarTransportClasses = ["I_G_Van_01_fuel_F", "O_G_Van_01_fuel_F", "O_G_Van_01_fuel_F", "B_G_Offroad_01_repair_F", "B_G_Van_01_transport_F", "C_Van_01_fuel_F", "C_Offroad_01_comms_F", "C_Offroad_01_repair_F", "C_Van_02_serviva_F", "C_Truck_02_fuel_F", "C_Truck_02_box_F", "C_Truck_02_transport_F", "C_Truck_02_covered_F","C_Hatchback_01_sport_F"]; 
    };
};

if ("EnsureSupports" in _options) then {
    if (va_pRepairClasses isEqualTo []) then {va_pRepairClasses = ["C_Truck_02_box_F"]};
    if (va_eRepairClasses isEqualTo []) then {va_eRepairClasses = ["C_Truck_02_box_F"]};
    if (va_pAmmoClasses isEqualTo []) then {va_pAmmoClasses = ["I_Truck_02_ammo_F"]};
    if (va_eAmmoClasses isEqualTo []) then {va_eAmmoClasses = ["I_Truck_02_ammo_F"]};
    if (va_pFuelClasses isEqualTo []) then {va_pFuelClasses = ["C_Truck_02_fuel_F"]};
    if (va_eFuelClasses isEqualTo []) then {va_eFuelClasses = ["C_Truck_02_fuel_F"]};
};

if ("EnsureQuadBike" in _options) then {
    if (va_eQuadBikeClasses isEqualTo []) then {
        if (va_cQuadBikeClasses isEqualTo []) then {
            switch (toLowerANSI worldName) do {
                case "stozec": {va_eQuadBikeClasses = ["CSLA_CIV_JARA250","US85_TT650"]};
                case "vn_khe_sanh";
                case "vn_the_bra";
                case "cam_lao_nam": {va_eQuadBikeClasses = ["vn_o_bicycle_01_nva65","vn_c_wheeled_m151_01"]};
                case "spex_utah_beach";
                case "spex_carentan";
                case "spe_mortain";
                case "spe_normandy": {va_eQuadBikeClasses = ["C_Tractor_01_F"]};
                case "gm_weferlingen_winter";
                case "gm_weferlingen_summer": {va_eQuadBikeClasses = ["gm_ge_army_k125"]};    
                default {
                    if ("vn" in _customDLCs) then {
                        va_eQuadBikeClasses = ["vn_o_bicycle_01_nva65","vn_c_wheeled_m151_01"]; // SOG Prairie Fire
                    } else {
                        if ("gm" in _customDLCs) then {
                            va_eQuadBikeClasses = ["gm_ge_army_k125"]; // global mobilization
                        } else {
                            if ("spe" in _customDLCs) then {
                                va_eQuadBikeClasses = ["C_Tractor_01_F"]; // Spearhead 1944
                            } else {
                                if ("csla" in _customDLCs) then {
                                    va_eQuadBikeClasses = ["CSLA_CIV_JARA250","US85_TT650"]; // CSLA Iron Curtain
                                } else {
                                    va_eQuadBikeClasses = ["C_Quadbike_01_black_F","C_Quadbike_01_blue_F","C_Quadbike_01_red_F","C_Quadbike_01_white_F"];
                                };
                            };
                        };
                    };
                };
            };            
        } else {
            va_eQuadBikeClasses = va_cQuadBikeClasses;
        };
    };
    if (va_pQuadBikeClasses isEqualTo []) then {
        if (va_cQuadBikeClasses isEqualTo []) then {
            switch (toLowerANSI worldName) do {
                case "stozec": {va_pQuadBikeClasses = ["CSLA_CIV_JARA250","US85_TT650"]};
                case "vn_khe_sanh";
                case "vn_the_bra";
                case "cam_lao_nam": {va_pQuadBikeClasses = ["vn_o_bicycle_01_nva65","vn_c_wheeled_m151_01"]};
                case "spex_utah_beach";
                case "spex_carentan";
                case "spe_mortain";
                case "spe_normandy": {va_pQuadBikeClasses = ["C_Tractor_01_F"]};
                case "gm_weferlingen_winter";
                case "gm_weferlingen_summer": {va_pQuadBikeClasses = ["gm_ge_army_k125"]};    
                default {
                    if ("vn" in _customDLCs) then {
                        va_pQuadBikeClasses = ["vn_o_bicycle_01_nva65","vn_c_wheeled_m151_01"]; // SOG Prairie Fire
                    } else {
                        if ("gm" in _customDLCs) then {
                            va_pQuadBikeClasses = ["gm_ge_army_k125"]; // global mobilization
                        } else {
                            if ("spe" in _customDLCs) then {
                                va_pQuadBikeClasses = ["C_Tractor_01_F"]; // Spearhead 1944
                            } else {
                                if ("csla" in _customDLCs) then {
                                    va_pQuadBikeClasses = ["CSLA_CIV_JARA250","US85_TT650"]; // CSLA Iron Curtain
                                } else {
                                    va_pQuadBikeClasses = ["C_Quadbike_01_black_F","C_Quadbike_01_blue_F","C_Quadbike_01_red_F","C_Quadbike_01_white_F"];
                                };
                            };
                        };
                    };
                };
            };
        } else {
            va_pQuadBikeClasses = va_cQuadBikeClasses;
        };
    };
};

// AIRPORTS
//try {
//    _airport = [];
//    _airport pushBack ((configFile >> "CfgWorlds" >> worldName >> "ilsPosition") call BIS_fnc_getCfgData);
//    _airport pushBack ((configFile >> "CfgWorlds" >> worldName >> "ilsDirection") call BIS_fnc_getCfgData);
//    _airport pushBack ((configFile >> "CfgWorlds" >> worldName >> "ilsTaxiOff") call BIS_fnc_getCfgData);
//    _airport pushBack ((configFile >> "CfgWorlds" >> worldName >> "ilsTaxiIn") call BIS_fnc_getCfgData);
//    va_airports pushBack _airport;
//} catch {};
//
//try {
//    {
//        _airport = [];
//        _airport pushBack ((_x >> "ilsPosition") call BIS_fnc_getCfgData);
//        _airport pushBack ((_x >> "ilsDirection") call BIS_fnc_getCfgData);
//        _airport pushBack ((_x >> "ilsTaxiOff") call BIS_fnc_getCfgData);
//        _airport pushBack ((_x >> "ilsTaxiIn") call BIS_fnc_getCfgData);
//        va_airports pushBack _airport;
//    } forEach ("true" configClasses (configFile / "CfgWorlds" / worldName / "SecondaryAirports")); 
//} catch {};


// handle if player asked to replace some of the vehicles
if (ITW_ParamVehicleChooser == 1 || {ITW_ParamVehicleChooser == 3}) then {
    // enemy override
    private _tnk = [ITW_EnemyVehicles,"Tnk",true] call VehicleChooser_Get;
    private _apc = [ITW_EnemyVehicles,"Apc",true] call VehicleChooser_Get;
    private _car = [ITW_EnemyVehicles,"Car",true] call VehicleChooser_Get;
    private _hel = [ITW_EnemyVehicles,"Hel",true] call VehicleChooser_Get;
    private _pla = [ITW_EnemyVehicles,"Pla",true] call VehicleChooser_Get;
    private _nav = [ITW_EnemyVehicles,"Nav",true] call VehicleChooser_Get;
    private _sta = [ITW_EnemyVehicles,"Sta",true] call VehicleChooser_Get;
    
    va_eTankClasses   = [];
    va_eAAClasses     = [];
    va_eApcClasses    = [];
    va_eCarClasses    = [];
    va_eHeliClasses   = [];
    va_ePlaneClasses  = [];
    va_eShipClasses   = [];
    va_eMortarClasses = [];
    va_eStaticClasses = [];
    va_eQuadBikeClasses = [];
    va_eRepairClasses = ["C_Truck_02_box_F"];
    va_eAmmoClasses = ["I_Truck_02_ammo_F"];
    va_eFuelClasses = ["C_Truck_02_fuel_F"];
    
    if !(_tnk isEqualTo []) then {va_eTankClasses   = _tnk; va_eAAClasses = _tnk};
    if !(_apc isEqualTo []) then {va_eApcClasses    = _apc};
    if !(_car isEqualTo []) then {va_eCarClasses    = _car};
    if !(_hel isEqualTo []) then {va_eHeliClasses   = _hel};
    if !(_pla isEqualTo []) then {va_ePlaneClasses  = _pla};
    if !(_nav isEqualTo []) then {va_eShipClasses   = _nav};
    if !(_sta isEqualTo []) then {va_eMortarClasses = _sta; va_eStaticClasses = _sta};
    
    if (!(_tnk isEqualTo []) && { (_apc isEqualTo [])}) then {va_eApcClasses = va_eTankClasses};
    if ( (_tnk isEqualTo []) && {!(_apc isEqualTo [])}) then {va_eTankClasses = va_eApcClasses};
    va_eTankAndApcClasses = va_eTankClasses + va_eApcClasses;
};

if (ITW_ParamVehicleChooser == 2 || {ITW_ParamVehicleChooser == 3}) then {
    // player override    
    private _tnk = [ITW_PlayerVehicles,"Tnk",true] call VehicleChooser_Get;
    private _apc = [ITW_PlayerVehicles,"Apc",true] call VehicleChooser_Get;
    private _car = [ITW_PlayerVehicles,"Car",true] call VehicleChooser_Get;
    private _hel = [ITW_PlayerVehicles,"Hel",true] call VehicleChooser_Get;
    private _pla = [ITW_PlayerVehicles,"Pla",true] call VehicleChooser_Get;
    private _nav = [ITW_PlayerVehicles,"Nav",true] call VehicleChooser_Get;
    private _sta = [ITW_PlayerVehicles,"Sta",true] call VehicleChooser_Get;
    
    va_pTankClasses   = [];
    va_pApcClasses    = [];
    va_pCarClasses    = [];
    va_pHeliClasses   = [];
    va_pPlaneClasses  = [];
    va_pShipClasses   = [];
    va_pMortarClasses = [];
    va_pStaticClasses = [];
    va_pQuadBikeClasses = [];
    va_pRepairClasses = ["C_Truck_02_box_F"];
    va_pAmmoClasses = ["I_Truck_02_ammo_F"];
    va_pFuelClasses = ["C_Truck_02_fuel_F"];
    va_pAAClasses = [];
    va_pArtyClasses = [];
    
    if !(_tnk isEqualTo []) then {va_pTankClasses   = _tnk;                           };
    if !(_apc isEqualTo []) then {va_pApcClasses    = _apc;                           };
    if !(_car isEqualTo []) then {va_pCarClasses    = _car;                           };
    if !(_hel isEqualTo []) then {va_pHeliClasses   = _hel;                           };
    if !(_pla isEqualTo []) then {va_pPlaneClasses  = _pla;                           };
    if !(_nav isEqualTo []) then {va_pShipClasses   = _nav;                           };
    if !(_sta isEqualTo []) then {va_pMortarClasses = _sta; va_pStaticClasses = _sta; };
    
    if (!(_tnk isEqualTo []) && { (_apc isEqualTo [])}) then {va_pApcClasses = va_pTankClasses};
    if ( (_tnk isEqualTo []) && {!(_apc isEqualTo [])}) then {va_pTankClasses = va_pApcClasses};
    va_pTankAndApcClasses = va_pTankClasses + va_pApcClasses;
};

// split Tank,Apc,Heli,Car into attack/transport/dual
private _fnAttackTransportSplit = {
    params ["_varArray","_minCargoSeats"];
    private _array = call compile _varArray;
    private _attack = [];
    private _transport = [];
    private _dual = [];
    {        		
        private _vehType = _x;
        private _class = if (typeName _vehType isEqualTo "STRING") then {_x} else {_x#0};
        private _cfg = configFile >> "CfgVehicles" >> _class;
        private _turrets = false;
        private _transportSeats = getNumber (_cfg >> "transportSoldier");
        private _fnc_turretsFFV = 
            {
                {
                    if (getText (_x >> "gun") select [0,4] == "main" && {!("waterCannonMagazine_RF" in getArray (_x >> "Magazines"))}) then {_turrets = true};
                    if (getNumber (_x >> "showAsCargo") > 0) then {_transportSeats = _transportSeats + 1};
                    if (isClass (_x >> "Turrets")) then {_x call _fnc_turretsFFV};
                }
                forEach ("true" configClasses (_this >> "Turrets"));
            };
            
        private _supportTypes = getArray (_cfg >> "availableForSupportTypes");
        if ("CAS_Bombing" in _supportTypes || {"CAS_Heli" in _supportTypes}) then {_turrets = true};
        
        _cfg call _fnc_turretsFFV;          
        if (_turrets) then {
            if (_transportSeats >= _minCargoSeats) then {_dual pushBack _vehType} else {_attack pushBack _vehType};
        } else {
            if (_transportSeats >= _minCargoSeats) then {_transport pushBack _vehType};
        };      
        false
    } count _array;
    call compile format ["%1Attack = _attack;%1Transport = _transport;%1Dual = _dual",_varArray];
};

{
    [_x,MIN_CARGO_SEATS_FOR_TRANSPORT] call _fnAttackTransportSplit;
    if (call compile format ["%1Transport isEqualTo []",_x]) then {
        [_x,MIN_ABS_CARGO_SEATS_FOR_TRANSPORT] call _fnAttackTransportSplit;
    };
} forEach ["va_pCarClasses","va_pTankClasses","va_pApcClasses","va_pHeliClasses","va_pPlaneClasses","va_pShipClasses",
           "va_eCarClasses","va_eTankClasses","va_eApcClasses","va_eHeliClasses","va_ePlaneClasses","va_eShipClasses",
           "va_cCarClasses","va_cHeliClasses","va_cPlaneClasses","va_cShipClasses"];

// we really want car transports, so look for smaller ones if needed
for "_i" from (MIN_ABS_CARGO_SEATS_FOR_TRANSPORT-1) to 1 step -1 do {
    private _pEmpty = va_pCarClassesTransport isEqualTo [];
    private _eEmpty = va_eCarClassesTransport isEqualTo [];
    if (!_pEmpty && !_eEmpty) exitWith {};
    if (_pEmpty) then {["va_pCarClasses",_i] call _fnAttackTransportSplit};
    if (_eEmpty) then {["va_eCarClasses",_i] call _fnAttackTransportSplit};
};

// remove types player doesn't want
if (ITW_ParamAttackPlaneSpawnAdjustment  < 0) then {va_pPlaneClassesTransport = [];va_ePlaneClassesTransport = []};
if (ITW_ParamAttackHeliSpawnAdjustment   < 0) then {va_pHeliClassesTransport  = [];va_eHeliClassesTransport  = []};
if (ITW_ParamAttackTankSpawnAdjustment   < 0) then {va_pTankClassesTransport  = [];va_eTankClassesTransport  = []};
if (ITW_ParamAttackApcSpawnAdjustment    < 0) then {va_pApcClassesTransport   = [];va_eApcClassesTransport   = []};
if (ITW_ParamAttackCarSpawnAdjustment    < 0) then {va_pCarClassesTransport   = [];va_eCarClassesTransport   = []};
if (ITW_ParamAttackShipSpawnAdjustment   < 0) then {va_pShipClassesTransport  = [];va_eShipClassesTransport  = []};
if (ITW_ParamAttackPlaneSpawnAdjustment <= 0) then {va_pPlaneClassesAttack = [];va_ePlaneClassesAttack = [];va_pPlaneClassesDual = [];va_ePlaneClassesDual = []};
if (ITW_ParamAttackHeliSpawnAdjustment  <= 0) then {va_pHeliClassesAttack  = [];va_eHeliClassesAttack  = [];va_pHeliClassesDual  = [];va_eHeliClassesDual  = []};
if (ITW_ParamAttackTankSpawnAdjustment  <= 0) then {va_pTankClassesAttack  = [];va_eTankClassesAttack  = [];va_pTankClassesDual  = [];va_eTankClassesDual  = []};
if (ITW_ParamAttackApcSpawnAdjustment   <= 0) then {va_pApcClassesAttack   = [];va_eApcClassesAttack   = [];va_pApcClassesDual   = [];va_eApcClassesDual   = []};
if (ITW_ParamAttackCarSpawnAdjustment   <= 0) then {va_pCarClassesAttack   = [];va_eCarClassesAttack   = [];va_pCarClassesDual   = [];va_eCarClassesDual   = []};
if (ITW_ParamAttackShipSpawnAdjustment  <= 0) then {va_pShipClassesAttack  = [];va_eShipClassesAttack  = [];va_pShipClassesDual  = [];va_eShipClassesDual  = []};

if ("NoTrucks" in _options) then {
    {
        if (_x isKindOf "Truck_F") then {
            va_pCarTransportClasses = va_pCarTransportClasses - [_x];
        };
    } forEach va_pCarTransportClasses;
    {
        if (_x isKindOf "Truck_F") then {
            va_pCarClasses = va_pCarClasses - [_x];
        };
    } forEach va_pCarClasses;
    
    {
        if (_x isKindOf "Truck_F") then {
            va_eCarTransportClasses = va_eCarTransportClasses - [_x];
        };
    } forEach va_eCarTransportClasses;
    {
        if (_x isKindOf "Truck_F") then {
            va_eCarClasses = va_eCarClasses - [_x];
        };
    } forEach va_eCarClasses;
    
    {
        if (_x isKindOf "Truck_F") then {
            va_cCarClasses = va_cCarClasses - [_x];
        };
    } forEach va_cCarClasses;
};

if ("EnsureBoats" in _options) then {
    if (va_pShipClasses isEqualTo []) then {va_pShipClasses = [call CustomArsenal_GetBoat]};
    if (va_eShipClasses isEqualTo []) then {va_eShipClasses = [call CustomArsenal_GetBoat]};
};

va_pAllVehicles = va_pCarClasses + va_pQuadBikeClasses + va_pTankClasses + va_pApcClasses + va_pHeliClasses + va_pFuelClasses + va_pRepairClasses + va_pAmmoClasses + va_pAAClasses + va_pShipClasses + va_pPlaneClasses + va_pArtyClasses + va_pStaticClasses + va_pMortarClasses + va_pDriverlessVehicles;

VEHICLE_ARRAYS_COMPLETE = true;

// clean up arrays not used in this mission

va_airports = nil;  //airports array in form [ilsPosition,ilsDirection,ilsTaxiOff,ilsTaxiIn] (see Arma_3_Dynamic_Airport_Configuration)

va_pOfficerClasses = nil;
va_pArtyClasses = nil;
va_pGenericNames = nil;
va_pLanguage = nil;
va_pUAVClasses = nil;
va_pInfClassesForWeights = nil;
va_pInfClassWeights = nil;

va_eOfficerClasses = nil;
va_eArtyClasses = nil;
va_eFuelClasses = nil;
va_eRepairClasses = nil;
va_eAmmoClasses = nil;
va_eGenericNames = nil;
va_eLanguage = nil;
va_eUAVClasses = nil;
va_eInfClassesForWeights = nil;
va_eInfClassWeights = nil;

va_cOfficerClasses = nil;
//va_cCarClasses = nil;
va_cQuadBikeClasses = nil;
va_cGenericNames = nil;
va_cLanguage = nil;
va_cUAVClasses = nil;
diag_log "Vehicle Arrays Processing Complete";
