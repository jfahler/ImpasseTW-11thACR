
diag_log "ITW: preInit start";

if (isNil "SKL_fnc_CompileFinal") then {SKL_fnc_CompileFinal = compileFinal preprocessFileLineNumbers "scripts\SKULL\SKL_CompileFinal.sqf"};
isNil {call compile preprocessFileLineNumbers "ITW_Airfield.sqf";              };
isNil {call compile preprocessFileLineNumbers "ITW_Ally.sqf";                  };
isNil {call compile preprocessFileLineNumbers "ITW_Attack.sqf";                };
isNil {call compile preprocessFileLineNumbers "ITW_Base.sqf";                  };
isNil {call compile preprocessFileLineNumbers "ITW_Enemy.sqf";                 };
isNil {call compile preprocessFileLineNumbers "ITW_Functions.sqf";             };
isNil {call compile preprocessFileLineNumbers "ITW_Garage.sqf";                };
isNil {call compile preprocessFileLineNumbers "ITW_Garrison.sqf";              };
isNil {call compile preprocessFileLineNumbers "ITW_Objectives.sqf";            };
isNil {call compile preprocessFileLineNumbers "ITW_Radio.sqf";                 };
isNil {call compile preprocessFileLineNumbers "ITW_Save.sqf";                  };
isNil {call compile preprocessFileLineNumbers "ITW_Teammates.sqf";             };
isNil {call compile preprocessFileLineNumbers "ITW_Vehicles.sqf";              };
isNil {call compile preprocessFileLineNumbers "ITW_VehRepair.sqf";             };
isNil {call compile preprocessFileLineNumbers "CustomArsenal\CustomArsenal.sqf";}; 
isNil {call compile preprocessFileLineNumbers "scripts\Factions\Factions.sqf";  }; 
isNil {call compile preprocessFileLineNumbers "scripts\Dlcs\DlcSelect.sqf";     };  
isNil {call compile preprocessFileLineNumbers "scripts\Skull\SKL_HeliExtract.sqf";}; 
isNil {call compile preprocessFileLineNumbers "scripts\Skull\SKL_TruckExtract.sqf";};
isNil {call compile preprocessFileLineNumbers "scripts\VehicleChooser\VehicleChooser.sqf";}; 

diag_log "ITW: preInit complete";
if (isServer) then {
    ITW_PreInitComplete = true;
    publicVariable "ITW_PreInitComplete";
};