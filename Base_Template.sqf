// Export of '11acr_Base_Template.Altis' by SSG Fahler on v0.9

///////////////////////////////////////////////////////////////////////////////////////////
// Init
params [["_layerWhiteList",[],[[]]],["_layerBlacklist",[],[[]]],["_posCenter",[0,0,0],[[]]],["_dir",0,[0]],["_idBlacklist",[],[[]]]];
private _allWhitelisted = _layerWhiteList isEqualTo [];
private _layerRoot = (_allWhitelisted || {true in _layerWhiteList}) && {!(true in _layerBlackList)};
private _layer143 = (_allWhitelisted || {"bunker (large) #b1" in _layerWhiteList}) && {!("bunker (large) #b1" in _layerBlackList)};
private _layer105 = (_allWhitelisted || {"dugout 2" in _layerWhiteList}) && {!("dugout 2" in _layerBlackList)};
private _layer99 = (_allWhitelisted || {"dugout 1" in _layerWhiteList}) && {!("dugout 1" in _layerBlackList)};
private _layer47 = (_allWhitelisted || {"outpost 5" in _layerWhiteList}) && {!("outpost 5" in _layerBlackList)};
private _layer33 = (_allWhitelisted || {"vehicle camp (nato)" in _layerWhiteList}) && {!("vehicle camp (nato)" in _layerBlackList)};


///////////////////////////////////////////////////////////////////////////////////////////
// Markers
private _markers = [];
private _markerIDs = [];


///////////////////////////////////////////////////////////////////////////////////////////
// Groups
private _groups = [];
private _groupIDs = [];

private _item290 = grpNull;
if (_layerRoot) then {
	_item290 = createGroup west;
	_this = _item290;
	_groups pushback _this;
	_groupIDs pushback 290;
};

private _item304 = grpNull;
if (_layerRoot) then {
	_item304 = createGroup west;
	_this = _item304;
	_groups pushback _this;
	_groupIDs pushback 304;
};

private _item306 = grpNull;
if (_layerRoot) then {
	_item306 = createGroup west;
	_this = _item306;
	_groups pushback _this;
	_groupIDs pushback 306;
};


///////////////////////////////////////////////////////////////////////////////////////////
// Objects
private _objects = [];
private _objectIDs = [];

private _item0 = objNull;
if (_layer33) then {
	_item0 = createVehicle ["gm_barrel",[23353.5,18344,0],[],0,"CAN_COLLIDE"];
	_this = _item0;
	_objects pushback _this;
	_objectIDs pushback 0;
	_this setPosWorld [23353.5,18344,3.63856];
	_this setVectorDirAndUp [[-0.982551,-0.185992,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item1 = objNull;
if (_layer33) then {
	_item1 = createVehicle ["land_gm_sandbags_02_wall",[23353.2,18349,0],[],0,"CAN_COLLIDE"];
	_this = _item1;
	_objects pushback _this;
	_objectIDs pushback 1;
	_this setPosWorld [23353.2,18349,3.19];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item2 = objNull;
if (_layer33) then {
	_item2 = createVehicle ["land_gm_sandbags_02_wall",[23353.1,18352,0],[],0,"CAN_COLLIDE"];
	_this = _item2;
	_objects pushback _this;
	_objectIDs pushback 2;
	_this setPosWorld [23353.1,18352,3.19];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item3 = objNull;
if (_layer33) then {
	_item3 = createVehicle ["land_gm_sandbags_02_wall",[23353.2,18345.9,0],[],0,"CAN_COLLIDE"];
	_this = _item3;
	_objects pushback _this;
	_objectIDs pushback 3;
	_this setPosWorld [23353.2,18345.9,3.19];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item4 = objNull;
if (_layer33) then {
	_item4 = createVehicle ["gm_barrel",[23368.4,18343.9,0],[],0,"CAN_COLLIDE"];
	_this = _item4;
	_objects pushback _this;
	_objectIDs pushback 4;
	_this setPosWorld [23368.4,18343.9,3.63856];
	_this setVectorDirAndUp [[0.942872,0.333155,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item5 = objNull;
if (_layer33) then {
	_item5 = createVehicle ["gm_barrel",[23368.9,18344.4,0],[],0,"CAN_COLLIDE"];
	_this = _item5;
	_objects pushback _this;
	_objectIDs pushback 5;
	_this setPosWorld [23368.9,18344.4,3.63856];
	_this setVectorDirAndUp [[0.940088,0.340933,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item6 = objNull;
if (_layer33) then {
	_item6 = createVehicle ["gm_barrel",[23354.2,18343.8,0],[],0,"CAN_COLLIDE"];
	_this = _item6;
	_objects pushback _this;
	_objectIDs pushback 6;
	_this setPosWorld [23354.2,18343.8,3.63856];
	_this setVectorDirAndUp [[0.833682,0.552245,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item7 = objNull;
if (_layer33) then {
	_item7 = createVehicle ["gm_barrel",[23354,18344.5,0],[],0,"CAN_COLLIDE"];
	_this = _item7;
	_objects pushback _this;
	_objectIDs pushback 7;
	_this setPosWorld [23354,18344.5,3.63856];
	_this setVectorDirAndUp [[0.940117,0.340851,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item8 = objNull;
if (_layer33) then {
	_item8 = createVehicle ["gm_barrel",[23385.7,18354.4,0],[],0,"CAN_COLLIDE"];
	_this = _item8;
	_objects pushback _this;
	_objectIDs pushback 8;
	_this setPosWorld [23385.7,18354.4,3.63856];
	_this setVectorDirAndUp [[0.354917,-0.934898,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item9 = objNull;
if (_layer33) then {
	_item9 = createVehicle ["gm_barrel",[23367.8,18344.1,0],[],0,"CAN_COLLIDE"];
	_this = _item9;
	_objects pushback _this;
	_objectIDs pushback 9;
	_this setPosWorld [23367.8,18344.1,3.63856];
	_this setVectorDirAndUp [[0.0501919,-0.99874,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item10 = objNull;
if (_layer33) then {
	_item10 = createVehicle ["gm_barrel",[23385.7,18355,0],[],0,"CAN_COLLIDE"];
	_this = _item10;
	_objects pushback _this;
	_objectIDs pushback 10;
	_this setPosWorld [23385.7,18355,3.63856];
	_this setVectorDirAndUp [[0.885453,0.464729,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item12 = objNull;
if (_layer33) then {
	_item12 = createVehicle ["land_gm_camonet_04_nato",[23360.8,18348.6,0],[],0,"CAN_COLLIDE"];
	_this = _item12;
	_objects pushback _this;
	_objectIDs pushback 12;
	_this setPosWorld [23360.8,18348.6,3.19];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item13 = objNull;
if (_layer33) then {
	_item13 = createVehicle ["land_gm_sandbags_02_wall",[23368.2,18346,0],[],0,"CAN_COLLIDE"];
	_this = _item13;
	_objects pushback _this;
	_objectIDs pushback 13;
	_this setPosWorld [23368.2,18346,3.19];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item14 = objNull;
if (_layer33) then {
	_item14 = createVehicle ["land_gm_sandbags_02_wall",[23397.4,18361.9,0],[],0,"CAN_COLLIDE"];
	_this = _item14;
	_objects pushback _this;
	_objectIDs pushback 14;
	_this setPosWorld [23397.4,18361.9,3.19];
	_this setVectorDirAndUp [[0.999889,0.0149164,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item15 = objNull;
if (_layer33) then {
	_item15 = createVehicle ["land_gm_sandbags_02_wall",[23368.1,18352.1,0],[],0,"CAN_COLLIDE"];
	_this = _item15;
	_objects pushback _this;
	_objectIDs pushback 15;
	_this setPosWorld [23368.1,18352.1,3.19];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item16 = objNull;
if (_layer33) then {
	_item16 = createVehicle ["land_gm_sandbags_02_wall",[23394.4,18361.8,0],[],0,"CAN_COLLIDE"];
	_this = _item16;
	_objects pushback _this;
	_objectIDs pushback 16;
	_this setPosWorld [23394.4,18361.8,3.19];
	_this setVectorDirAndUp [[0.999889,0.0149164,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item17 = objNull;
if (_layer33) then {
	_item17 = createVehicle ["land_gm_sandbags_02_wall",[23368.1,18349,0],[],0,"CAN_COLLIDE"];
	_this = _item17;
	_objects pushback _this;
	_objectIDs pushback 17;
	_this setPosWorld [23368.1,18349,3.19];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item18 = objNull;
if (_layer33) then {
	_item18 = createVehicle ["land_gm_sandbags_02_wall",[23391.4,18361.7,0],[],0,"CAN_COLLIDE"];
	_this = _item18;
	_objects pushback _this;
	_objectIDs pushback 18;
	_this setPosWorld [23391.4,18361.7,3.19];
	_this setVectorDirAndUp [[0.999889,0.0149164,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item20 = objNull;
if (_layer33) then {
	_item20 = createVehicle ["gm_ge_army_shelteraceII_standard",[23401.2,18347.5,0],[],0,"CAN_COLLIDE"];
	_this = _item20;
	_objects pushback _this;
	_objectIDs pushback 20;
	_this setPosWorld [23401.2,18347.5,4.28371];
	_this setVectorDirAndUp [[4.93811e-07,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	[_this,"[[[[],[]],[[],[]],[[],[]],[[],[]]],false]"] call bis_fnc_initAmmoBox;;
	;
};

private _item21 = objNull;
if (_layer33) then {
	_item21 = createVehicle ["land_gm_euro_furniture_table_05",[23407.4,18347.2,0],[],0,"CAN_COLLIDE"];
	_this = _item21;
	_objects pushback _this;
	_objectIDs pushback 21;
	_this setPosWorld [23407.4,18347.2,3.60729];
	_this setVectorDirAndUp [[-0.0217624,-0.999763,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item22 = objNull;
if (_layer33) then {
	_item22 = createVehicle ["land_gm_euro_furniture_table_05",[23407.3,18349.4,0],[],0,"CAN_COLLIDE"];
	_this = _item22;
	_objects pushback _this;
	_objectIDs pushback 22;
	_this setPosWorld [23407.3,18349.4,3.60729];
	_this setVectorDirAndUp [[0.0127258,0.999919,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item23 = objNull;
if (_layer33) then {
	_item23 = createVehicle ["gm_barrel",[23408.7,18344.2,0],[],0,"CAN_COLLIDE"];
	_this = _item23;
	_objects pushback _this;
	_objectIDs pushback 23;
	_this setPosWorld [23408.7,18344.2,3.63856];
	_this setVectorDirAndUp [[0.940087,0.340934,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item24 = objNull;
if (_layer33) then {
	_item24 = createVehicle ["gm_barrel",[23408.1,18344.1,0],[],0,"CAN_COLLIDE"];
	_this = _item24;
	_objects pushback _this;
	_objectIDs pushback 24;
	_this setPosWorld [23408.1,18344.1,3.63856];
	_this setVectorDirAndUp [[-0.535252,0.844693,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item25 = objNull;
if (_layer33) then {
	_item25 = createVehicle ["gm_barrel",[23407.8,18344.8,0],[],0,"CAN_COLLIDE"];
	_this = _item25;
	_objects pushback _this;
	_objectIDs pushback 25;
	_this setPosWorld [23407.8,18344.8,3.63856];
	_this setVectorDirAndUp [[7.20058e-07,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item26 = objNull;
if (_layer33) then {
	_item26 = createVehicle ["land_gm_camonet_04_nato",[23391.3,18348.7,0],[],0,"CAN_COLLIDE"];
	_this = _item26;
	_objects pushback _this;
	_objectIDs pushback 26;
	_this setPosWorld [23391.3,18348.7,3.19];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item27 = objNull;
if (_layer33) then {
	_item27 = createVehicle ["land_gm_sandbags_02_wall",[23408.5,18346.2,0],[],0,"CAN_COLLIDE"];
	_this = _item27;
	_objects pushback _this;
	_objectIDs pushback 27;
	_this setPosWorld [23408.5,18346.2,3.19];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item28 = objNull;
if (_layer33) then {
	_item28 = createVehicle ["land_gm_sandbags_02_wall",[23382.3,18361.7,0],[],0,"CAN_COLLIDE"];
	_this = _item28;
	_objects pushback _this;
	_objectIDs pushback 28;
	_this setPosWorld [23382.3,18361.7,3.19];
	_this setVectorDirAndUp [[0.999928,-0.0119731,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item30 = objNull;
if (_layer33) then {
	_item30 = createVehicle ["land_gm_sandbags_02_wall",[23408.5,18349.2,0],[],0,"CAN_COLLIDE"];
	_this = _item30;
	_objects pushback _this;
	_objectIDs pushback 30;
	_this setPosWorld [23408.5,18349.2,3.19];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item31 = objNull;
if (_layer33) then {
	_item31 = createVehicle ["land_gm_sandbags_02_wall",[23408.4,18352.2,0],[],0,"CAN_COLLIDE"];
	_this = _item31;
	_objects pushback _this;
	_objectIDs pushback 31;
	_this setPosWorld [23408.4,18352.2,3.19];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item32 = objNull;
if (_layer33) then {
	_item32 = createVehicle ["land_gm_sandbags_02_wall",[23385.4,18361.7,0],[],0,"CAN_COLLIDE"];
	_this = _item32;
	_objects pushback _this;
	_objectIDs pushback 32;
	_this setPosWorld [23385.4,18361.7,3.19];
	_this setVectorDirAndUp [[0.999928,-0.0119731,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item159 = objNull;
if (_layer33) then {
	_item159 = createVehicle ["land_gm_camonet_02_nato",[23404.4,18348.2,0],[],0,"CAN_COLLIDE"];
	_this = _item159;
	_objects pushback _this;
	_objectIDs pushback 159;
	_this setPosWorld [23404.4,18348.2,3.19];
	_this setVectorDirAndUp [[-0.999061,-0.0433228,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item201 = objNull;
if (_layer33) then {
	_item201 = createVehicle ["land_gm_sandbags_02_wall",[23373.3,18361.6,0],[],0,"CAN_COLLIDE"];
	_this = _item201;
	_objects pushback _this;
	_objectIDs pushback 201;
	_this setPosWorld [23373.3,18361.6,3.19];
	_this setVectorDirAndUp [[0.999928,-0.0119731,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item202 = objNull;
if (_layer33) then {
	_item202 = createVehicle ["land_gm_sandbags_02_wall",[23379.3,18361.7,0],[],0,"CAN_COLLIDE"];
	_this = _item202;
	_objects pushback _this;
	_objectIDs pushback 202;
	_this setPosWorld [23379.3,18361.7,3.19];
	_this setVectorDirAndUp [[0.999928,-0.0119731,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item203 = objNull;
if (_layer33) then {
	_item203 = createVehicle ["land_gm_sandbags_02_wall",[23376.3,18361.7,0],[],0,"CAN_COLLIDE"];
	_this = _item203;
	_objects pushback _this;
	_objectIDs pushback 203;
	_this setPosWorld [23376.3,18361.7,3.19];
	_this setVectorDirAndUp [[0.999928,-0.0119731,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item34 = objNull;
if (_layer47) then {
	_item34 = createVehicle ["gm_camotarp_02",[23391.6,18325.1,0],[],0,"CAN_COLLIDE"];
	_this = _item34;
	_objects pushback _this;
	_objectIDs pushback 34;
	_this setPosWorld [23391.6,18325.1,3.19];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item35 = objNull;
if (_layer47) then {
	_item35 = createVehicle ["gm_crates_pile_03",[23392.3,18322.6,0],[],0,"CAN_COLLIDE"];
	_this = _item35;
	_objects pushback _this;
	_objectIDs pushback 35;
	_this setPosWorld [23392.3,18322.6,3.19];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item36 = objNull;
if (_layer47) then {
	_item36 = createVehicle ["gm_crates_pile_04",[23391,18327.9,0],[],0,"CAN_COLLIDE"];
	_this = _item36;
	_objects pushback _this;
	_objectIDs pushback 36;
	_this setPosWorld [23391,18327.9,3.19];
	_this setVectorDirAndUp [[-0.999951,-0.00986368,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item37 = objNull;
if (_layer47) then {
	_item37 = createVehicle ["gm_placeholder_2x2x2",[23395,18323.4,0],[],0,"CAN_COLLIDE"];
	_this = _item37;
	_objects pushback _this;
	_objectIDs pushback 37;
	_this setPosWorld [23395,18323.4,4.19];
	_this setVectorDirAndUp [[0.999952,0.00975792,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item38 = objNull;
if (_layer47) then {
	_item38 = createVehicle ["land_gm_sandbags_01_short_01",[23388.2,18324.9,0],[],0,"CAN_COLLIDE"];
	_this = _item38;
	_objects pushback _this;
	_objectIDs pushback 38;
	_this setPosWorld [23388.2,18324.9,3.19];
	_this setVectorDirAndUp [[1,-4.37114e-08,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item39 = objNull;
if (_layer47) then {
	_item39 = createVehicle ["land_gm_sandbags_02_wall",[23393.2,18320.7,0],[],0,"CAN_COLLIDE"];
	_this = _item39;
	_objects pushback _this;
	_objectIDs pushback 39;
	_this setPosWorld [23393.2,18320.7,3.19];
	_this setVectorDirAndUp [[1,-4.37114e-08,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item40 = objNull;
if (_layer47) then {
	_item40 = createVehicle ["land_gm_sandbags_02_wall",[23390.1,18320.7,0],[],0,"CAN_COLLIDE"];
	_this = _item40;
	_objects pushback _this;
	_objectIDs pushback 40;
	_this setPosWorld [23390.1,18320.7,3.19];
	_this setVectorDirAndUp [[1,-4.37114e-08,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item43 = objNull;
if (_layer47) then {
	_item43 = createVehicle ["land_gm_sandbags_01_short_01",[23388.3,18321,0],[],0,"CAN_COLLIDE"];
	_this = _item43;
	_objects pushback _this;
	_objectIDs pushback 43;
	_this setPosWorld [23388.3,18321,3.19];
	_this setVectorDirAndUp [[-0.999712,-0.0239959,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item44 = objNull;
if (_layer47) then {
	_item44 = createVehicle ["land_gm_sandbags_02_wall",[23401.9,18321.4,0],[],0,"CAN_COLLIDE"];
	_this = _item44;
	_objects pushback _this;
	_objectIDs pushback 44;
	_this setPosWorld [23401.9,18321.4,3.19];
	_this setVectorDirAndUp [[0.999779,-0.021014,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item46 = objNull;
if (_layer47) then {
	_item46 = createVehicle ["land_gm_sandbags_01_short_01",[23388.1,18329.2,0],[],0,"CAN_COLLIDE"];
	_this = _item46;
	_objects pushback _this;
	_objectIDs pushback 46;
	_this setPosWorld [23388.1,18329.2,3.19];
	_this setVectorDirAndUp [[1,-4.37114e-08,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item224 = objNull;
if (_layer47) then {
	_item224 = createVehicle ["land_gm_sandbags_01_short_01",[23394.4,18329.2,0],[],0,"CAN_COLLIDE"];
	_this = _item224;
	_objects pushback _this;
	_objectIDs pushback 224;
	_this setPosWorld [23394.4,18329.2,3.19];
	_this setVectorDirAndUp [[1,-4.37114e-08,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item225 = objNull;
if (_layer47) then {
	_item225 = createVehicle ["land_gm_sandbags_02_wall",[23404.8,18321.5,0],[],0,"CAN_COLLIDE"];
	_this = _item225;
	_objects pushback _this;
	_objectIDs pushback 225;
	_this setPosWorld [23404.8,18321.5,3.19];
	_this setVectorDirAndUp [[0.999779,-0.021014,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item226 = objNull;
if (_layer47) then {
	_item226 = createVehicle ["land_gm_sandbags_02_wall",[23408,18321.4,0],[],0,"CAN_COLLIDE"];
	_this = _item226;
	_objects pushback _this;
	_objectIDs pushback 226;
	_this setPosWorld [23408,18321.4,3.19];
	_this setVectorDirAndUp [[0.999779,-0.021014,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item227 = objNull;
if (_layer47) then {
	_item227 = createVehicle ["land_gm_sandbags_02_wall",[23409.2,18323.2,0],[],0,"CAN_COLLIDE"];
	_this = _item227;
	_objects pushback _this;
	_objectIDs pushback 227;
	_this setPosWorld [23409.2,18323.2,3.19];
	_this setVectorDirAndUp [[0.0182859,0.999833,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item90 = objNull;
if (_layer99) then {
	_item90 = createVehicle ["land_gm_camonet_03_east",[23347.2,18335.9,0.120228],[],0,"CAN_COLLIDE"];
	_this = _item90;
	_objects pushback _this;
	_objectIDs pushback 90;
	_this setPosWorld [23347.2,18335.9,3.31023];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item91 = objNull;
if (_layer99) then {
	_item91 = createVehicle ["gm_placeholder_2x2x2",[23346.7,18334,0],[],0,"CAN_COLLIDE"];
	_this = _item91;
	_objects pushback _this;
	_objectIDs pushback 91;
	_this setPosWorld [23346.7,18334,4.19];
	_this setVectorDirAndUp [[-0.999972,0.00752205,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item92 = objNull;
if (_layer99) then {
	_item92 = createVehicle ["land_gm_sandbags_01_wall_02",[23343.6,18333.6,0],[],0,"CAN_COLLIDE"];
	_this = _item92;
	_objects pushback _this;
	_objectIDs pushback 92;
	_this setPosWorld [23343.6,18333.6,3.19];
	_this setVectorDirAndUp [[1,-4.37114e-08,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item93 = objNull;
if (_layer99) then {
	_item93 = createVehicle ["gm_berm_01",[23349.6,18335.4,0],[],0,"CAN_COLLIDE"];
	_this = _item93;
	_objects pushback _this;
	_objectIDs pushback 93;
	_this setPosWorld [23349.6,18335.4,3.19];
	_this setVectorDirAndUp [[-0.99909,0.0426606,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item94 = objNull;
if (_layer99) then {
	_item94 = createVehicle ["land_gm_sandbags_01_wall_02",[23343.6,18338.4,0],[],0,"CAN_COLLIDE"];
	_this = _item94;
	_objects pushback _this;
	_objectIDs pushback 94;
	_this setPosWorld [23343.6,18338.4,3.19];
	_this setVectorDirAndUp [[1,-4.37114e-08,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item95 = objNull;
if (_layer99) then {
	_item95 = createVehicle ["land_gm_sandbags_01_wall_02",[23343.8,18329.2,0],[],0,"CAN_COLLIDE"];
	_this = _item95;
	_objects pushback _this;
	_objectIDs pushback 95;
	_this setPosWorld [23343.8,18329.2,3.19];
	_this setVectorDirAndUp [[-0.997154,-0.075396,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item97 = objNull;
if (_layer99) then {
	_item97 = createVehicle ["gm_mudpit_01",[23346.5,18338.4,0],[],0,"CAN_COLLIDE"];
	_this = _item97;
	_objects pushback _this;
	_objectIDs pushback 97;
	_this setPosWorld [23346.5,18338.4,3.19];
	_this setVectorDirAndUp [[0.00891856,-0.99996,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item98 = objNull;
if (_layer99) then {
	_item98 = createVehicle ["gm_mudpit_01",[23346.8,18334.1,0],[],0,"CAN_COLLIDE"];
	_this = _item98;
	_objects pushback _this;
	_objectIDs pushback 98;
	_this setPosWorld [23346.8,18334.1,3.19];
	_this setVectorDirAndUp [[0.999903,-0.0139307,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item100 = objNull;
if (_layer105) then {
	_item100 = createVehicle ["land_gm_woodbunker_01_bags",[23410.6,18343,0],[],0,"CAN_COLLIDE"];
	_this = _item100;
	_objects pushback _this;
	_objectIDs pushback 100;
	_this setPosWorld [23410.6,18343,3.19];
	_this setVectorDirAndUp [[0.999743,0.0226626,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item121 = objNull;
if (_layer143) then {
	_item121 = createVehicle ["Land_BagFence_Corner_F",[23397,18337.4,0],[],0,"CAN_COLLIDE"];
	_this = _item121;
	_objects pushback _this;
	_objectIDs pushback 121;
	_this setPosWorld [23397,18337.4,3.6111];
	_this setVectorDirAndUp [[-0.999992,-0.00401638,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item123 = objNull;
if (_layer143) then {
	_item123 = createVehicle ["Land_BagFence_Long_F",[23401.6,18337.8,0],[],0,"CAN_COLLIDE"];
	_this = _item123;
	_objects pushback _this;
	_objectIDs pushback 123;
	_this setPosWorld [23401.6,18337.8,3.60931];
	_this setVectorDirAndUp [[0.00401678,-0.999992,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item124 = objNull;
if (_layer143) then {
	_item124 = createVehicle ["Land_BagFence_Long_F",[23398.8,18337.8,0],[],0,"CAN_COLLIDE"];
	_this = _item124;
	_objects pushback _this;
	_objectIDs pushback 124;
	_this setPosWorld [23398.8,18337.8,3.60931];
	_this setVectorDirAndUp [[0.00401678,-0.999992,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item125 = objNull;
if (_layer143) then {
	_item125 = createVehicle ["Land_BagFence_Long_F",[23409.9,18338.3,0],[],0,"CAN_COLLIDE"];
	_this = _item125;
	_objects pushback _this;
	_objectIDs pushback 125;
	_this setPosWorld [23409.9,18338.3,3.60931];
	_this setVectorDirAndUp [[0.999597,-0.0284038,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item127 = objNull;
if (_layer143) then {
	_item127 = createVehicle ["Land_Pallet_F",[23407.5,18339.2,0],[],0,"CAN_COLLIDE"];
	_this = _item127;
	_objects pushback _this;
	_objectIDs pushback 127;
	_this setPosWorld [23407.5,18339.2,3.29104];
	_this setVectorDirAndUp [[0.695936,0.718104,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item128 = objNull;
if (_layer143) then {
	_item128 = createVehicle ["Land_CratesWooden_F",[23404.6,18336.2,0],[],0,"CAN_COLLIDE"];
	_this = _item128;
	_objects pushback _this;
	_objectIDs pushback 128;
	_this setPosWorld [23404.6,18336.2,3.929];
	_this setVectorDirAndUp [[-0.00401621,0.999992,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item129 = objNull;
if (_layer143) then {
	_item129 = createVehicle ["Land_BarrelEmpty_F",[23404.1,18339,0],[],0,"CAN_COLLIDE"];
	_this = _item129;
	_objects pushback _this;
	_objectIDs pushback 129;
	_this setPosWorld [23404.1,18339,3.59475];
	_this setVectorDirAndUp [[0.00448813,-0.99999,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item130 = objNull;
if (_layer143) then {
	_item130 = createVehicle ["AmmoCrates_NoInteractive_Large",[23405.3,18339.3,0],[],0,"CAN_COLLIDE"];
	_this = _item130;
	_objects pushback _this;
	_objectIDs pushback 130;
	_this setPosWorld [23405.3,18339.3,4.55025];
	_this setVectorDirAndUp [[-0.00401621,0.999992,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item132 = objNull;
if (_layer143) then {
	_item132 = createVehicle ["Land_BagFence_Corner_F",[23397.2,18333.6,0],[],0,"CAN_COLLIDE"];
	_this = _item132;
	_objects pushback _this;
	_objectIDs pushback 132;
	_this setPosWorld [23397.2,18333.6,3.6111];
	_this setVectorDirAndUp [[0.00401678,-0.999992,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item133 = objNull;
if (_layer143) then {
	_item133 = createVehicle ["Land_BagFence_Long_F",[23399,18333.4,0],[],0,"CAN_COLLIDE"];
	_this = _item133;
	_objects pushback _this;
	_objectIDs pushback 133;
	_this setPosWorld [23399,18333.4,3.60931];
	_this setVectorDirAndUp [[-0.00401621,0.999992,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item134 = objNull;
if (_layer143) then {
	_item134 = createVehicle ["Land_BagFence_Long_F",[23409.9,18335.7,0],[],0,"CAN_COLLIDE"];
	_this = _item134;
	_objects pushback _this;
	_objectIDs pushback 134;
	_this setPosWorld [23409.9,18335.7,3.60931];
	_this setVectorDirAndUp [[-0.999992,-0.00401638,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item135 = objNull;
if (_layer143) then {
	_item135 = createVehicle ["Land_BagFence_Long_F",[23396.8,18335.4,0],[],0,"CAN_COLLIDE"];
	_this = _item135;
	_objects pushback _this;
	_objectIDs pushback 135;
	_this setPosWorld [23396.8,18335.4,3.60931];
	_this setVectorDirAndUp [[0.999992,0.0040167,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item139 = objNull;
if (_layer143) then {
	_item139 = createVehicle ["Land_CamoNetVar_NATO_EP1",[23406.4,18328.8,0],[],0,"CAN_COLLIDE"];
	_this = _item139;
	_objects pushback _this;
	_objectIDs pushback 139;
	_this setPosWorld [23406.4,18328.8,4.31267];
	_this setVectorDirAndUp [[-0.00401621,0.999992,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item140 = objNull;
if (_layer143) then {
	_item140 = createVehicle ["Land_fortified_nest_big_EP1",[23404.8,18329.9,0],[],0,"CAN_COLLIDE"];
	_this = _item140;
	_objects pushback _this;
	_objectIDs pushback 140;
	_this setPosWorld [23404.8,18329.9,4.11012];
	_this setVectorDirAndUp [[-0.00401621,0.999992,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item141 = objNull;
if (_layer143) then {
	_item141 = createVehicle ["Land_Pneu",[23410.8,18332.7,0],[],0,"CAN_COLLIDE"];
	_this = _item141;
	_objects pushback _this;
	_objectIDs pushback 141;
	_this setPosWorld [23410.8,18332.7,3.32292];
	_this setVectorDirAndUp [[0.00401678,-0.999992,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item204 = objNull;
if (_layer143) then {
	_item204 = createVehicle ["Land_BagFence_Long_F",[23410.1,18340,0],[],0,"CAN_COLLIDE"];
	_this = _item204;
	_objects pushback _this;
	_objectIDs pushback 204;
	_this setPosWorld [23410.1,18340,3.60931];
	_this setVectorDirAndUp [[0.999597,-0.0284038,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item209 = objNull;
if (_layer143) then {
	_item209 = createVehicle ["Fort_RazorWire",[23417.3,18326.6,0],[],0,"CAN_COLLIDE"];
	_this = _item209;
	_objects pushback _this;
	_objectIDs pushback 209;
	_this setPosWorld [23417.3,18326.6,3.94507];
	_this setVectorDirAndUp [[0.999973,-0.00731907,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item210 = objNull;
if (_layer143) then {
	_item210 = createVehicle ["Fort_RazorWire",[23417.4,18334.6,0],[],0,"CAN_COLLIDE"];
	_this = _item210;
	_objects pushback _this;
	_objectIDs pushback 210;
	_this setPosWorld [23417.4,18334.6,3.94507];
	_this setVectorDirAndUp [[0.999979,-0.00654113,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item211 = objNull;
if (_layer143) then {
	_item211 = createVehicle ["Fort_RazorWire",[23417.4,18342.5,0],[],0,"CAN_COLLIDE"];
	_this = _item211;
	_objects pushback _this;
	_objectIDs pushback 211;
	_this setPosWorld [23417.4,18342.5,3.94507];
	_this setVectorDirAndUp [[0.999973,-0.00731907,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item212 = objNull;
if (_layer143) then {
	_item212 = createVehicle ["Fort_RazorWire",[23417.2,18350.4,0],[],0,"CAN_COLLIDE"];
	_this = _item212;
	_objects pushback _this;
	_objectIDs pushback 212;
	_this setPosWorld [23417.2,18350.4,3.94507];
	_this setVectorDirAndUp [[0.999562,0.0295942,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item213 = objNull;
if (_layer143) then {
	_item213 = createVehicle ["Fort_RazorWire",[23416.9,18358.4,0],[],0,"CAN_COLLIDE"];
	_this = _item213;
	_objects pushback _this;
	_objectIDs pushback 213;
	_this setPosWorld [23416.9,18358.4,3.94507];
	_this setVectorDirAndUp [[0.999562,0.0295942,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item214 = objNull;
if (_layer143) then {
	_item214 = createVehicle ["Fort_RazorWire",[23416.5,18366.1,0],[],0,"CAN_COLLIDE"];
	_this = _item214;
	_objects pushback _this;
	_objectIDs pushback 214;
	_this setPosWorld [23416.5,18366.1,3.94507];
	_this setVectorDirAndUp [[0.999562,0.0295942,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item215 = objNull;
if (_layer143) then {
	_item215 = createVehicle ["Fort_RazorWire",[23412.8,18370.4,0],[],0,"CAN_COLLIDE"];
	_this = _item215;
	_objects pushback _this;
	_objectIDs pushback 215;
	_this setPosWorld [23412.8,18370.4,3.94507];
	_this setVectorDirAndUp [[-0.0184962,0.999829,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item216 = objNull;
if (_layer143) then {
	_item216 = createVehicle ["Fort_RazorWire",[23405.2,18370.2,0],[],0,"CAN_COLLIDE"];
	_this = _item216;
	_objects pushback _this;
	_objectIDs pushback 216;
	_this setPosWorld [23405.2,18370.2,3.94507];
	_this setVectorDirAndUp [[-0.0184962,0.999829,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item217 = objNull;
if (_layer143) then {
	_item217 = createVehicle ["Fort_RazorWire",[23397.5,18369.9,0],[],0,"CAN_COLLIDE"];
	_this = _item217;
	_objects pushback _this;
	_objectIDs pushback 217;
	_this setPosWorld [23397.5,18369.9,3.94507];
	_this setVectorDirAndUp [[-0.0385597,0.999256,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item218 = objNull;
if (_layer143) then {
	_item218 = createVehicle ["Fort_RazorWire",[23389.9,18369.6,0],[],0,"CAN_COLLIDE"];
	_this = _item218;
	_objects pushback _this;
	_objectIDs pushback 218;
	_this setPosWorld [23389.9,18369.6,3.94507];
	_this setVectorDirAndUp [[-0.0385597,0.999256,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item219 = objNull;
if (_layer143) then {
	_item219 = createVehicle ["Fort_RazorWire",[23381.9,18369.3,0],[],0,"CAN_COLLIDE"];
	_this = _item219;
	_objects pushback _this;
	_objectIDs pushback 219;
	_this setPosWorld [23381.9,18369.3,3.94507];
	_this setVectorDirAndUp [[-0.0385597,0.999256,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item220 = objNull;
if (_layer143) then {
	_item220 = createVehicle ["Fort_RazorWire",[23374.4,18369,0],[],0,"CAN_COLLIDE"];
	_this = _item220;
	_objects pushback _this;
	_objectIDs pushback 220;
	_this setPosWorld [23374.4,18369,3.94507];
	_this setVectorDirAndUp [[-0.0385597,0.999256,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item228 = objNull;
if (_layer143) then {
	_item228 = createVehicle ["Fort_RazorWire",[23371.6,18368.9,0],[],0,"CAN_COLLIDE"];
	_this = _item228;
	_objects pushback _this;
	_objectIDs pushback 228;
	_this setPosWorld [23371.6,18368.9,3.94507];
	_this setVectorDirAndUp [[-0.0184962,0.999829,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item231 = objNull;
if (_layer143) then {
	_item231 = createVehicle ["Fort_RazorWire",[23348.7,18368.1,0],[],0,"CAN_COLLIDE"];
	_this = _item231;
	_objects pushback _this;
	_objectIDs pushback 231;
	_this setPosWorld [23348.7,18368.1,3.94507];
	_this setVectorDirAndUp [[-0.0385597,0.999256,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item232 = objNull;
if (_layer143) then {
	_item232 = createVehicle ["Fort_RazorWire",[23340.7,18367.8,0],[],0,"CAN_COLLIDE"];
	_this = _item232;
	_objects pushback _this;
	_objectIDs pushback 232;
	_this setPosWorld [23340.7,18367.8,3.94507];
	_this setVectorDirAndUp [[-0.0385597,0.999256,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item233 = objNull;
if (_layer143) then {
	_item233 = createVehicle ["Fort_RazorWire",[23333.1,18367.5,0],[],0,"CAN_COLLIDE"];
	_this = _item233;
	_objects pushback _this;
	_objectIDs pushback 233;
	_this setPosWorld [23333.1,18367.5,3.94507];
	_this setVectorDirAndUp [[-0.0385597,0.999256,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item234 = objNull;
if (_layer143) then {
	_item234 = createVehicle ["Fort_RazorWire",[23329.4,18364,0],[],0,"CAN_COLLIDE"];
	_this = _item234;
	_objects pushback _this;
	_objectIDs pushback 234;
	_this setPosWorld [23329.4,18364,3.94507];
	_this setVectorDirAndUp [[-0.999952,0.00982747,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item235 = objNull;
if (_layer143) then {
	_item235 = createVehicle ["Fort_RazorWire",[23329.3,18356,0],[],0,"CAN_COLLIDE"];
	_this = _item235;
	_objects pushback _this;
	_objectIDs pushback 235;
	_this setPosWorld [23329.3,18356,3.94507];
	_this setVectorDirAndUp [[-0.999959,0.0090493,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item236 = objNull;
if (_layer143) then {
	_item236 = createVehicle ["Fort_RazorWire",[23329.3,18348.1,0],[],0,"CAN_COLLIDE"];
	_this = _item236;
	_objects pushback _this;
	_objectIDs pushback 236;
	_this setPosWorld [23329.3,18348.1,3.94507];
	_this setVectorDirAndUp [[-0.999952,0.00982747,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item237 = objNull;
if (_layer143) then {
	_item237 = createVehicle ["Fort_RazorWire",[23329.4,18340.2,0],[],0,"CAN_COLLIDE"];
	_this = _item237;
	_objects pushback _this;
	_objectIDs pushback 237;
	_this setPosWorld [23329.4,18340.2,3.94507];
	_this setVectorDirAndUp [[-0.999633,-0.0270867,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item238 = objNull;
if (_layer143) then {
	_item238 = createVehicle ["Fort_RazorWire",[23329.7,18332.3,0],[],0,"CAN_COLLIDE"];
	_this = _item238;
	_objects pushback _this;
	_objectIDs pushback 238;
	_this setPosWorld [23329.7,18332.3,3.94507];
	_this setVectorDirAndUp [[-0.999633,-0.0270867,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item239 = objNull;
if (_layer143) then {
	_item239 = createVehicle ["Fort_RazorWire",[23330,18324.5,0],[],0,"CAN_COLLIDE"];
	_this = _item239;
	_objects pushback _this;
	_objectIDs pushback 239;
	_this setPosWorld [23330,18324.5,3.94507];
	_this setVectorDirAndUp [[-0.999633,-0.0270867,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item240 = objNull;
if (_layer143) then {
	_item240 = createVehicle ["Fort_RazorWire",[23333.9,18301.5,0],[],0,"CAN_COLLIDE"];
	_this = _item240;
	_objects pushback _this;
	_objectIDs pushback 240;
	_this setPosWorld [23333.9,18301.5,3.94507];
	_this setVectorDirAndUp [[0.00426282,-0.999991,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item241 = objNull;
if (_layer143) then {
	_item241 = createVehicle ["Fort_RazorWire",[23341.4,18301.5,0],[],0,"CAN_COLLIDE"];
	_this = _item241;
	_objects pushback _this;
	_objectIDs pushback 241;
	_this setPosWorld [23341.4,18301.5,3.94507];
	_this setVectorDirAndUp [[0.00426282,-0.999991,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item242 = objNull;
if (_layer143) then {
	_item242 = createVehicle ["Fort_RazorWire",[23349.2,18301.7,0],[],0,"CAN_COLLIDE"];
	_this = _item242;
	_objects pushback _this;
	_objectIDs pushback 242;
	_this setPosWorld [23349.2,18301.7,3.94507];
	_this setVectorDirAndUp [[0.0243324,-0.999704,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item243 = objNull;
if (_layer143) then {
	_item243 = createVehicle ["Fort_RazorWire",[23356.7,18301.9,0],[],0,"CAN_COLLIDE"];
	_this = _item243;
	_objects pushback _this;
	_objectIDs pushback 243;
	_this setPosWorld [23356.7,18301.9,3.94507];
	_this setVectorDirAndUp [[0.0243324,-0.999704,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item244 = objNull;
if (_layer143) then {
	_item244 = createVehicle ["Fort_RazorWire",[23364.8,18302.1,0],[],0,"CAN_COLLIDE"];
	_this = _item244;
	_objects pushback _this;
	_objectIDs pushback 244;
	_this setPosWorld [23364.8,18302.1,3.94507];
	_this setVectorDirAndUp [[0.0243324,-0.999704,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item245 = objNull;
if (_layer143) then {
	_item245 = createVehicle ["Fort_RazorWire",[23372.3,18302.3,0],[],0,"CAN_COLLIDE"];
	_this = _item245;
	_objects pushback _this;
	_objectIDs pushback 245;
	_this setPosWorld [23372.3,18302.3,3.94507];
	_this setVectorDirAndUp [[0.0243324,-0.999704,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item246 = objNull;
if (_layer143) then {
	_item246 = createVehicle ["Fort_RazorWire",[23375.1,18302.4,0],[],0,"CAN_COLLIDE"];
	_this = _item246;
	_objects pushback _this;
	_objectIDs pushback 246;
	_this setPosWorld [23375.1,18302.4,3.94507];
	_this setVectorDirAndUp [[0.00426282,-0.999991,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item247 = objNull;
if (_layer143) then {
	_item247 = createVehicle ["Fort_RazorWire",[23382.7,18302.4,0],[],0,"CAN_COLLIDE"];
	_this = _item247;
	_objects pushback _this;
	_objectIDs pushback 247;
	_this setPosWorld [23382.7,18302.4,3.94507];
	_this setVectorDirAndUp [[0.00426282,-0.999991,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item248 = objNull;
if (_layer143) then {
	_item248 = createVehicle ["Fort_RazorWire",[23390.4,18302.6,0],[],0,"CAN_COLLIDE"];
	_this = _item248;
	_objects pushback _this;
	_objectIDs pushback 248;
	_this setPosWorld [23390.4,18302.6,3.94507];
	_this setVectorDirAndUp [[0.0243324,-0.999704,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item249 = objNull;
if (_layer143) then {
	_item249 = createVehicle ["Fort_RazorWire",[23398,18302.8,0],[],0,"CAN_COLLIDE"];
	_this = _item249;
	_objects pushback _this;
	_objectIDs pushback 249;
	_this setPosWorld [23398,18302.8,3.94507];
	_this setVectorDirAndUp [[0.0243324,-0.999704,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item250 = objNull;
if (_layer143) then {
	_item250 = createVehicle ["Fort_RazorWire",[23406,18303,0],[],0,"CAN_COLLIDE"];
	_this = _item250;
	_objects pushback _this;
	_objectIDs pushback 250;
	_this setPosWorld [23406,18303,3.94507];
	_this setVectorDirAndUp [[0.0243324,-0.999704,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item251 = objNull;
if (_layer143) then {
	_item251 = createVehicle ["Fort_RazorWire",[23413.6,18303.2,0],[],0,"CAN_COLLIDE"];
	_this = _item251;
	_objects pushback _this;
	_objectIDs pushback 251;
	_this setPosWorld [23413.6,18303.2,3.94507];
	_this setVectorDirAndUp [[0.0243324,-0.999704,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item252 = objNull;
if (_layer143) then {
	_item252 = createVehicle ["Fort_RazorWire",[23417.3,18318.8,0],[],0,"CAN_COLLIDE"];
	_this = _item252;
	_objects pushback _this;
	_objectIDs pushback 252;
	_this setPosWorld [23417.3,18318.8,3.94507];
	_this setVectorDirAndUp [[0.999973,-0.00731907,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item253 = objNull;
if (_layer143) then {
	_item253 = createVehicle ["Fort_RazorWire",[23417.1,18311.6,0],[],0,"CAN_COLLIDE"];
	_this = _item253;
	_objects pushback _this;
	_objectIDs pushback 253;
	_this setPosWorld [23417.1,18311.6,3.94507];
	_this setVectorDirAndUp [[0.999973,-0.00731907,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item254 = objNull;
if (_layer143) then {
	_item254 = createVehicle ["Fort_RazorWire",[23417.1,18307.4,0],[],0,"CAN_COLLIDE"];
	_this = _item254;
	_objects pushback _this;
	_objectIDs pushback 254;
	_this setPosWorld [23417.1,18307.4,3.94507];
	_this setVectorDirAndUp [[0.999973,-0.00731907,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item255 = objNull;
if (_layer143) then {
	_item255 = createVehicle ["Fort_RazorWire",[23330.2,18316.7,0],[],0,"CAN_COLLIDE"];
	_this = _item255;
	_objects pushback _this;
	_objectIDs pushback 255;
	_this setPosWorld [23330.2,18316.7,3.94507];
	_this setVectorDirAndUp [[0.999973,-0.00731907,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item256 = objNull;
if (_layer143) then {
	_item256 = createVehicle ["Fort_RazorWire",[23330.2,18308.9,0],[],0,"CAN_COLLIDE"];
	_this = _item256;
	_objects pushback _this;
	_objectIDs pushback 256;
	_this setPosWorld [23330.2,18308.9,3.94507];
	_this setVectorDirAndUp [[0.999973,-0.00731907,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item257 = objNull;
if (_layer143) then {
	_item257 = createVehicle ["Fort_RazorWire",[23330.1,18305,0],[],0,"CAN_COLLIDE"];
	_this = _item257;
	_objects pushback _this;
	_objectIDs pushback 257;
	_this setPosWorld [23330.1,18305,3.94507];
	_this setVectorDirAndUp [[0.999973,-0.00731907,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item365 = objNull;
if (_layer143) then {
	_item365 = createVehicle ["Land_BagFence_Long_F",[23410,18339.7,0.765373],[],0,"CAN_COLLIDE"];
	_this = _item365;
	_objects pushback _this;
	_objectIDs pushback 365;
	_this setPosWorld [23410,18339.7,4.37468];
	_this setVectorDirAndUp [[0.999597,-0.0284038,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item367 = objNull;
if (_layer143) then {
	_item367 = createVehicle ["cwr3_closet_green",[23395,18346.6,0],[],0,"CAN_COLLIDE"];
	_this = _item367;
	_objects pushback _this;
	_objectIDs pushback 367;
	_this setPosWorld [23395,18346.6,3.78561];
	_this setVectorDirAndUp [[0.999586,-0.0287765,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item145 = objNull;
if (_layerRoot) then {
	_item145 = createVehicle ["vn_b_ammobox_supply_10",[23398.2,18335.4,0],[],0,"CAN_COLLIDE"];
	_this = _item145;
	_objects pushback _this;
	_objectIDs pushback 145;
	_this setPosWorld [23398.2,18335.4,3.70865];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	[_this,"[[[[""vn_m_m51_etool_01"",""vn_m_shovel_01"",""vn_m_axe_01""],[2,2,2]],[[""vn_prop_fort_mag""],[50]],[[],[]],[[],[]]],false]"] call bis_fnc_initAmmoBox;;
	;
	[_this, 1] call ace_cargo_fnc_setSize;
};

private _item147 = objNull;
if (_layerRoot) then {
	_item147 = createVehicle ["Land_vn_bagfence_01_long_green_f",[23353.1,18351.9,1.84621],[],0,"CAN_COLLIDE"];
	_this = _item147;
	_objects pushback _this;
	_objectIDs pushback 147;
	_this setPosWorld [23353.1,18351.9,5.45352];
	_this setVectorDirAndUp [[0.999238,0.0390401,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item148 = objNull;
if (_layerRoot) then {
	_item148 = createVehicle ["Land_vn_bagfence_01_long_green_f",[23353.3,18349,1.84621],[],0,"CAN_COLLIDE"];
	_this = _item148;
	_objects pushback _this;
	_objectIDs pushback 148;
	_this setPosWorld [23353.3,18349,5.45352];
	_this setVectorDirAndUp [[0.999238,0.0390401,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item149 = objNull;
if (_layerRoot) then {
	_item149 = createVehicle ["Land_vn_bagfence_01_long_green_f",[23353.3,18346.1,1.84621],[],0,"CAN_COLLIDE"];
	_this = _item149;
	_objects pushback _this;
	_objectIDs pushback 149;
	_this setPosWorld [23353.3,18346.1,5.45352];
	_this setVectorDirAndUp [[0.999866,-0.0163912,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item150 = objNull;
if (_layerRoot) then {
	_item150 = createVehicle ["land_gm_sandbags_02_wall",[23343.4,18353.7,0],[],0,"CAN_COLLIDE"];
	_this = _item150;
	_objects pushback _this;
	_objectIDs pushback 150;
	_this setPosWorld [23343.4,18353.7,3.19];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item151 = objNull;
if (_layerRoot) then {
	_item151 = createVehicle ["land_gm_sandbags_02_wall",[23343.4,18350.7,0],[],0,"CAN_COLLIDE"];
	_this = _item151;
	_objects pushback _this;
	_objectIDs pushback 151;
	_this setPosWorld [23343.4,18350.7,3.19];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item152 = objNull;
if (_layerRoot) then {
	_item152 = createVehicle ["Land_vn_b_tower_01",[23345.6,18344.6,0],[],0,"CAN_COLLIDE"];
	_this = _item152;
	_objects pushback _this;
	_objectIDs pushback 152;
	_this setPosWorld [23345.6,18344.6,5.68428];
	_this setVectorDirAndUp [[-0.998807,0.0488416,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item153 = objNull;
if (_layerRoot) then {
	_item153 = createVehicle ["Land_vn_b_trench_bunker_04_01",[23346.4,18356.3,-2.38419e-07],[],0,"CAN_COLLIDE"];
	_this = _item153;
	_objects pushback _this;
	_objectIDs pushback 153;
	_this setPosWorld [23346.4,18356.3,4.59644];
	_this setVectorDirAndUp [[-0.999388,0.0349913,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item154 = objNull;
if (_layerRoot) then {
	_item154 = createVehicle ["land_gm_sandbags_02_wall",[23343.5,18347.9,0],[],0,"CAN_COLLIDE"];
	_this = _item154;
	_objects pushback _this;
	_objectIDs pushback 154;
	_this setPosWorld [23343.5,18347.9,3.19];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item155 = objNull;
if (_layerRoot) then {
	_item155 = createVehicle ["land_gm_sandbags_02_wall",[23343.5,18345,0],[],0,"CAN_COLLIDE"];
	_this = _item155;
	_objects pushback _this;
	_objectIDs pushback 155;
	_this setPosWorld [23343.5,18345,3.19];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item156 = objNull;
if (_layerRoot) then {
	_item156 = createVehicle ["land_gm_sandbags_02_wall",[23343.6,18342.1,0],[],0,"CAN_COLLIDE"];
	_this = _item156;
	_objects pushback _this;
	_objectIDs pushback 156;
	_this setPosWorld [23343.6,18342.1,3.19];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item158 = objNull;
if (_layerRoot) then {
	_item158 = createVehicle ["Land_vn_bunker_big_02",[23403.5,18357.2,-2.38419e-07],[],0,"CAN_COLLIDE"];
	_this = _item158;
	_objects pushback _this;
	_objectIDs pushback 158;
	_this setPosWorld [23403.5,18357.2,5.07048];
	_this setVectorDirAndUp [[0.0298612,-0.999554,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item160 = objNull;
if (_layerRoot) then {
	_item160 = createVehicle ["Land_vn_bunker_big_01",[23357.9,18325.1,0],[],0,"CAN_COLLIDE"];
	_this = _item160;
	_objects pushback _this;
	_objectIDs pushback 160;
	_this setPosWorld [23357.9,18325.1,4.11012];
	_this setVectorDirAndUp [[0.0337189,0.999431,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item162 = objNull;
if (_layerRoot) then {
	_item162 = createVehicle ["Land_fortified_nest_small",[23396.8,18322.7,0],[],0,"CAN_COLLIDE"];
	_this = _item162;
	_objects pushback _this;
	_objectIDs pushback 162;
	_this setPosWorld [23396.8,18322.7,4.15563];
	_this setVectorDirAndUp [[0.0289993,0.999579,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item166 = objNull;
if (_layerRoot) then {
	_item166 = createVehicle ["Land_vn_bagfence_01_long_green_f",[23387.2,18320.5,0],[],0,"CAN_COLLIDE"];
	_this = _item166;
	_objects pushback _this;
	_objectIDs pushback 166;
	_this setPosWorld [23387.2,18320.5,3.60731];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item167 = objNull;
if (_layerRoot) then {
	_item167 = createVehicle ["Land_vn_bagfence_01_long_green_f",[23384.4,18320.5,0],[],0,"CAN_COLLIDE"];
	_this = _item167;
	_objects pushback _this;
	_objectIDs pushback 167;
	_this setPosWorld [23384.4,18320.5,3.60731];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item168 = objNull;
if (_layerRoot) then {
	_item168 = createVehicle ["Land_vn_bagfence_01_long_green_f",[23381.6,18320.5,0],[],0,"CAN_COLLIDE"];
	_this = _item168;
	_objects pushback _this;
	_objectIDs pushback 168;
	_this setPosWorld [23381.6,18320.5,3.60731];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item169 = objNull;
if (_layerRoot) then {
	_item169 = createVehicle ["Land_vn_bagfence_01_long_green_f",[23378.9,18320.4,0],[],0,"CAN_COLLIDE"];
	_this = _item169;
	_objects pushback _this;
	_objectIDs pushback 169;
	_this setPosWorld [23378.9,18320.4,3.60731];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item170 = objNull;
if (_layerRoot) then {
	_item170 = createVehicle ["Land_vn_bagfence_01_long_green_f",[23376.3,18320.5,0],[],0,"CAN_COLLIDE"];
	_this = _item170;
	_objects pushback _this;
	_objectIDs pushback 170;
	_this setPosWorld [23376.3,18320.5,3.60731];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item171 = objNull;
if (_layerRoot) then {
	_item171 = createVehicle ["Land_vn_bagfence_01_long_green_f",[23373.5,18320.4,0],[],0,"CAN_COLLIDE"];
	_this = _item171;
	_objects pushback _this;
	_objectIDs pushback 171;
	_this setPosWorld [23373.5,18320.4,3.60731];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item172 = objNull;
if (_layerRoot) then {
	_item172 = createVehicle ["Land_vn_bagfence_01_long_green_f",[23370.8,18320.3,0],[],0,"CAN_COLLIDE"];
	_this = _item172;
	_objects pushback _this;
	_objectIDs pushback 172;
	_this setPosWorld [23370.8,18320.3,3.60731];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item173 = objNull;
if (_layerRoot) then {
	_item173 = createVehicle ["Land_vn_bagfence_01_long_green_f",[23368.3,18320.3,0],[],0,"CAN_COLLIDE"];
	_this = _item173;
	_objects pushback _this;
	_objectIDs pushback 173;
	_this setPosWorld [23368.3,18320.3,3.60731];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item174 = objNull;
if (_layerRoot) then {
	_item174 = createVehicle ["Land_vn_bagfence_01_long_green_f",[23365.5,18320.3,0],[],0,"CAN_COLLIDE"];
	_this = _item174;
	_objects pushback _this;
	_objectIDs pushback 174;
	_this setPosWorld [23365.5,18320.3,3.60731];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item175 = objNull;
if (_layerRoot) then {
	_item175 = createVehicle ["Land_vn_bagfence_01_long_green_f",[23362.8,18320.2,0],[],0,"CAN_COLLIDE"];
	_this = _item175;
	_objects pushback _this;
	_objectIDs pushback 175;
	_this setPosWorld [23362.8,18320.2,3.60731];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item176 = objNull;
if (_layerRoot) then {
	_item176 = createVehicle ["Land_vn_bagfence_01_long_green_f",[23351.8,18320.4,0],[],0,"CAN_COLLIDE"];
	_this = _item176;
	_objects pushback _this;
	_objectIDs pushback 176;
	_this setPosWorld [23351.8,18320.4,3.60731];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item177 = objNull;
if (_layerRoot) then {
	_item177 = createVehicle ["Land_vn_bagfence_01_long_green_f",[23349,18320.3,0],[],0,"CAN_COLLIDE"];
	_this = _item177;
	_objects pushback _this;
	_objectIDs pushback 177;
	_this setPosWorld [23349,18320.3,3.60731];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item178 = objNull;
if (_layerRoot) then {
	_item178 = createVehicle ["Land_vn_bagfence_01_long_green_f",[23346.3,18320.3,0],[],0,"CAN_COLLIDE"];
	_this = _item178;
	_objects pushback _this;
	_objectIDs pushback 178;
	_this setPosWorld [23346.3,18320.3,3.60731];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item179 = objNull;
if (_layerRoot) then {
	_item179 = createVehicle ["Land_vn_bagfence_01_long_green_f",[23344.9,18321.7,0],[],0,"CAN_COLLIDE"];
	_this = _item179;
	_objects pushback _this;
	_objectIDs pushback 179;
	_this setPosWorld [23344.9,18321.7,3.60731];
	_this setVectorDirAndUp [[-0.995869,-0.0908033,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item180 = objNull;
if (_layerRoot) then {
	_item180 = createVehicle ["Land_vn_bagfence_01_long_green_f",[23344.6,18324.3,0],[],0,"CAN_COLLIDE"];
	_this = _item180;
	_objects pushback _this;
	_objectIDs pushback 180;
	_this setPosWorld [23344.6,18324.3,3.60731];
	_this setVectorDirAndUp [[-0.995869,-0.0908033,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item181 = objNull;
if (_layerRoot) then {
	_item181 = createVehicle ["Land_vn_bagfence_01_long_green_f",[23344.4,18326.7,0],[],0,"CAN_COLLIDE"];
	_this = _item181;
	_objects pushback _this;
	_objectIDs pushback 181;
	_this setPosWorld [23344.4,18326.7,3.60731];
	_this setVectorDirAndUp [[-0.991781,-0.127946,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item182 = objNull;
if (_layerRoot) then {
	_item182 = createVehicle ["land_gm_sandbags_01_single_01",[23344.5,18328.2,0],[],0,"CAN_COLLIDE"];
	_this = _item182;
	_objects pushback _this;
	_objectIDs pushback 182;
	_this setPosWorld [23344.5,18328.3,3.19263];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item183 = objNull;
if (_layerRoot) then {
	_item183 = createVehicle ["land_gm_sandbags_01_single_01",[23344.9,18328.3,0],[],0,"CAN_COLLIDE"];
	_this = _item183;
	_objects pushback _this;
	_objectIDs pushback 183;
	_this setPosWorld [23344.9,18328.3,3.19263];
	_this setVectorDirAndUp [[-0.764911,0.644136,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item184 = objNull;
if (_layerRoot) then {
	_item184 = createVehicle ["land_gm_sandbags_01_single_03",[23344.4,18328.8,0],[],0,"CAN_COLLIDE"];
	_this = _item184;
	_objects pushback _this;
	_objectIDs pushback 184;
	_this setPosWorld [23344.4,18328.8,3.19263];
	_this setVectorDirAndUp [[0.994985,-0.100025,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item185 = objNull;
if (_layerRoot) then {
	_item185 = createVehicle ["ACE_SandbagObject",[23344.8,18327.8,0],[],0,"CAN_COLLIDE"];
	_this = _item185;
	_objects pushback _this;
	_objectIDs pushback 185;
	_this setPosWorld [23344.8,18327.8,3.25838];
	_this setVectorDirAndUp [[0.13691,0.990583,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item186 = objNull;
if (_layerRoot) then {
	_item186 = createVehicle ["land_gm_sandbags_01_wall_01",[23351.7,18320.3,0.672888],[],0,"CAN_COLLIDE"];
	_this = _item186;
	_objects pushback _this;
	_objectIDs pushback 186;
	_this setPosWorld [23351.7,18320.3,3.86289];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item187 = objNull;
if (_layerRoot) then {
	_item187 = createVehicle ["land_gm_sandbags_01_wall_01",[23347,18320.1,0.672888],[],0,"CAN_COLLIDE"];
	_this = _item187;
	_objects pushback _this;
	_objectIDs pushback 187;
	_this setPosWorld [23347,18320.1,3.86289];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item188 = objNull;
if (_layerRoot) then {
	_item188 = createVehicle ["Info_Board_EP1",[23353.1,18328,0],[],0,"CAN_COLLIDE"];
	_this = _item188;
	_objects pushback _this;
	_objectIDs pushback 188;
	_this setPosWorld [23353.1,18328,3.98143];
	_this setVectorDirAndUp [[0.998072,-0.0620691,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item258 = objNull;
if (_layerRoot) then {
	_item258 = createVehicle ["Land_fort_rampart",[23397.6,18366.3,0],[],0,"CAN_COLLIDE"];
	_this = _item258;
	_objects pushback _this;
	_objectIDs pushback 258;
	_this setPosWorld [23397.6,18366.3,3.32995];
	_this setVectorDirAndUp [[-0.0188214,0.999823,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item259 = objNull;
if (_layerRoot) then {
	_item259 = createVehicle ["land_gm_sandbags_02_wall",[23353.2,18355.1,0],[],0,"CAN_COLLIDE"];
	_this = _item259;
	_objects pushback _this;
	_objectIDs pushback 259;
	_this setPosWorld [23353.2,18355.1,3.19];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item260 = objNull;
if (_layerRoot) then {
	_item260 = createVehicle ["land_gm_sandbags_02_wall",[23353,18357.9,0],[],0,"CAN_COLLIDE"];
	_this = _item260;
	_objects pushback _this;
	_objectIDs pushback 260;
	_this setPosWorld [23353,18357.9,3.19];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item261 = objNull;
if (_layerRoot) then {
	_item261 = createVehicle ["land_gm_sandbags_02_wall",[23353,18360.7,0],[],0,"CAN_COLLIDE"];
	_this = _item261;
	_objects pushback _this;
	_objectIDs pushback 261;
	_this setPosWorld [23353,18360.7,3.19];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item262 = objNull;
if (_layerRoot) then {
	_item262 = createVehicle ["land_gm_sandbags_02_wall",[23352.8,18362.8,0],[],0,"CAN_COLLIDE"];
	_this = _item262;
	_objects pushback _this;
	_objectIDs pushback 262;
	_this setPosWorld [23352.8,18362.8,3.19];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item263 = objNull;
if (_layerRoot) then {
	_item263 = createVehicle ["land_gm_sandbags_02_wall",[23352.7,18365.6,0],[],0,"CAN_COLLIDE"];
	_this = _item263;
	_objects pushback _this;
	_objectIDs pushback 263;
	_this setPosWorld [23352.7,18365.6,3.19];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item264 = objNull;
if (_layerRoot) then {
	_item264 = createVehicle ["land_gm_sandbags_02_wall",[23352.6,18368.5,0],[],0,"CAN_COLLIDE"];
	_this = _item264;
	_objects pushback _this;
	_objectIDs pushback 264;
	_this setPosWorld [23352.6,18368.5,3.19];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item265 = objNull;
if (_layerRoot) then {
	_item265 = createVehicle ["land_gm_sandbags_02_wall",[23371.1,18361.6,0],[],0,"CAN_COLLIDE"];
	_this = _item265;
	_objects pushback _this;
	_objectIDs pushback 265;
	_this setPosWorld [23371.1,18361.6,3.19];
	_this setVectorDirAndUp [[0.998568,0.0535027,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item266 = objNull;
if (_layerRoot) then {
	_item266 = createVehicle ["land_gm_sandbags_02_wall",[23368.9,18361.5,0],[],0,"CAN_COLLIDE"];
	_this = _item266;
	_objects pushback _this;
	_objectIDs pushback 266;
	_this setPosWorld [23368.9,18361.5,3.19];
	_this setVectorDirAndUp [[0.999674,0.0255236,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item267 = objNull;
if (_layerRoot) then {
	_item267 = createVehicle ["land_gm_sandbags_02_wall",[23367.5,18362.9,0],[],0,"CAN_COLLIDE"];
	_this = _item267;
	_objects pushback _this;
	_objectIDs pushback 267;
	_this setPosWorld [23367.5,18362.9,3.19];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item268 = objNull;
if (_layerRoot) then {
	_item268 = createVehicle ["land_gm_sandbags_02_wall",[23367.4,18365.6,0],[],0,"CAN_COLLIDE"];
	_this = _item268;
	_objects pushback _this;
	_objectIDs pushback 268;
	_this setPosWorld [23367.4,18365.6,3.19];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item269 = objNull;
if (_layerRoot) then {
	_item269 = createVehicle ["land_gm_sandbags_02_wall",[23367.3,18368.6,0],[],0,"CAN_COLLIDE"];
	_this = _item269;
	_objects pushback _this;
	_objectIDs pushback 269;
	_this setPosWorld [23367.3,18368.6,3.19];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item270 = objNull;
if (_layerRoot) then {
	_item270 = createVehicle ["Land_vn_b_tower_01",[23407.5,18323,0],[],0,"CAN_COLLIDE"];
	_this = _item270;
	_objects pushback _this;
	_objectIDs pushback 270;
	_this setPosWorld [23407.5,18323,5.68428];
	_this setVectorDirAndUp [[0.999986,-0.00538458,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item272 = objNull;
if (_layerRoot) then {
	_item272 = createVehicle ["Land_BagFence_01_long_green_F",[23387.3,18320.6,0.64865],[],0,"CAN_COLLIDE"];
	_this = _item272;
	_objects pushback _this;
	_objectIDs pushback 272;
	_this setPosWorld [23387.3,18320.6,4.25596];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item273 = objNull;
if (_layerRoot) then {
	_item273 = createVehicle ["Land_BagFence_01_long_green_F",[23384.4,18320.5,0.64865],[],0,"CAN_COLLIDE"];
	_this = _item273;
	_objects pushback _this;
	_objectIDs pushback 273;
	_this setPosWorld [23384.4,18320.5,4.25596];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item274 = objNull;
if (_layerRoot) then {
	_item274 = createVehicle ["Land_BagFence_01_long_green_F",[23381.7,18320.5,0.64865],[],0,"CAN_COLLIDE"];
	_this = _item274;
	_objects pushback _this;
	_objectIDs pushback 274;
	_this setPosWorld [23381.7,18320.5,4.25596];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item275 = objNull;
if (_layerRoot) then {
	_item275 = createVehicle ["Land_BagFence_01_long_green_F",[23378.9,18320.4,0.64865],[],0,"CAN_COLLIDE"];
	_this = _item275;
	_objects pushback _this;
	_objectIDs pushback 275;
	_this setPosWorld [23378.9,18320.4,4.25596];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item276 = objNull;
if (_layerRoot) then {
	_item276 = createVehicle ["Land_BagFence_01_long_green_F",[23376.2,18320.5,0.64865],[],0,"CAN_COLLIDE"];
	_this = _item276;
	_objects pushback _this;
	_objectIDs pushback 276;
	_this setPosWorld [23376.2,18320.5,4.25596];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item277 = objNull;
if (_layerRoot) then {
	_item277 = createVehicle ["Land_BagFence_01_long_green_F",[23373.5,18320.5,0.64865],[],0,"CAN_COLLIDE"];
	_this = _item277;
	_objects pushback _this;
	_objectIDs pushback 277;
	_this setPosWorld [23373.5,18320.5,4.25596];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item278 = objNull;
if (_layerRoot) then {
	_item278 = createVehicle ["Land_BagFence_01_long_green_F",[23370.7,18320.3,0.64865],[],0,"CAN_COLLIDE"];
	_this = _item278;
	_objects pushback _this;
	_objectIDs pushback 278;
	_this setPosWorld [23370.7,18320.3,4.25596];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item279 = objNull;
if (_layerRoot) then {
	_item279 = createVehicle ["Land_BagFence_01_long_green_F",[23368.1,18320.4,0.64865],[],0,"CAN_COLLIDE"];
	_this = _item279;
	_objects pushback _this;
	_objectIDs pushback 279;
	_this setPosWorld [23368.1,18320.4,4.25596];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item280 = objNull;
if (_layerRoot) then {
	_item280 = createVehicle ["Land_BagFence_01_long_green_F",[23365.7,18320.3,0.64865],[],0,"CAN_COLLIDE"];
	_this = _item280;
	_objects pushback _this;
	_objectIDs pushback 280;
	_this setPosWorld [23365.7,18320.3,4.25596];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item281 = objNull;
if (_layerRoot) then {
	_item281 = createVehicle ["Land_BagFence_01_long_green_F",[23363.6,18320.2,0.64865],[],0,"CAN_COLLIDE"];
	_this = _item281;
	_objects pushback _this;
	_objectIDs pushback 281;
	_this setPosWorld [23363.6,18320.2,4.25596];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item283 = objNull;
if (_layerRoot) then {
	_item283 = createVehicle ["Land_ConcreteBlock",[23379.8,18348,0],[],0,"CAN_COLLIDE"];
	_this = _item283;
	_objects pushback _this;
	_objectIDs pushback 283;
	_this setPosWorld [23379.8,18348,3.77474];
	_this setVectorDirAndUp [[1,0.000907616,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item284 = objNull;
if (_layerRoot) then {
	_item284 = createVehicle ["Land_BlockConcrete_F",[23374.9,18348,0],[],0,"CAN_COLLIDE"];
	_this = _item284;
	_objects pushback _this;
	_objectIDs pushback 284;
	_this setPosWorld [23374.9,18348,3.77474];
	_this setVectorDirAndUp [[1,0.000907616,0],[0,0,1]];
	base_center = _this;
	_this setVehicleVarName "base_center";
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item286 = objNull;
if (_layerRoot) then {
	_item286 = createVehicle ["dcx_dmo_cwn_usareur_m923a",[23383.8,18326.2,0],[],0,"CAN_COLLIDE"];
	_this = _item286;
	_objects pushback _this;
	_objectIDs pushback 286;
	_this setPosWorld [23383.8,18326.2,5.29299];
	_this setVectorDirAndUp [[-0.0327036,0.999465,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	if (!is3DEN && {10 != getWaterLeakiness _this}) then {[_this, 10] remoteExec ['setWaterLeakiness', _this]};
	[_this, -1] remoteExec ['limitSpeed', _this];
	[_this, 1] remoteExec ['setFuelConsumptionCoef', _this];
	[_this,"[[[[],[]],[[],[]],[[],[]],[[],[]]],false]"] call bis_fnc_initAmmoBox;;
	if (local _this) then {parseSimpleArray "[[""hithull"",""hittailgate"",""hitbody"",""hitengine"",""hitfuel"",""hitglass1"",""hitglass2"",""hitglass3"",""hitglass4"",""hitglass5"",""hitglass6"",""hitlfwheel"",""hitlmwheel"",""hitlbwheel"",""hitrfwheel"",""hitrmwheel"",""hitrbwheel"",""hitrglass"",""hitlglass"",""hitglass7"",""hitglass8"",""hitlf2wheel"",""hitrf2wheel"",""#light_l"",""#light_r""],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]]" params ['_hitpoints', '_damage']; {if ((_damage # _forEachIndex) == 0) then {continue}; _this setHitPointDamage [_x, _damage # _forEachIndex, false]} forEach _hitpoints};
	;
	if (-1 >= 0) then { _this setVariable ["ace_overpressure_distance", -1, true] };
	if (1 != (if (isNumber (configOf _this >> 'ace_rearm_defaultSupply')) then {getNumber (configOf _this >> 'ace_rearm_defaultSupply')} else {(if (getAmmoCargo _this > 0) then {getAmmoCargo _this} else {-1})})) then {[_this, 1] call ace_rearm_fnc_makeSource};
	_this setVariable ['s',1];;
	[_this, 8] call ace_cargo_fnc_setSpace;
	[_this, 0, 4, 5] spawn CSLA_fnc_texturaVehiculi;;
	[_this, 0, 6, 7] spawn CSLA_fnc_texturaVehiculi;;
};

private _item287 = objNull;
if (_layerRoot) then {
	_item287 = createVehicle ["dcx_dmo_cwn_usareur_m923a1f",[23377.9,18326,0],[],0,"CAN_COLLIDE"];
	_this = _item287;
	_objects pushback _this;
	_objectIDs pushback 287;
	_this setPosWorld [23377.9,18326,5.28676];
	_this setVectorDirAndUp [[-0.0263539,0.999653,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	if (!is3DEN && {10 != getWaterLeakiness _this}) then {[_this, 10] remoteExec ['setWaterLeakiness', _this]};
	[_this, -1] remoteExec ['limitSpeed', _this];
	[_this, 1] remoteExec ['setFuelConsumptionCoef', _this];
	[_this,"[[[[],[]],[[],[]],[[],[]],[[],[]]],false]"] call bis_fnc_initAmmoBox;;
	if (local _this) then {parseSimpleArray "[[""hithull"",""hittailgate"",""hitbody"",""hitengine"",""hitfuel"",""hitglass1"",""hitglass2"",""hitglass3"",""hitglass4"",""hitglass5"",""hitglass6"",""hitlfwheel"",""hitlmwheel"",""hitlbwheel"",""hitrfwheel"",""hitrmwheel"",""hitrbwheel"",""hitrglass"",""hitlglass"",""hitglass7"",""hitglass8"",""hitlf2wheel"",""hitrf2wheel"",""#light_l"",""#light_r""],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]]" params ['_hitpoints', '_damage']; {if ((_damage # _forEachIndex) == 0) then {continue}; _this setHitPointDamage [_x, _damage # _forEachIndex, false]} forEach _hitpoints};
	;
	if (-1 >= 0) then { _this setVariable ["ace_overpressure_distance", -1, true] };
	if (3000 != (_this call ace_refuel_fnc_getFuelCargo)) then {[_this, 3000] call ace_refuel_fnc_makeSource};
	_this setVariable ['s',1];;
	[_this, 8] call ace_cargo_fnc_setSpace;
	[_this, 0, 8, 9] spawn CSLA_fnc_texturaVehiculi;;
	[_this, 0, 10, 11] spawn CSLA_fnc_texturaVehiculi;;
};

private _item288 = objNull;
if (_layerRoot) then {
	_item288 = createVehicle ["dcx_dmo_cwn_cfe_static_m2_high",[23407.8,18322.8,4.33849],[],0,"CAN_COLLIDE"];
	_this = _item288;
	_objects pushback _this;
	_objectIDs pushback 288;
	_this setPosWorld [23407.8,18322.8,9.18199];
	_this setVectorDirAndUp [[0.999969,0.00787138,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	if (!is3DEN && {100 != getWaterLeakiness _this}) then {[_this, 100] remoteExec ['setWaterLeakiness', _this]};
	[_this, -1] remoteExec ['limitSpeed', _this];
	[_this, 1] remoteExec ['setFuelConsumptionCoef', _this];
	if (local _this) then {parseSimpleArray "[[""hitengine"",""hithull"",""hitturret"",""hitgun"",""hitltrack"",""hitrtrack"",""hitbody"",""#mg1_light_1""],[0,0,0,0,0,0,0,0]]" params ['_hitpoints', '_damage']; {if ((_damage # _forEachIndex) == 0) then {continue}; _this setHitPointDamage [_x, _damage # _forEachIndex, false]} forEach _hitpoints};
	;
	if (-1 >= 0) then { _this setVariable ["ace_overpressure_distance", -1, true] };
	[_this, 2] call ace_cargo_fnc_setSize;
};

private _item289 = objNull;
if (_layerRoot) then {
	_item289 = createVehicle ["dcx_dmo_cwn_usareur_m923a1om2",[23372.9,18326.1,0],[],0,"CAN_COLLIDE"];
	_this = _item289;
	_objects pushback _this;
	_objectIDs pushback 289;
	_this setPosWorld [23372.9,18326.1,6.08796];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	if (!is3DEN && {10 != getWaterLeakiness _this}) then {[_this, 10] remoteExec ['setWaterLeakiness', _this]};
	[_this, -1] remoteExec ['limitSpeed', _this];
	[_this, 1] remoteExec ['setFuelConsumptionCoef', _this];
	[_this,"[[[[],[]],[[],[]],[[],[]],[[],[]]],false]"] call bis_fnc_initAmmoBox;;
	if (local _this) then {parseSimpleArray "[[""hithull"",""hittailgate"",""hitbody"",""hitengine"",""hitfuel"",""hitglass1"",""hitglass2"",""hitglass3"",""hitglass4"",""hitglass5"",""hitglass6"",""hitlfwheel"",""hitlmwheel"",""hitlbwheel"",""hitrfwheel"",""hitrmwheel"",""hitrbwheel"",""hitrglass"",""hitlglass"",""hitglass7"",""hitglass8"",""hitlf2wheel"",""hitrf2wheel"",""hitturret"",""hitgun"",""#light_l"",""#light_r""],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]]" params ['_hitpoints', '_damage']; {if ((_damage # _forEachIndex) == 0) then {continue}; _this setHitPointDamage [_x, _damage # _forEachIndex, false]} forEach _hitpoints};
	;
	if (-1 >= 0) then { _this setVariable ["ace_overpressure_distance", -1, true] };
	_this setVariable ['s',1];;
	[_this, 8] call ace_cargo_fnc_setSpace;
	[_this, 0, 8, 9] spawn CSLA_fnc_texturaVehiculi;;
	[_this, 0, 10, 11] spawn CSLA_fnc_texturaVehiculi;;
};

private _item291 = objNull;
if (_layerRoot) then {
	_item291 = _item290 createUnit ["dmo_cwn_usareur_soldier_mrk",[23366.6,18326.8,0],[],0,"CAN_COLLIDE"];
	_item290 selectLeader _item291;
	_this = _item291;
	_objects pushback _this;
	_objectIDs pushback 291;
	_this setPosWorld [23366.6,18326.9,3.19144];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	selectPlayer _this;
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	if (!is3DEN && !isMultiplayer) then {_this setVariable ['ENH_SPR_Tickets', 0]};
	_this setname "Callum Ward";;
	_this setface "LivonianHead_4";;
	_this setspeaker "male10eng";;
	_this setpitch 1.033;;
	if (local _this) then {parseSimpleArray "[[""hitface"",""hitneck"",""hithead"",""hitpelvis"",""hitabdomen"",""hitdiaphragm"",""hitchest"",""hitbody"",""hitarms"",""hithands"",""hitlegs"",""incapacitated"",""hitleftarm"",""hitrightarm"",""hitleftleg"",""hitrightleg""],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]]" params ['_hitpoints', '_damage']; {if ((_damage # _forEachIndex) == 0) then {continue}; _this setHitPointDamage [_x, _damage # _forEachIndex, false]} forEach _hitpoints};
	if (0.5 != 0.5) then {[_this, ['aimingShake', 0.5]] remoteExec ['setSkill', _this]};
	if (0.5 != 0.5) then {[_this, ['aimingSpeed', 0.5]] remoteExec ['setSkill', _this]};
	if (0.5 != 0.5) then {[_this, ['aimingAccuracy', 0.5]] remoteExec ['setSkill', _this]};
	if (0.5 != 0.5) then {[_this, ['commanding', 0.5]] remoteExec ['setSkill', _this]};
	if (0.5 != 0.5) then {[_this, ['courage', 0.5]] remoteExec ['setSkill', _this]};
	if (0.5 != 0.5) then {[_this, ['general', 0.5]] remoteExec ['setSkill', _this]};
	if (0.5 != 0.5) then {[_this, ['reloadSpeed', 0.5]] remoteExec ['setSkill', _this]};
	if (0.5 != 0.5) then {[_this, ['spotDistance', 0.5]] remoteExec ['setSkill', _this]};
	if (0.5 != 0.5) then {[_this, ['spotTime', 0.5]] remoteExec ['setSkill', _this]};
	if (0.5 != 0.5) then {[_this, 0.5] remoteExec ['allowFleeing', _this]};
	if !(isClass (configFile >> 'CfgPatches' >> 'ace_common')) then {[_this, ['Medic', false]] remoteExec ['setUnitTrait', _this]};
	if !(isClass (configFile >> 'CfgPatches' >> 'ace_common')) then {[_this, ['Engineer', false]] remoteExec ['setUnitTrait', _this]};
	if !(isClass (configFile >> 'CfgPatches' >> 'ace_common')) then {[_this, ['ExplosiveSpecialist', false]] remoteExec ['setUnitTrait', _this]};
	[_this, ['UAVHacker', false]] remoteExec ['setUnitTrait', _this];
	if !(isClass (configFile >> 'CfgPatches' >> 'ace_common')) then {[_this, ['CamouflageCoef', 1]] remoteExec ['setUnitTrait', _this]};
	if !(isClass (configFile >> 'CfgPatches' >> 'ace_common')) then {[_this, ['AudibleCoef', 1]] remoteExec ['setUnitTrait', _this]};
	if !(isClass (configFile >> 'CfgPatches' >> 'ace_common')) then {[_this, ['LoadCoef', 1]] remoteExec ['setUnitTrait', _this]};
	;
	if !(0 == ([0, 1] select (_this getUnitTrait 'engineer')) || {0 == -1}) then {_this setVariable ['s', 0, true]};
	_this setVariable ["ace_advanced_fatigue_performanceFactor", 1, true];
	_this setVariable ['ACE_isEOD', false, true];
	if (0 >= 0.1) then {_this setVariable ["ace_medical_damageThreshold", 0, true]};
	if (0 != -1 && {0 != (parseNumber (_this getUnitTrait 'medic'))}) then {_this setVariable ["ace_medical_medicClass", 0, true]};
};

private _item293 = objNull;
if (_layerRoot) then {
	_item293 = createVehicle ["Land_vn_object_ladder_01",[23379.2,18352.8,0],[],0,"CAN_COLLIDE"];
	_this = _item293;
	_objects pushback _this;
	_objectIDs pushback 293;
	_this setPosWorld [23379.2,18352.8,3.19];
	_this setVectorDirAndUp [[-0.999999,-0.00100754,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item296 = objNull;
if (_layerRoot) then {
	_item296 = createVehicle ["FoldChair",[23390.7,18349.1,0],[],0,"CAN_COLLIDE"];
	_this = _item296;
	_objects pushback _this;
	_objectIDs pushback 296;
	_this setPosWorld [23390.7,18349.1,3.68918];
	_this setVectorDirAndUp [[-0.187437,0.982277,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item297 = objNull;
if (_layerRoot) then {
	_item297 = createVehicle ["FoldChair",[23391.7,18349.8,0],[],0,"CAN_COLLIDE"];
	_this = _item297;
	_objects pushback _this;
	_objectIDs pushback 297;
	_this setPosWorld [23391.7,18349.8,3.68918];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item298 = objNull;
if (_layerRoot) then {
	_item298 = createVehicle ["FoldChair",[23392.7,18349.9,0],[],0,"CAN_COLLIDE"];
	_this = _item298;
	_objects pushback _this;
	_objectIDs pushback 298;
	_this setPosWorld [23392.7,18349.9,3.68918];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item305 = objNull;
if (_layerRoot) then {
	_item305 = _item304 createUnit ["cwr3_b_soldier",[23391.7,18349.7,0],[],0,"CAN_COLLIDE"];
	_item304 selectLeader _item305;
	_this = _item305;
	_objects pushback _this;
	_objectIDs pushback 305;
	_this setPosWorld [23391.7,18349.7,3.19144];
	_this setVectorDirAndUp [[0.308502,-0.951224,0],[0,0,1]];
	_this setUnitLoadout [[],[],[],["cwr3_b_uniform_m81_woodland_rolled",[["FirstAidKit",1]]],["V_Simc_vest_pasgt",[["CUP_HandGrenade_M67",4,1]]],[],"H_Simc_pasgt_m81_SGT","",[],["ItemMap","","ItemRadio","ItemCompass","ItemWatch",""]];
	tweedleDee = _this;
	_this setVehicleVarName "tweedleDee";
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	if (!is3DEN && !isMultiplayer) then {_this setVariable ['ENH_SPR_Tickets', 0]};
	_this setname "Callen Rogers";;
	_this setspeaker "Male10ENG";;
	_this setpitch 0.96;;
	if (local _this) then {parseSimpleArray "[[""hitface"",""hitneck"",""hithead"",""hitpelvis"",""hitabdomen"",""hitdiaphragm"",""hitchest"",""hitbody"",""hitarms"",""hithands"",""hitlegs"",""incapacitated"",""hitleftarm"",""hitrightarm"",""hitleftleg"",""hitrightleg""],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]]" params ['_hitpoints', '_damage']; {if ((_damage # _forEachIndex) == 0) then {continue}; _this setHitPointDamage [_x, _damage # _forEachIndex, false]} forEach _hitpoints};
	            if (["SIT1",["hubsittingchaira_idle1","hubsittingchaira_idle2","hubsittingchaira_idle3","hubsittingchaira_move1"],false,false] # 0 != '') then            {                ["SIT1",["hubsittingchaira_idle1","hubsittingchaira_idle2","hubsittingchaira_idle3","hubsittingchaira_move1"],false,false] params ['_animSet', '_anims', '_canExit', '_attach'];                                _this setVariable ['ENH_ambientAnimations_anims', _anims];                _this disableAI 'ANIM';                if (_attach && !is3DEN) then                {                    private _logic = group _this createUnit ['Logic', getPosATL _this, [], 0, 'NONE'];                    _this setVariable ['ENH_ambientAnimations_logic', _logic];                    [_this, _logic] call BIS_fnc_attachToRelative;                };                                ENH_fnc_ambientAnimations_play =                {                    params ['_unit'];                    private _anim = selectRandom (_unit getVariable ['ENH_ambientAnimations_anims', []]);                    [_unit, _anim] remoteExec ['switchMove', 0];                };                                ENH_fnc_ambientAnimations_exit =                {                    params ['_unit'];                    if !(_unit getVariable ['ENH_ambientAnimations_exit', true]) exitWith {false};                    _unit setVariable ['ENH_ambientAnimations_exit', true];                    detach _unit;                    deleteVehicle (_unit getVariable ['ENH_ambientAnimations_logic', objNull]);                    if (alive _unit) then                    {                        [_unit, ''] remoteExec ['switchMove', 0];                        _unit enableAI 'ANIM';                    };                    _unit removeEventHandler ['Killed', _unit getVariable ['ENH_EHKilled',-1]];                    _unit removeEventHandler ['Dammaged', _unit getVariable ['ENH_EHDammaged',-1]];                    _unit removeEventHandler ['AnimDone', _unit getVariable ['ENH_EHAnimDone',-1]];                };                                private _EHAnimDone = _this addEventHandler ['AnimDone',                    {                        params ['_unit'];                        if (alive _unit) then                        {                            _unit call ENH_fnc_ambientAnimations_play;                        }                        else                        {                            _unit call ENH_fnc_ambientAnimations_exit;                        };                    }                ];                _this setVariable ['ENH_EHAnimDone', _EHAnimDone];                                if (_canExit && !is3DEN) then                {                    private _EHKilled = _this addEventHandler ['Killed',                    {                        (_this select 0) call ENH_fnc_ambientAnimations_exit;                    }];                    _this setVariable ['ENH_EHKilled', _EHKilled];                    private _EHDammaged = _this addEventHandler ['Dammaged',                    {                        (_this select 0) call ENH_fnc_ambientAnimations_exit;                    }];                    _this setVariable ['ENH_EHDammaged', _EHDammaged];                    _this spawn                    {                        scriptName 'ENH_Attribute_AmbientAnimations';                        params ['_unit'];                        waitUntil                        {                            sleep 1; (_unit getVariable ['ENH_ambientAnimations_exit', false]) || {behaviour _unit == 'COMBAT'}                        };                        _unit call ENH_fnc_ambientAnimations_exit;                    };                };                _this call ENH_fnc_ambientAnimations_play;            };;
	if (0.5 != 0.5) then {[_this, ['aimingShake', 0.5]] remoteExec ['setSkill', _this]};
	if (0.5 != 0.5) then {[_this, ['aimingSpeed', 0.5]] remoteExec ['setSkill', _this]};
	if (0.5 != 0.5) then {[_this, ['aimingAccuracy', 0.5]] remoteExec ['setSkill', _this]};
	if (0.5 != 0.5) then {[_this, ['commanding', 0.5]] remoteExec ['setSkill', _this]};
	if (0.5 != 0.5) then {[_this, ['courage', 0.5]] remoteExec ['setSkill', _this]};
	if (0.5 != 0.5) then {[_this, ['general', 0.5]] remoteExec ['setSkill', _this]};
	if (0.5 != 0.5) then {[_this, ['reloadSpeed', 0.5]] remoteExec ['setSkill', _this]};
	if (0.5 != 0.5) then {[_this, ['spotDistance', 0.5]] remoteExec ['setSkill', _this]};
	if (0.5 != 0.5) then {[_this, ['spotTime', 0.5]] remoteExec ['setSkill', _this]};
	if (0.5 != 0.5) then {[_this, 0.5] remoteExec ['allowFleeing', _this]};
	if !(isClass (configFile >> 'CfgPatches' >> 'ace_common')) then {[_this, ['Medic', false]] remoteExec ['setUnitTrait', _this]};
	if !(isClass (configFile >> 'CfgPatches' >> 'ace_common')) then {[_this, ['Engineer', false]] remoteExec ['setUnitTrait', _this]};
	if !(isClass (configFile >> 'CfgPatches' >> 'ace_common')) then {[_this, ['ExplosiveSpecialist', false]] remoteExec ['setUnitTrait', _this]};
	[_this, ['UAVHacker', false]] remoteExec ['setUnitTrait', _this];
	if !(isClass (configFile >> 'CfgPatches' >> 'ace_common')) then {[_this, ['CamouflageCoef', 1]] remoteExec ['setUnitTrait', _this]};
	if !(isClass (configFile >> 'CfgPatches' >> 'ace_common')) then {[_this, ['AudibleCoef', 1]] remoteExec ['setUnitTrait', _this]};
	if !(isClass (configFile >> 'CfgPatches' >> 'ace_common')) then {[_this, ['LoadCoef', 1]] remoteExec ['setUnitTrait', _this]};
	;
	if !(0 == ([0, 1] select (_this getUnitTrait 'engineer')) || {0 == -1}) then {_this setVariable ['s', 0, true]};
	_this setVariable ["ace_advanced_fatigue_performanceFactor", 1, true];
	_this setVariable ['ACE_isEOD', false, true];
	if (0 >= 0.1) then {_this setVariable ["ace_medical_damageThreshold", 0, true]};
	if (0 != -1 && {0 != (parseNumber (_this getUnitTrait 'medic'))}) then {_this setVariable ["ace_medical_medicClass", 0, true]};
	_this setVariable ["acre_sys_radio_setup", "[[""ACRE_PRC343"",[1,1]],[""ACRE_PRC152"",1],[""ACRE_PRC117F"",1]]", true];
};

private _item307 = objNull;
if (_layerRoot) then {
	_item307 = _item306 createUnit ["cwr3_b_soldier",[23392.8,18349.7,0],[],0,"CAN_COLLIDE"];
	_item306 selectLeader _item307;
	_this = _item307;
	_objects pushback _this;
	_objectIDs pushback 307;
	_this setPosWorld [23392.8,18349.8,3.19144];
	_this setVectorDirAndUp [[0.308502,-0.951224,0],[0,0,1]];
	_this setUnitLoadout [[],[],[],["cwr3_b_uniform_m81_woodland_rolled",[["FirstAidKit",1]]],["V_Simc_vest_pasgt",[["CUP_HandGrenade_M67",4,1]]],[],"H_Simc_pasgt_m81_PFC","",[],["ItemMap","","ItemRadio","ItemCompass","ItemWatch",""]];
	tweedleDum = _this;
	_this setVehicleVarName "tweedleDum";
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	if (!is3DEN && !isMultiplayer) then {_this setVariable ['ENH_SPR_Tickets', 0]};
	_this setname "Elliott James";;
	_this setspeaker "Male10ENG";;
	_this setpitch 0.96;;
	if (local _this) then {parseSimpleArray "[[""hitface"",""hitneck"",""hithead"",""hitpelvis"",""hitabdomen"",""hitdiaphragm"",""hitchest"",""hitbody"",""hitarms"",""hithands"",""hitlegs"",""incapacitated"",""hitleftarm"",""hitrightarm"",""hitleftleg"",""hitrightleg""],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]]" params ['_hitpoints', '_damage']; {if ((_damage # _forEachIndex) == 0) then {continue}; _this setHitPointDamage [_x, _damage # _forEachIndex, false]} forEach _hitpoints};
	            if (["SIT_AT_TABLE",["hubsittingattableu_idle1","hubsittingattableu_idle2","hubsittingattableu_idle3"],false,false] # 0 != '') then            {                ["SIT_AT_TABLE",["hubsittingattableu_idle1","hubsittingattableu_idle2","hubsittingattableu_idle3"],false,false] params ['_animSet', '_anims', '_canExit', '_attach'];                                _this setVariable ['ENH_ambientAnimations_anims', _anims];                _this disableAI 'ANIM';                if (_attach && !is3DEN) then                {                    private _logic = group _this createUnit ['Logic', getPosATL _this, [], 0, 'NONE'];                    _this setVariable ['ENH_ambientAnimations_logic', _logic];                    [_this, _logic] call BIS_fnc_attachToRelative;                };                                ENH_fnc_ambientAnimations_play =                {                    params ['_unit'];                    private _anim = selectRandom (_unit getVariable ['ENH_ambientAnimations_anims', []]);                    [_unit, _anim] remoteExec ['switchMove', 0];                };                                ENH_fnc_ambientAnimations_exit =                {                    params ['_unit'];                    if !(_unit getVariable ['ENH_ambientAnimations_exit', true]) exitWith {false};                    _unit setVariable ['ENH_ambientAnimations_exit', true];                    detach _unit;                    deleteVehicle (_unit getVariable ['ENH_ambientAnimations_logic', objNull]);                    if (alive _unit) then                    {                        [_unit, ''] remoteExec ['switchMove', 0];                        _unit enableAI 'ANIM';                    };                    _unit removeEventHandler ['Killed', _unit getVariable ['ENH_EHKilled',-1]];                    _unit removeEventHandler ['Dammaged', _unit getVariable ['ENH_EHDammaged',-1]];                    _unit removeEventHandler ['AnimDone', _unit getVariable ['ENH_EHAnimDone',-1]];                };                                private _EHAnimDone = _this addEventHandler ['AnimDone',                    {                        params ['_unit'];                        if (alive _unit) then                        {                            _unit call ENH_fnc_ambientAnimations_play;                        }                        else                        {                            _unit call ENH_fnc_ambientAnimations_exit;                        };                    }                ];                _this setVariable ['ENH_EHAnimDone', _EHAnimDone];                                if (_canExit && !is3DEN) then                {                    private _EHKilled = _this addEventHandler ['Killed',                    {                        (_this select 0) call ENH_fnc_ambientAnimations_exit;                    }];                    _this setVariable ['ENH_EHKilled', _EHKilled];                    private _EHDammaged = _this addEventHandler ['Dammaged',                    {                        (_this select 0) call ENH_fnc_ambientAnimations_exit;                    }];                    _this setVariable ['ENH_EHDammaged', _EHDammaged];                    _this spawn                    {                        scriptName 'ENH_Attribute_AmbientAnimations';                        params ['_unit'];                        waitUntil                        {                            sleep 1; (_unit getVariable ['ENH_ambientAnimations_exit', false]) || {behaviour _unit == 'COMBAT'}                        };                        _unit call ENH_fnc_ambientAnimations_exit;                    };                };                _this call ENH_fnc_ambientAnimations_play;            };;
	if (0.5 != 0.5) then {[_this, ['aimingShake', 0.5]] remoteExec ['setSkill', _this]};
	if (0.5 != 0.5) then {[_this, ['aimingSpeed', 0.5]] remoteExec ['setSkill', _this]};
	if (0.5 != 0.5) then {[_this, ['aimingAccuracy', 0.5]] remoteExec ['setSkill', _this]};
	if (0.5 != 0.5) then {[_this, ['commanding', 0.5]] remoteExec ['setSkill', _this]};
	if (0.5 != 0.5) then {[_this, ['courage', 0.5]] remoteExec ['setSkill', _this]};
	if (0.5 != 0.5) then {[_this, ['general', 0.5]] remoteExec ['setSkill', _this]};
	if (0.5 != 0.5) then {[_this, ['reloadSpeed', 0.5]] remoteExec ['setSkill', _this]};
	if (0.5 != 0.5) then {[_this, ['spotDistance', 0.5]] remoteExec ['setSkill', _this]};
	if (0.5 != 0.5) then {[_this, ['spotTime', 0.5]] remoteExec ['setSkill', _this]};
	if (0.5 != 0.5) then {[_this, 0.5] remoteExec ['allowFleeing', _this]};
	if !(isClass (configFile >> 'CfgPatches' >> 'ace_common')) then {[_this, ['Medic', false]] remoteExec ['setUnitTrait', _this]};
	if !(isClass (configFile >> 'CfgPatches' >> 'ace_common')) then {[_this, ['Engineer', false]] remoteExec ['setUnitTrait', _this]};
	if !(isClass (configFile >> 'CfgPatches' >> 'ace_common')) then {[_this, ['ExplosiveSpecialist', false]] remoteExec ['setUnitTrait', _this]};
	[_this, ['UAVHacker', false]] remoteExec ['setUnitTrait', _this];
	if !(isClass (configFile >> 'CfgPatches' >> 'ace_common')) then {[_this, ['CamouflageCoef', 1]] remoteExec ['setUnitTrait', _this]};
	if !(isClass (configFile >> 'CfgPatches' >> 'ace_common')) then {[_this, ['AudibleCoef', 1]] remoteExec ['setUnitTrait', _this]};
	if !(isClass (configFile >> 'CfgPatches' >> 'ace_common')) then {[_this, ['LoadCoef', 1]] remoteExec ['setUnitTrait', _this]};
	;
	if !(0 == ([0, 1] select (_this getUnitTrait 'engineer')) || {0 == -1}) then {_this setVariable ['s', 0, true]};
	_this setVariable ["ace_advanced_fatigue_performanceFactor", 1, true];
	_this setVariable ['ACE_isEOD', false, true];
	if (0 >= 0.1) then {_this setVariable ["ace_medical_damageThreshold", 0, true]};
	if (0 != -1 && {0 != (parseNumber (_this getUnitTrait 'medic'))}) then {_this setVariable ["ace_medical_medicClass", 0, true]};
	_this setVariable ["acre_sys_radio_setup", "[[""ACRE_PRC343"",[1,1]],[""ACRE_PRC152"",1],[""ACRE_PRC117F"",1]]", true];
};

private _item308 = objNull;
if (_layerRoot) then {
	_item308 = createVehicle ["Gunrack1",[23393.6,18351.9,0],[],0,"CAN_COLLIDE"];
	_this = _item308;
	_objects pushback _this;
	_objectIDs pushback 308;
	_this setPosWorld [23393.6,18351.9,3.69478];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item309 = objNull;
if (_layerRoot) then {
	_item309 = createVehicle ["Gunrack2",[23393.5,18352.2,0],[],0,"CAN_COLLIDE"];
	_this = _item309;
	_objects pushback _this;
	_objectIDs pushback 309;
	_this setPosWorld [23393.5,18352.2,3.55511];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item311 = objNull;
if (_layerRoot) then {
	_item311 = createVehicle ["Land_File1_F",[23392.7,18349,0.855968],[],0,"CAN_COLLIDE"];
	_this = _item311;
	_objects pushback _this;
	_objectIDs pushback 311;
	_this setPosWorld [23392.7,18349,4.05459];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
	_this setObjectTextureGlobal [0,"#(argb,8,8,3)color(0.835294,0,0,0.0,ca)"];
};

private _item312 = objNull;
if (_layerRoot) then {
	_item312 = createVehicle ["Land_Notepad_F",[23392.9,18349.3,0.864592],[],0,"CAN_COLLIDE"];
	_this = _item312;
	_objects pushback _this;
	_objectIDs pushback 312;
	_this setPosWorld [23392.9,18349.3,4.06566];
	_this setVectorDirAndUp [[0.925935,0.377684,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
	_this setObjectTextureGlobal [0,"#(argb,8,8,3)color(0.835294,0,0,0.0,ca)"];
};

private _item313 = objNull;
if (_layerRoot) then {
	_item313 = createVehicle ["Land_PenRed_F",[23392.8,18349.2,0.851118],[],0,"CAN_COLLIDE"];
	_this = _item313;
	_objects pushback _this;
	_objectIDs pushback 313;
	_this setPosWorld [23392.8,18349.2,4.049];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item315 = objNull;
if (_layerRoot) then {
	_item315 = createVehicle ["Newspaper_01_F",[23393.2,18349,0.864592],[],0,"CAN_COLLIDE"];
	_this = _item315;
	_objects pushback _this;
	_objectIDs pushback 315;
	_this setPosWorld [23393.2,18349,4.06648];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item316 = objNull;
if (_layerRoot) then {
	_item316 = createVehicle ["ClutterCutter_EP1",[23357,18329.6,0],[],0,"CAN_COLLIDE"];
	_this = _item316;
	_objects pushback _this;
	_objectIDs pushback 316;
	_this setPosWorld [23357,18329.6,3.19];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item317 = objNull;
if (_layerRoot) then {
	_item317 = createVehicle ["ClutterCutter_EP1",[23353.1,18349.7,0],[],0,"CAN_COLLIDE"];
	_this = _item317;
	_objects pushback _this;
	_objectIDs pushback 317;
	_this setPosWorld [23353.1,18349.7,3.19];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item318 = objNull;
if (_layerRoot) then {
	_item318 = createVehicle ["ClutterCutter_EP1",[23363.4,18360.2,0],[],0,"CAN_COLLIDE"];
	_this = _item318;
	_objects pushback _this;
	_objectIDs pushback 318;
	_this setPosWorld [23363.4,18360.2,3.19];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item319 = objNull;
if (_layerRoot) then {
	_item319 = createVehicle ["ClutterCutter_EP1",[23376.7,18350.4,1.81084],[],0,"CAN_COLLIDE"];
	_this = _item319;
	_objects pushback _this;
	_objectIDs pushback 319;
	_this setPosWorld [23376.7,18350.4,5.00084];
	_this setVectorDirAndUp [[0,0.999999,-0.00109183],[0,0.00109183,0.999999]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item320 = objNull;
if (_layerRoot) then {
	_item320 = createVehicle ["ClutterCutter_EP1",[23393.8,18354.9,0],[],0,"CAN_COLLIDE"];
	_this = _item320;
	_objects pushback _this;
	_objectIDs pushback 320;
	_this setPosWorld [23393.8,18354.9,3.19];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item321 = objNull;
if (_layerRoot) then {
	_item321 = createVehicle ["ClutterCutter_EP1",[23403,18360,4.00486],[],0,"CAN_COLLIDE"];
	_this = _item321;
	_objects pushback _this;
	_objectIDs pushback 321;
	_this setPosWorld [23403,18360,7.19486];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item322 = objNull;
if (_layerRoot) then {
	_item322 = createVehicle ["ClutterCutter_EP1",[23402.4,18344.7,0],[],0,"CAN_COLLIDE"];
	_this = _item322;
	_objects pushback _this;
	_objectIDs pushback 322;
	_this setPosWorld [23402.4,18344.7,3.19];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item323 = objNull;
if (_layerRoot) then {
	_item323 = createVehicle ["ClutterCutter_EP1",[23402.7,18335,0],[],0,"CAN_COLLIDE"];
	_this = _item323;
	_objects pushback _this;
	_objectIDs pushback 323;
	_this setPosWorld [23402.7,18335,3.19];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item324 = objNull;
if (_layerRoot) then {
	_item324 = createVehicle ["ClutterCutter_EP1",[23402.4,18327.4,0.17834],[],0,"CAN_COLLIDE"];
	_this = _item324;
	_objects pushback _this;
	_objectIDs pushback 324;
	_this setPosWorld [23402.4,18327.4,3.36834];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item325 = objNull;
if (_layerRoot) then {
	_item325 = createVehicle ["ClutterCutter_EP1",[23384.8,18330.6,0],[],0,"CAN_COLLIDE"];
	_this = _item325;
	_objects pushback _this;
	_objectIDs pushback 325;
	_this setPosWorld [23384.8,18330.6,3.19];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item326 = objNull;
if (_layerRoot) then {
	_item326 = createVehicle ["ClutterCutter_EP1",[23387.8,18341.3,0],[],0,"CAN_COLLIDE"];
	_this = _item326;
	_objects pushback _this;
	_objectIDs pushback 326;
	_this setPosWorld [23387.8,18341.3,3.19];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item327 = objNull;
if (_layerRoot) then {
	_item327 = createVehicle ["ClutterCutter_EP1",[23371.1,18340.2,0],[],0,"CAN_COLLIDE"];
	_this = _item327;
	_objects pushback _this;
	_objectIDs pushback 327;
	_this setPosWorld [23371.1,18340.2,3.19];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item330 = objNull;
if (_layerRoot) then {
	_item330 = createVehicle ["Land_PaperBox_closed_F",[23389.3,18354.4,0],[],0,"CAN_COLLIDE"];
	_this = _item330;
	_objects pushback _this;
	_objectIDs pushback 330;
	_this setPosWorld [23389.3,18354.4,3.8332];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
	[_this, 11] call ace_cargo_fnc_setSize;
};

private _item334 = objNull;
if (_layerRoot) then {
	_item334 = createVehicle ["Land_Magazine_rifle_F",[23392,18348.9,0.864592],[],0,"CAN_COLLIDE"];
	_this = _item334;
	_objects pushback _this;
	_objectIDs pushback 334;
	_this setPosWorld [23392,18348.9,4.06206];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item335 = objNull;
if (_layerRoot) then {
	_item335 = createVehicle ["Land_Magazine_rifle_F",[23391.9,18348.9,0.864592],[],0,"CAN_COLLIDE"];
	_this = _item335;
	_objects pushback _this;
	_objectIDs pushback 335;
	_this setPosWorld [23391.9,18348.9,4.06206];
	_this setVectorDirAndUp [[0.439553,0.898217,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item336 = objNull;
if (_layerRoot) then {
	_item336 = createVehicle ["Land_WoodenCrate_01_stack_x5_F",[23393.6,18354.7,2.38419e-07],[],0,"CAN_COLLIDE"];
	_this = _item336;
	_objects pushback _this;
	_objectIDs pushback 336;
	_this setPosWorld [23393.6,18354.7,4.15197];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item337 = objNull;
if (_layerRoot) then {
	_item337 = createVehicle ["Land_CanisterFuel_F",[23392.4,18354.3,0],[],0,"CAN_COLLIDE"];
	_this = _item337;
	_objects pushback _this;
	_objectIDs pushback 337;
	_this setPosWorld [23392.4,18354.3,3.4635];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
	if (300 != (_this call ace_refuel_fnc_getFuelCargo)) then {[_this, 300] call ace_refuel_fnc_makeSource};
	[_this, 1] call ace_cargo_fnc_setSize;
};

private _item338 = objNull;
if (_layerRoot) then {
	_item338 = createVehicle ["Land_CanisterFuel_F",[23392.4,18354.5,0],[],0,"CAN_COLLIDE"];
	_this = _item338;
	_objects pushback _this;
	_objectIDs pushback 338;
	_this setPosWorld [23392.4,18354.5,3.4635];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
	if (300 != (_this call ace_refuel_fnc_getFuelCargo)) then {[_this, 300] call ace_refuel_fnc_makeSource};
	[_this, 1] call ace_cargo_fnc_setSize;
};

private _item339 = objNull;
if (_layerRoot) then {
	_item339 = createVehicle ["Land_CanisterFuel_White_F",[23392.4,18354.7,0],[],0,"CAN_COLLIDE"];
	_this = _item339;
	_objects pushback _this;
	_objectIDs pushback 339;
	_this setPosWorld [23392.4,18354.7,3.4635];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
	if (300 != (_this call ace_refuel_fnc_getFuelCargo)) then {[_this, 300] call ace_refuel_fnc_makeSource};
	[_this, 1] call ace_cargo_fnc_setSize;
};

private _item340 = objNull;
if (_layerRoot) then {
	_item340 = createVehicle ["Land_FireExtinguisher_F",[23392.6,18353.8,0],[],0,"CAN_COLLIDE"];
	_this = _item340;
	_objects pushback _this;
	_objectIDs pushback 340;
	_this setPosWorld [23392.6,18353.8,3.57516];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item341 = objNull;
if (_layerRoot) then {
	_item341 = createVehicle ["Land_Shovel_F",[23391.6,18348.9,0.864592],[],0,"CAN_COLLIDE"];
	_this = _item341;
	_objects pushback _this;
	_objectIDs pushback 341;
	_this setPosWorld [23391.6,18348.9,4.07571];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item342 = objNull;
if (_layerRoot) then {
	_item342 = createVehicle ["Land_DuctTape_F",[23391.4,18348.9,0.864592],[],0,"CAN_COLLIDE"];
	_this = _item342;
	_objects pushback _this;
	_objectIDs pushback 342;
	_this setPosWorld [23391.4,18348.9,4.07959];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item344 = objNull;
if (_layerRoot) then {
	_item344 = createVehicle ["Land_FloodLight_F",[23395,18346,1.1149],[],0,"CAN_COLLIDE"];
	_this = _item344;
	_objects pushback _this;
	_objectIDs pushback 344;
	_this setPosWorld [23395,18346,4.48775];
	_this setVectorDirAndUp [[-0.494112,-0.869398,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item345 = objNull;
if (_layerRoot) then {
	_item345 = createVehicle ["Land_Camera_01_F",[23391.4,18348.5,0.864591],[],0,"CAN_COLLIDE"];
	_this = _item345;
	_objects pushback _this;
	_objectIDs pushback 345;
	_this setPosWorld [23391.4,18348.5,4.09169];
	_this setVectorDirAndUp [[0.999949,0.0101006,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item346 = objNull;
if (_layerRoot) then {
	_item346 = createVehicle ["Land_Notepad_F",[23392.4,18348.5,0.864592],[],0,"CAN_COLLIDE"];
	_this = _item346;
	_objects pushback _this;
	_objectIDs pushback 346;
	_this setPosWorld [23392.4,18348.5,4.06566];
	_this setVectorDirAndUp [[-0.997236,-0.0742928,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
	_this setObjectTextureGlobal [0,"#(argb,8,8,3)color(0.835294,0,0,0.0,ca)"];
};

private _item295 = objNull;
if (_layerRoot) then {
	_item295 = createVehicle ["Land_WoodenTable_large_F",[23392.3,18348.9,0],[],0,"CAN_COLLIDE"];
	_this = _item295;
	_objects pushback _this;
	_objectIDs pushback 295;
	_this setPosWorld [23392.3,18348.9,3.6223];
	_this setVectorDirAndUp [[-0.99817,-0.0604637,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item351 = objNull;
if (_layerRoot) then {
	_item351 = createVehicle ["land_gm_euro_stationary_02",[23392.2,18348.4,0.864592],[],0,"CAN_COLLIDE"];
	_this = _item351;
	_objects pushback _this;
	_objectIDs pushback 351;
	_this setPosWorld [23392.2,18348.4,4.05458];
	_this setVectorDirAndUp [[0.999576,-0.0291138,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
	_this setObjectTextureGlobal [0,"gm\gm_structures\gm_structures_euro_80\furniture\data\gm_euro_furniture_stationary_01_text_co.paa"];
};

private _item352 = objNull;
if (_layerRoot) then {
	_item352 = createVehicle ["Sign_F",[23388.2,18346.3,0],[],0,"CAN_COLLIDE"];
	_this = _item352;
	_objects pushback _this;
	_objectIDs pushback 352;
	_this setPosWorld [23388.2,18346.3,3.89626];
	_this setVectorDirAndUp [[-0.999487,-0.0320332,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item354 = objNull;
if (_layerRoot) then {
	_item354 = createVehicle ["Flag_NATO_F",[23399.4,18332.7,0],[],0,"CAN_COLLIDE"];
	_this = _item354;
	_objects pushback _this;
	_objectIDs pushback 354;
	_this setPosWorld [23399.4,18332.7,7.1668];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item355 = objNull;
if (_layerRoot) then {
	_item355 = createVehicle ["Flag_US_F",[23397.3,18332.7,0],[],0,"CAN_COLLIDE"];
	_this = _item355;
	_objects pushback _this;
	_objectIDs pushback 355;
	_this setPosWorld [23397.3,18332.7,7.1668];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item358 = objNull;
if (_layerRoot) then {
	_item358 = createVehicle ["vn_sign_town_d_12",[23388.3,18345.7,0.832231],[],0,"CAN_COLLIDE"];
	_this = _item358;
	_objects pushback _this;
	_objectIDs pushback 358;
	_this setPosWorld [23388.3,18345.7,4.02223];
	_this setVectorDirAndUp [[-0.999372,-0.0354416,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item359 = objNull;
if (_layerRoot) then {
	_item359 = createVehicle ["Land_vn_usaf_sign_ns_01",[23388.3,18346.8,1.69308],[],0,"CAN_COLLIDE"];
	_this = _item359;
	_objects pushback _this;
	_objectIDs pushback 359;
	_this setPosWorld [23388.3,18346.8,4.88308];
	_this setVectorDirAndUp [[-0.999237,-0.0390506,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item360 = objNull;
if (_layerRoot) then {
	_item360 = createVehicle ["land_gm_euro_furniture_book_01",[23391.9,18348.4,0.864592],[],0,"CAN_COLLIDE"];
	_this = _item360;
	_objects pushback _this;
	_objectIDs pushback 360;
	_this setPosWorld [23391.9,18348.4,4.05582];
	_this setVectorDirAndUp [[-0.126254,0.991998,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item361 = objNull;
if (_layerRoot) then {
	_item361 = createVehicle ["land_gm_euro_furniture_infoboard_01",[23388.2,18346.8,1.03532],[],0,"CAN_COLLIDE"];
	_this = _item361;
	_objects pushback _this;
	_objectIDs pushback 361;
	_this setPosWorld [23388.2,18346.8,4.22532];
	_this setVectorDirAndUp [[-0.998167,-0.0605261,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item364 = objNull;
if (_layerRoot) then {
	_item364 = createVehicle ["land_cwr3_wall_wood1_5",[23409.6,18335.8,0],[],0,"CAN_COLLIDE"];
	_this = _item364;
	_objects pushback _this;
	_objectIDs pushback 364;
	_this setPosWorld [23409.6,18335.8,3.17038];
	_this setVectorDirAndUp [[-0.999991,0.0043478,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item368 = objNull;
if (_layerRoot) then {
	_item368 = createVehicle ["vn_b_prop_cabinet_01_01",[23394.4,18350.3,0],[],0,"CAN_COLLIDE"];
	_this = _item368;
	_objects pushback _this;
	_objectIDs pushback 368;
	_this setPosWorld [23394.4,18350.3,3.19];
	_this setVectorDirAndUp [[0.99905,0.0435866,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item369 = objNull;
if (_layerRoot) then {
	_item369 = createVehicle ["cwr3_metal_locker",[23395.1,18348,0],[],0,"CAN_COLLIDE"];
	_this = _item369;
	_objects pushback _this;
	_objectIDs pushback 369;
	_this setPosWorld [23395.1,18348,4.11339];
	_this setVectorDirAndUp [[0.997299,0.0734491,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item370 = objNull;
if (_layerRoot) then {
	_item370 = createVehicle ["Land_BagFence_01_long_green_F",[23409.9,18337.1,0.710443],[],0,"CAN_COLLIDE"];
	_this = _item370;
	_objects pushback _this;
	_objectIDs pushback 370;
	_this setPosWorld [23409.9,18337.1,4.31775];
	_this setVectorDirAndUp [[-0.999506,0.0314384,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item371 = objNull;
if (_layerRoot) then {
	_item371 = createVehicle ["Land_BagFence_01_long_green_F",[23409.9,18334.7,0.710443],[],0,"CAN_COLLIDE"];
	_this = _item371;
	_objects pushback _this;
	_objectIDs pushback 371;
	_this setPosWorld [23409.9,18334.7,4.31775];
	_this setVectorDirAndUp [[-0.999506,0.0314384,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item372 = objNull;
if (_layerRoot) then {
	_item372 = createVehicle ["land_gm_sandbags_01_door_01",[23409.5,18333.4,0],[],0,"CAN_COLLIDE"];
	_this = _item372;
	_objects pushback _this;
	_objectIDs pushback 372;
	_this setPosWorld [23409.5,18333.4,3.19];
	_this setVectorDirAndUp [[-0.0300165,0.999549,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item375 = objNull;
if (_layerRoot) then {
	_item375 = createVehicle ["land_gm_sandbags_01_door_01",[23399.9,18321.4,0],[],0,"CAN_COLLIDE"];
	_this = _item375;
	_objects pushback _this;
	_objectIDs pushback 375;
	_this setPosWorld [23399.9,18321.4,3.19];
	_this setVectorDirAndUp [[-0.0300165,0.999549,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item376 = objNull;
if (_layerRoot) then {
	_item376 = createVehicle ["land_gm_sandbags_01_door_01",[23398.9,18321.4,0],[],0,"CAN_COLLIDE"];
	_this = _item376;
	_objects pushback _this;
	_objectIDs pushback 376;
	_this setPosWorld [23398.9,18321.4,3.19];
	_this setVectorDirAndUp [[-0.0300165,0.999549,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item377 = objNull;
if (_layerRoot) then {
	_item377 = createVehicle ["Land_BagFence_01_end_green_F",[23409.7,18333.8,0],[],0,"CAN_COLLIDE"];
	_this = _item377;
	_objects pushback _this;
	_objectIDs pushback 377;
	_this setPosWorld [23409.7,18333.8,3.59966];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item378 = objNull;
if (_layerRoot) then {
	_item378 = createVehicle ["Land_BagFence_01_end_green_F",[23409.7,18334.2,0],[],0,"CAN_COLLIDE"];
	_this = _item378;
	_objects pushback _this;
	_objectIDs pushback 378;
	_this setPosWorld [23409.7,18334.2,3.59966];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item379 = objNull;
if (_layerRoot) then {
	_item379 = createVehicle ["Land_BagFence_01_end_green_F",[23408.8,18344.5,0.874115],[],0,"CAN_COLLIDE"];
	_this = _item379;
	_objects pushback _this;
	_objectIDs pushback 379;
	_this setPosWorld [23408.8,18344.5,4.47378];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item380 = objNull;
if (_layerRoot) then {
	_item380 = createVehicle ["Land_SandbagBarricade_01_half_F",[23395.4,18354.9,0],[],0,"CAN_COLLIDE"];
	_this = _item380;
	_objects pushback _this;
	_objectIDs pushback 380;
	_this setPosWorld [23395.4,18354.9,3.85899];
	_this setVectorDirAndUp [[-1,-0.000888336,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item381 = objNull;
if (_layerRoot) then {
	_item381 = createVehicle ["land_gm_sandbags_01_door_02",[23386.2,18354.8,0],[],0,"CAN_COLLIDE"];
	_this = _item381;
	_objects pushback _this;
	_objectIDs pushback 381;
	_this setPosWorld [23386.2,18354.8,3.19];
	_this setVectorDirAndUp [[-0.999863,0.0165541,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item382 = objNull;
if (_layerRoot) then {
	_item382 = createVehicle ["land_gm_sandbags_01_door_02",[23385.8,18356.2,0],[],0,"CAN_COLLIDE"];
	_this = _item382;
	_objects pushback _this;
	_objectIDs pushback 382;
	_this setPosWorld [23385.8,18356.2,3.19];
	_this setVectorDirAndUp [[-0.10375,0.994603,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item383 = objNull;
if (_layerRoot) then {
	_item383 = createVehicle ["land_gm_woodbunker_01_bags",[23388.5,18360.4,0],[],0,"CAN_COLLIDE"];
	_this = _item383;
	_objects pushback _this;
	_objectIDs pushback 383;
	_this setPosWorld [23388.5,18360.4,3.19];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item384 = objNull;
if (_layerRoot) then {
	_item384 = createVehicle ["Land_vn_sandbagbarricade_01_half_f",[23394.8,18356.4,0],[],0,"CAN_COLLIDE"];
	_this = _item384;
	_objects pushback _this;
	_objectIDs pushback 384;
	_this setPosWorld [23394.8,18356.4,3.85899];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item385 = objNull;
if (_layerRoot) then {
	_item385 = createVehicle ["land_gm_sandbags_01_wall_02",[23391.6,18356.4,0],[],0,"CAN_COLLIDE"];
	_this = _item385;
	_objects pushback _this;
	_objectIDs pushback 385;
	_this setPosWorld [23391.6,18356.4,3.19];
	_this setVectorDirAndUp [[0,1,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item386 = objNull;
if (_layerRoot) then {
	_item386 = createVehicle ["Land_vn_bagfence_01_long_green_f",[23387.8,18356.4,0],[],0,"CAN_COLLIDE"];
	_this = _item386;
	_objects pushback _this;
	_objectIDs pushback 386;
	_this setPosWorld [23387.8,18356.4,3.60731];
	_this setVectorDirAndUp [[-0.090408,0.995905,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item387 = objNull;
if (_layerRoot) then {
	_item387 = createVehicle ["Land_vn_bagfence_01_long_green_f",[23385.1,18354.8,0],[],0,"CAN_COLLIDE"];
	_this = _item387;
	_objects pushback _this;
	_objectIDs pushback 387;
	_this setPosWorld [23385.1,18354.8,3.60731];
	_this setVectorDirAndUp [[0.999395,0.0347726,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};

private _item388 = objNull;
if (_layerRoot) then {
	_item388 = createVehicle ["Land_BagFence_Long_F",[23386.4,18356.2,0.791383],[],0,"CAN_COLLIDE"];
	_this = _item388;
	_objects pushback _this;
	_objectIDs pushback 388;
	_this setPosWorld [23386.4,18356.2,4.40069];
	_this setVectorDirAndUp [[0.114012,-0.993479,0],[0,0,1]];
	[_this, 0] remoteExec ['setFeatureType', 0, _this];
	;
};


///////////////////////////////////////////////////////////////////////////////////////////
// Triggers
private _triggers = [];
private _triggerIDs = [];


///////////////////////////////////////////////////////////////////////////////////////////
// Group attributes (applied only once group units exist)
_this = _item290;
if !(units _this isEqualTo []) then {
	[_this,0] setWaypointPosition [position leader _this,0];
	                            if (isNil 'CBA_fnc_setCallsign') then {                                _this setGroupID ["Alpha 1-1"];                            } else {                                [_this, "Alpha 1-1"] call CBA_fnc_setCallsign;                            };;
	if (!is3DEN && 0 > 0) then {[_this, getPosATL (leader _this), 0] call BIS_fnc_taskPatrol};
	;
	;
};
_this = _item304;
if !(units _this isEqualTo []) then {
	[_this,0] setWaypointPosition [position leader _this,0];
	                            if (isNil 'CBA_fnc_setCallsign') then {                                _this setGroupID ["Alpha 1-2"];                            } else {                                [_this, "Alpha 1-2"] call CBA_fnc_setCallsign;                            };;
	if (!is3DEN && 0 > 0) then {[_this, getPosATL (leader _this), 0] call BIS_fnc_taskPatrol};
	;
	;
};
_this = _item306;
if !(units _this isEqualTo []) then {
	[_this,0] setWaypointPosition [position leader _this,0];
	                            if (isNil 'CBA_fnc_setCallsign') then {                                _this setGroupID ["Alpha 1-3"];                            } else {                                [_this, "Alpha 1-3"] call CBA_fnc_setCallsign;                            };;
	if (!is3DEN && 0 > 0) then {[_this, getPosATL (leader _this), 0] call BIS_fnc_taskPatrol};
	;
	;
};


///////////////////////////////////////////////////////////////////////////////////////////
// Waypoints
private _waypoints = [];
private _waypointIDs = [];


///////////////////////////////////////////////////////////////////////////////////////////
// Logics
private _logics = [];
private _logicIDs = [];


///////////////////////////////////////////////////////////////////////////////////////////
// Layers
if (_layer143) then {missionNamespace setVariable ["11acr_Base_Template_Bunker (Large) #B1",[[_item121,_item123,_item124,_item125,_item127,_item128,_item129,_item130,_item132,_item133,_item134,_item135,_item139,_item140,_item141,_item204,_item209,_item210,_item211,_item212,_item213,_item214,_item215,_item216,_item217,_item218,_item219,_item220,_item228,_item231,_item232,_item233,_item234,_item235,_item236,_item237,_item238,_item239,_item240,_item241,_item242,_item243,_item244,_item245,_item246,_item247,_item248,_item249,_item250,_item251,_item252,_item253,_item254,_item255,_item256,_item257,_item365,_item367],[]]];};
if (_layer105) then {missionNamespace setVariable ["11acr_Base_Template_Dugout 2",[[_item100],[]]];};
if (_layer99) then {missionNamespace setVariable ["11acr_Base_Template_Dugout 1",[[_item90,_item91,_item92,_item93,_item94,_item95,_item97,_item98],[]]];};
if (_layer47) then {missionNamespace setVariable ["11acr_Base_Template_Outpost 5",[[_item34,_item35,_item36,_item37,_item38,_item39,_item40,_item43,_item44,_item46,_item224,_item225,_item226,_item227],[]]];};
if (_layer33) then {missionNamespace setVariable ["11acr_Base_Template_Vehicle Camp (NATO)",[[_item0,_item1,_item2,_item3,_item4,_item5,_item6,_item7,_item8,_item9,_item10,_item12,_item13,_item14,_item15,_item16,_item17,_item18,_item20,_item21,_item22,_item23,_item24,_item25,_item26,_item27,_item28,_item30,_item31,_item32,_item159,_item201,_item202,_item203],[]]];};


///////////////////////////////////////////////////////////////////////////////////////////
// Crews


///////////////////////////////////////////////////////////////////////////////////////////
// Vehicle cargo


///////////////////////////////////////////////////////////////////////////////////////////
// Connections


///////////////////////////////////////////////////////////////////////////////////////////
// Inits (executed only once all entities exist; isNil used to ensure non-scheduled environment)
isNil {
};


///////////////////////////////////////////////////////////////////////////////////////////
// Module activations (only once everything is spawned and connected)


///////////////////////////////////////////////////////////////////////////////////////////
[[_objects,_groups,_triggers,_waypoints,_logics,_markers],[_objectIDs,_groupIDs,_triggerIDs,_waypointIDs,_logicIDs,_markerIDs]]
