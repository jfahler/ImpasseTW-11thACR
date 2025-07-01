// I needed the garage not to place the vehicles on the ground
#define DEBUGLOG if(true)then

ITW_Garage = compile preprocessFileLineNumbers "fn_garage.sqf";
ITW_Arsenal = compile preprocessFileLineNumbers "fn_arsenal.sqf";

uiNamespace setVariable ["ITW_Garage",ITW_Garage]; 
uiNamespace setVariable ["ITW_Arsenal",ITW_Arsenal]; 
   
uiNamespace setVariable ["RscDisplayGarageSKL_script",{ 
    _mode = _this select 0;
    _params = _this select 1;
    _class = _this select 2;

    _data = missionnamespace getvariable ["bis_fnc_garage_data",nil];
    
    switch _mode do {
        case "onLoad": {
            if (isnil {missionnamespace getvariable "bis_fnc_arsenal_data"}) then {
                startloadingscreen [""];
                ['Init',_params] spawn (uiNamespace getvariable "ITW_garage");
            } else {
                ['Init',_params] call (uiNamespace getvariable "ITW_garage");
            };
        };
        case "onUnload": {
            ['Exit',_params] call (uiNamespace getvariable "ITW_garage");
        };
    };}];
    
ITW_GaragePreload = {
    private _data = missionnamespace getvariable ["bis_fnc_garage_data",[]];
    if (_data isEqualTo []) then {
        // preload garage data  
        private "_fullData";     
        ["Preload"] spawn ITW_garage;
        waitUntil { 
            _fullData = missionnamespace getvariable ["bis_fnc_garage_data",[]]; 
            !(_fullData isEqualTo [])
        };   
        if (ITW_ParamVirtualGarage == 1) then {
            private _allVehicles = va_pAllVehicles apply {if (typeName _x isEqualTo "ARRAY") then {_x#0} else {_x}};
            {
                private _tab = []; 
                private _tabData = _x;
                // list of   model, [cfg,cfg,cfg...],   model, [cfg,cfg,cfg...], ...
                for "_i" from 1 to count _tabData step 2 do {         
                    private _catagory = _tabData#(_i-1);
                    private _cfgsFull = _tabData#(_i);
                    private _cfgs = [];
                    {
                        if (configName _x in _allVehicles) then {
                            _cfgs pushBack _x;
                        };
                    } forEach _cfgsFull;
                    if !(_cfgs isEqualTo []) then {
                        _tab pushBack _catagory;
                        _tab pushBack _cfgs;            
                    };
                };           
                _data pushBack _tab; 
            } forEach _fullData; // [[tanks],[ships],[planes],...]
            missionnamespace setvariable ["bis_fnc_garage_data",_data];  
        };
    };
    _data
};

#define IDC_RSCDISPLAYARSENAL_CONTROLSBAR_BUTTONINTERFACE	44151
ITW_GarageAddCancelBtn = {
    // Change the 'random' button to a 'cancel' button
    params ["_display"];
    // called in ui namespace
    if (is3DEN) exitWith {};
    ITWGarageDisplay = _display;
    private _ctrlButton = _display displayCtrl IDC_RSCDISPLAYARSENAL_CONTROLSBAR_BUTTONINTERFACE;
    _ctrlButton ctrlSetText "CANCEL";
    _ctrlButton ctrlRemoveAllEventHandlers "buttonclick"; 
    _ctrlButton ctrlAddEventHandler ["buttonclick",
        {
            // called in mission namespace
            ITW_GARAGE_CANCEL = true;        
            with uinamespace do {
                ["buttonClose",[ITWGarageDisplay]] call BIS_fnc_Arsenal;
            };                    
        }];
    _ctrlButton ctrlEnable true; 
    _ctrlButton ctrlSetTooltip "Close the garage without creating a vehicle";
    missionNamespace setVariable ["ITW_GARAGE_CANCEL",false];
};


["ITW_GaragePreload"] call SKL_fnc_CompileFinal;
["ITW_GarageAddCancelBtn"] call SKL_fnc_CompileFinal;