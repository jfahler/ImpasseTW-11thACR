
if (isNil "ITW_Params_complete") then {
    // Convert all the params into ITW_<paramName> variables
    diag_log "ITW: Params:";
    
    private _list = [];
    { 
        private _name = configName _x;
        if (_name select [0,6] != "Spacer") then { 
            call compile format [
                "ITW_Param%1 = %2;
                 if (isServer) then {profileNamespace setVariable ['ITW_Param%1',ITW_Param%1];};
                 _list pushBack 'ITW_Param%1';"
                ,_name, [_name,nil] call BIS_fnc_getParamValue];
        };
    } forEach ("true" configClasses getMissionConfig "Params");
    
    // Convert to fractional value
    if (ITW_ParamDifficulty == 0) then {
        ITW_ParamDifficulty = call ITW_FncGetServerAiDifficultySetting;
    } else {
        ITW_ParamDifficulty = ITW_ParamDifficulty/10; 
    };
    if (ITW_ParamFriendlySquadSkill == 0) then {
        ITW_ParamFriendlySquadSkill = call ITW_FncGetServerAiDifficultySetting;
    } else {
        ITW_ParamFriendlySquadSkill = ITW_ParamFriendlySquadSkill/10;
    };
    ITW_ParamForceNVGs = ITW_ParamForceNVGs == 1;
    ITW_ParamVehicleSideAdjustment = ITW_ParamVehicleSideAdjustment/10;
    ITW_ParamVehicleSpawnAdjustment = ITW_ParamVehicleSpawnAdjustment/10;
    ITW_ParamAttackPlaneSpawnAdjustment = ITW_ParamAttackPlaneSpawnAdjustment/10;
    ITW_ParamAttackHeliSpawnAdjustment  = ITW_ParamAttackHeliSpawnAdjustment /10;
    ITW_ParamAttackTankSpawnAdjustment  = ITW_ParamAttackTankSpawnAdjustment /10;
    ITW_ParamAttackApcSpawnAdjustment   = ITW_ParamAttackApcSpawnAdjustment  /10;
    ITW_ParamAttackCarSpawnAdjustment   = ITW_ParamAttackCarSpawnAdjustment  /10;
    ITW_ParamAttackShipSpawnAdjustment  = ITW_ParamAttackShipSpawnAdjustment /10;
    
    {
        diag_log format ["  %1 = %2",_x,call compile _x];
    } forEach _list;
    
    ITW_Params_complete = true;
};