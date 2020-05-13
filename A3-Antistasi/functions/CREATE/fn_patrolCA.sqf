if (!isServer and hasInterface) exitWith {};

/*  Sends a QRF force towards the given position

    Execution on: Server

    Scope: External

    Params:
        _destination: POSITION : The target position where the QRF will be send to
        _side: SIDE : The start parameter of the QRF
        _attackType: STRING : Can be one of "Air", "Tank", "Normal" or ""
        _super: BOOLEAN : Determine if the attack should be super strong
*/


//[position player,Occupants,"Normal",false] spawn A3A_Fnc_patrolCA
params ["_destination", "_side", "_attackType", "_super"];
private _filename = "fn_patrolCA";

_super = if (!isMultiplayer) then {false};
private _posOrigin = [];
private _posDestination = [];

[2, format ["Spawning QRF. Target:%1, Side:%2, Type:%3, IsSuper:%4",_destination,_side,_typeOfAttack,_super], _filename] call A3A_fnc_log;

//If too foggy for anything abort here
if ([_destination,false] call A3A_fnc_fogCheck < 0.3) exitWith
{
    [2, format ["QRF to %1 cancelled due to heavy fog",_destination], _filename] call A3A_fnc_log
};

private _exit = false;
private _enemyGroups = allGroups select
{
    (side _x != _side) &&
    {side _x != civilian &&
    {(getPos (leader _x) distance2D _posDestination) < distanceSPWN2}}
}
private _nearEnemies = []
{
    _nearEnemies append ((units _x) select {alive _x});
} forEach _enemyGroups;

private _threatEvalLand = [_posDestination,_side] call A3A_fnc_landThreatEval;;

private _availableAirports = airportsX select
{
    (sidesX getVariable [_x,sideUnknown] == _side) &&
    {([_x,true] call A3A_fnc_airportCanAttack) &&
    {getMarkerPos _x distance2D _posDestination < distanceForAirAttack}}
};

if (hasIFA && (_threatEvalLand <= 15)) then
{
    _availableAirports = _availableAirports select {(getMarkerPos _x distance2D _posDestination < distanceForLandAttack)}
};
private _outposts = if (_threatEvalLand <= 15) then
{
    outposts select
    {
        (sidesX getVariable [_x,sideUnknown] == _side) &&
        {([_x,true] call A3A_fnc_airportCanAttack) &&
        {(getMarkerPos _x distance _posDestination < distanceForLandAttack) &&
        {[_posDestination, getMarkerPos _x] call A3A_fnc_isTheSameIsland}}}
    }
}
else
{
    []
};
_availableAirports = _availableAirports + _outposts;
private _nearestMarker = [(resourcesX + factories + airportsX + outposts + seaports),_posDestination] call BIS_fnc_nearestPosition;
private _markerOrigin = "";
_availableAirports = _availableAirports select
{
    ({_x == _nearestMarker} count (killZones getVariable [_x,[]])) < 3
};
if !(_availableAirports isEqualTo []) then
{
    _markerOrigin = [_availableAirports, _posDestination] call BIS_fnc_nearestPosition;
	_posOrigin = getMarkerPos _markerOrigin;
};

if (_markerOrigin == "") exitWith
{
    [2, format ["QRF to %1 cancelled because no usable bases in vicinity",_destination], _filename] call A3A_fnc_log
};


private _allAIUnits = {(alive _x) && {!(isPlayer _x)}} count allUnits;
private _allUnitsSide = 0;
private _maxUnitsSide = maxUnits;

if (gameMode <3) then
{
	_allUnitsSide = {(alive _x) && {(side group _x == _side) && {!(isPlayer)}}} count allUnits;
	_maxUnitsSide = round (maxUnits * 0.7);
};
if ((_allAIUnits + 4 > maxUnits) || (_allUnitsSide + 4 > _maxUnitsSide)) then
{
    [2, format ["QRF to %1 cancelled because maximum unit count reached",_destination], _filename] call A3A_fnc_log
};

//if (debug) then {hint format ["Nos contraatacan desde %1 o desde el airportX %2 hacia %3", _base, _side,_destination]; sleep 5};
//diag_log format ["Antistasi PatrolCA: CA performed from %1 to %2.Is waved:%3.Is super:%4",_side,_destination,_inWaves,_super];
//_config = if (_side == Occupants) then {cfgNATOInf} else {cfgCSATInf};

_soldiers = [];
_vehiclesX = [];
_groups = [];
_roads = [];

if (_base != "") then
	{
	_side = "";
	if (_base in outposts) then {[_base,60] call A3A_fnc_addTimeForIdle} else {[_base,30] call A3A_fnc_addTimeForIdle};
	_indexX = airportsX find _base;
	_spawnPoint = objNull;
	_pos = [];
	_dir = 0;
	if (_indexX > -1) then
		{
		_spawnPoint = server getVariable (format ["spawn_%1", _base]);
		_pos = getMarkerPos _spawnPoint;
		_dir = markerDir _spawnPoint;
		}
	else
		{
		_spawnPoint = [_posOrigin] call A3A_fnc_findNearestGoodRoad;
		_pos = position _spawnPoint;
		_dir = getDir _spawnPoint;
		};

	_vehPool = if (_side == Occupants) then {vehNATOAttack select {[_x] call A3A_fnc_vehAvailable}} else {vehCSATAttack select {[_x] call A3A_fnc_vehAvailable}};
	_road = [_posDestination] call A3A_fnc_findNearestGoodRoad;
	if ((position _road) distance _posDestination > 150) then {_vehPool = _vehPool - vehTanks};
	if (_isSDK) then
		{
		_rnd = random 100;
		if (_side == Occupants) then
			{
			if (_rnd > aggressionOccupants) then
				{
				_vehPool = _vehPool - [vehNATOTank];
				};
			}
		else
			{
			if (_rnd > aggressionInvaders) then
				{
				_vehPool = _vehPool - [vehCSATTank];
				};
			};
		};
	_countX = if (!_super) then {if (_isMarker) then {2} else {1}} else {round ((tierWar + difficultyCoef) / 2) + 1};
	_landPosBlacklist = [];
	for "_i" from 1 to _countX do
		{
		if (_vehPool isEqualTo []) then {if (_side == Occupants) then {_vehPool = vehNATOTrucks} else {_vehPool = vehCSATTrucks}};
		_typeVehX = if (_i == 1) then
						{
						if (_typeOfAttack == "Normal") then
							{
							selectRandom _vehPool
							}
						else
							{
							if (_typeOfAttack == "Air") then
								{
								if (_side == Occupants) then
									{
									if ([vehNATOAA] call A3A_fnc_vehAvailable) then {vehNATOAA} else {selectRandom _vehPool}
									}
								else
									{
									if ([vehCSATAA] call A3A_fnc_vehAvailable) then {vehCSATAA} else {selectRandom _vehPool}
									};
								}
							else
								{
								if (_side == Occupants) then
									{
									if ([vehNATOTank] call A3A_fnc_vehAvailable) then {vehNATOTank} else {selectRandom _vehPool}
									}
								else
									{
									if ([vehCSATTank] call A3A_fnc_vehAvailable) then {vehCSATTank} else {selectRandom _vehPool}
									};
								};
							};
						}
					else
						{
						if ((_isMarker) and !((_vehPool - vehTanks) isEqualTo [])) then {selectRandom (_vehPool - vehTanks)} else {selectRandom _vehPool};
						};
		//_road = _roads select 0;
		_timeOut = 0;
		_pos = _pos findEmptyPosition [0,100,_typeVehX];
		while {_timeOut < 60} do
			{
			if (count _pos > 0) exitWith {};
			_timeOut = _timeOut + 1;
			_pos = _pos findEmptyPosition [0,100,_typeVehX];
			sleep 1;
			};
		if (count _pos == 0) then {_pos = if (_indexX == -1) then {getMarkerPos _spawnPoint} else {position _spawnPoint}};
		_vehicle=[_pos, _dir,_typeVehX, _side] call bis_fnc_spawnvehicle;

		_veh = _vehicle select 0;
		_vehCrew = _vehicle select 1;
		{[_x] call A3A_fnc_NATOinit} forEach _vehCrew;
		[_veh] call A3A_fnc_AIVEHinit;
		_groupVeh = _vehicle select 2;
		_soldiers = _soldiers + _vehCrew;
		_groups pushBack _groupVeh;
		_vehiclesX pushBack _veh;
		_landPos = [_posDestination,_pos,false,_landPosBlacklist] call A3A_fnc_findSafeRoadToUnload;
		if ((not(_typeVehX in vehTanks)) and (not(_typeVehX in vehAA))) then
			{
			_landPosBlacklist pushBack _landPos;
			_typeGroup = if (_typeOfAttack == "Normal") then
				{
				[_typeVehX,_side] call A3A_fnc_cargoSeats;
				}
			else
				{
				if (_typeOfAttack == "Air") then
					{
					if (_side == Occupants) then {groupsNATOAA} else {groupsCSATAA}
					}
				else
					{
					if (_side == Occupants) then {groupsNATOAT} else {groupsCSATAT}
					};
				};
			_groupX = [_posOrigin,_side,_typeGroup] call A3A_fnc_spawnGroup;
			{
			_x assignAsCargo _veh;
			_x moveInCargo _veh;
			if (vehicle _x == _veh) then
				{
				_soldiers pushBack _x;
				[_x] call A3A_fnc_NATOinit;
				_x setVariable ["originX",_base];
				}
			else
				{
				deleteVehicle _x;
				};
			} forEach units _groupX;
			if (not(_typeVehX in vehTrucks)) then
				{
				{_x disableAI "MINEDETECTION"} forEach (units _groupVeh);
				(units _groupX) joinSilent _groupVeh;
				deleteGroup _groupX;
				_groupVeh spawn A3A_fnc_attackDrillAI;
				//_groups pushBack _groupX;
				[_base,_landPos,_groupVeh] call A3A_fnc_WPCreate;
				_Vwp0 = (wayPoints _groupVeh) select 0;
				_Vwp0 setWaypointBehaviour "SAFE";
				_Vwp0 = _groupVeh addWaypoint [_landPos,count (wayPoints _groupVeh)];
				_Vwp0 setWaypointType "TR UNLOAD";
				//_Vwp0 setWaypointStatements ["true", "(group this) spawn A3A_fnc_attackDrillAI"];
				//_Vwp0 setWaypointStatements ["true", "[vehicle this] call A3A_fnc_smokeCoverAuto"];
				_Vwp1 = _groupVeh addWaypoint [_posDestination, count (wayPoints _groupVeh)];
				_Vwp1 setWaypointType "SAD";
				_Vwp1 setWaypointStatements ["true","{if (side _x != side this) then {this reveal [_x,4]}} forEach allUnits"];
				_Vwp1 setWaypointBehaviour "COMBAT";
				[_veh,"APC"] spawn A3A_fnc_inmuneConvoy;
				_veh allowCrewInImmobile true;
				}
			else
				{
				(units _groupX) joinSilent _groupVeh;
				deleteGroup _groupX;
				_groupVeh spawn A3A_fnc_attackDrillAI;
				if (count units _groupVeh > 1) then {_groupVeh selectLeader (units _groupVeh select 1)};
				[_base,_landPos,_groupVeh] call A3A_fnc_WPCreate;
				_Vwp0 = (wayPoints _groupVeh) select 0;
				_Vwp0 setWaypointBehaviour "SAFE";
				/*
				_Vwp0 = (wayPoints _groupVeh) select ((count wayPoints _groupVeh) - 1);
				_Vwp0 setWaypointType "GETOUT";
				*/
				_Vwp0 = _groupVeh addWaypoint [_landPos, count (wayPoints _groupVeh)];
				_Vwp0 setWaypointType "GETOUT";
				//_Vwp0 setWaypointStatements ["true", "(group this) spawn A3A_fnc_attackDrillAI"];
				_Vwp1 = _groupVeh addWaypoint [_posDestination, count (wayPoints _groupVeh)];
				_Vwp1 setWaypointStatements ["true","{if (side _x != side this) then {this reveal [_x,4]}} forEach allUnits"];
				if (_isMarker) then
					{

					if ((count (garrison getVariable [_destination, []])) < 4) then
						{
						_Vwp1 setWaypointType "MOVE";
						_Vwp1 setWaypointBehaviour "AWARE";
						}
					else
						{
						_Vwp1 setWaypointType "SAD";
						_Vwp1 setWaypointBehaviour "COMBAT";
						};
					}
				else
					{
					_Vwp1 setWaypointType "SAD";
					_Vwp1 setWaypointBehaviour "COMBAT";
					};
				[_veh,"Inf Truck."] spawn A3A_fnc_inmuneConvoy;
				};
			}
		else
			{
			{_x disableAI "MINEDETECTION"} forEach (units _groupVeh);
			[_base,_posDestination,_groupVeh] call A3A_fnc_WPCreate;
			_Vwp0 = (wayPoints _groupVeh) select 0;
			_Vwp0 setWaypointBehaviour "SAFE";
			_Vwp0 = _groupVeh addWaypoint [_posDestination, count (waypoints _groupVeh)];
			[_veh,"Tank"] spawn A3A_fnc_inmuneConvoy;
			_Vwp0 setWaypointType "SAD";
			_Vwp0 setWaypointBehaviour "AWARE";
			_Vwp0 setWaypointStatements ["true","{if (side _x != side this) then {this reveal [_x,4]}} forEach allUnits"];
			_veh allowCrewInImmobile true;
			};
		_vehPool = _vehPool select {[_x] call A3A_fnc_vehAvailable};
		[3, format ["PatrolCA vehicle %1 sent with %2 soldiers", typeof _veh, count crew _veh], _filename] call A3A_fnc_log;
		};
	[2, format ["Land patrolCA performed on %1, type %2, veh count %3, troop count %4", _destination,_typeOfAttack,count _vehiclesX,count _soldiers], _filename] call A3A_fnc_log;
	}
else
	{
	[_side,20] call A3A_fnc_addTimeForIdle;
	_vehPool = [];
	_countX = if (!_super) then {if (_isMarker) then {2} else {1}} else {round ((tierWar + difficultyCoef) / 2) + 1};
	_typeVehX = "";
	_vehPool = if (_side == Occupants) then {
		(vehNATOAir - [vehNATOPlane,vehNATOPlaneAA]) select {[_x] call A3A_fnc_vehAvailable}
	} else {
		(vehCSATAir - [vehCSATPlane,vehCSATPlaneAA]) select {[_x] call A3A_fnc_vehAvailable}
	};
	if (_isSDK) then
		{
		_rnd = random 100;
		if (_side == Occupants) then
			{
			if (_rnd > aggressionOccupants) then
				{
				_vehPool = _vehPool - vehNATOAttackHelis;
				};
			}
		else
			{
			if (_rnd > aggressionInvaders) then
				{
				_vehPool = _vehPool - vehCSATAttackHelis;
				};
			};
		};
	if (_vehPool isEqualTo []) then {if (_side == Occupants) then {_vehPool = [vehNATOPatrolHeli]} else {_vehPool = [vehCSATPatrolHeli]}};
	for "_i" from 1 to _countX do
		{
		_typeVehX = if (_i == 1) then
				{
				if (_typeOfAttack == "Normal") then
					{
					if (_countX == 1) then
						{
						if (count (_vehPool - vehTransportAir) == 0) then {selectRandom _vehPool} else {selectRandom (_vehPool - vehTransportAir)};
						}
					else
						{
						//if (count (_vehPool - vehTransportAir) == 0) then {selectRandom _vehPool} else {selectRandom (_vehPool - vehTransportAir)};
						selectRandom (_vehPool select {_x in vehTransportAir});
						};
					}
				else
					{
					if (_typeOfAttack == "Air") then
						{
						if (_side == Occupants) then {if ([vehNATOPlaneAA] call A3A_fnc_vehAvailable) then {vehNATOPlaneAA} else {selectRandom _vehPool}} else {if ([vehCSATPlaneAA] call A3A_fnc_vehAvailable) then {vehCSATPlaneAA} else {selectRandom _vehPool}};
						}
					else
						{
						if (_side == Occupants) then {if ([vehNATOPlane] call A3A_fnc_vehAvailable) then {vehNATOPlane} else {selectRandom _vehPool}} else {if ([vehCSATPlane] call A3A_fnc_vehAvailable) then {vehCSATPlane} else {selectRandom _vehPool}};
						};
					};
				}
			else
				{
				if (_isMarker) then {selectRandom (_vehPool select {_x in vehTransportAir})} else {selectRandom _vehPool};
				};

		_pos = _posOrigin;
		_ang = 0;
		_size = [_side] call A3A_fnc_sizeMarker;
		_buildings = nearestObjects [_posOrigin, ["Land_LandMark_F","Land_runway_edgelight"], _size / 2];
		if (count _buildings > 1) then
			{
			_pos1 = getPos (_buildings select 0);
			_pos2 = getPos (_buildings select 1);
			_ang = [_pos1, _pos2] call BIS_fnc_DirTo;
			_pos = [_pos1, 5,_ang] call BIS_fnc_relPos;
			};
		if (count _pos == 0) then {_pos = _posOrigin};
		_vehicle=[_pos, _ang + 90,_typeVehX, _side] call bis_fnc_spawnvehicle;
		_veh = _vehicle select 0;
		if (hasIFA) then {_veh setVelocityModelSpace [((velocityModelSpace _veh) select 0) + 0,((velocityModelSpace _veh) select 1) + 150,((velocityModelSpace _veh) select 2) + 50]};
		_vehCrew = _vehicle select 1;
		_groupVeh = _vehicle select 2;
		_soldiers append _vehCrew;
		_groups pushBack _groupVeh;
		_vehiclesX pushBack _veh;
		{[_x] call A3A_fnc_NATOinit} forEach units _groupVeh;
		[_veh] call A3A_fnc_AIVEHinit;
		if (not (_typeVehX in vehTransportAir)) then
			{
			_Hwp0 = _groupVeh addWaypoint [_posDestination, 0];
			_Hwp0 setWaypointBehaviour "AWARE";
			_Hwp0 setWaypointType "SAD";
			//[_veh,"Air Attack"] spawn A3A_fnc_inmuneConvoy;
			}
		else
			{
			_typeGroup = if (_typeOfAttack == "Normal") then
				{
				[_typeVehX,_side] call A3A_fnc_cargoSeats;
				}
			else
				{
				if (_typeOfAttack == "Air") then
					{
					if (_side == Occupants) then {groupsNATOAA} else {groupsCSATAA}
					}
				else
					{
					if (_side == Occupants) then {groupsNATOAT} else {groupsCSATAT}
					};
				};
			_groupX = [_posOrigin,_side,_typeGroup] call A3A_fnc_spawnGroup;
			//{_x assignAsCargo _veh;_x moveInCargo _veh; [_x] call A3A_fnc_NATOinit;_soldiers pushBack _x;_x setVariable ["originX",_side]} forEach units _groupX;
			{
			_x assignAsCargo _veh;
			_x moveInCargo _veh;
			if (vehicle _x == _veh) then
				{
				_soldiers pushBack _x;
				[_x] call A3A_fnc_NATOinit;
				_x setVariable ["originX",_side];
				}
			else
				{
				deleteVehicle _x;
				};
			} forEach units _groupX;
			_groups pushBack _groupX;
			_landpos = [];
			_proceed = true;
			if (_isMarker) then
				{
				if ((_destination in airportsX)  or !(_veh isKindOf "Helicopter")) then
					{
					_proceed = false;
					[_veh,_groupX,_destination,_side] spawn A3A_fnc_airdrop;
					}
				else
					{
					if (_isSDK) then
						{
						if (((count(garrison getVariable [_destination,[]])) < 10) and (_typeVehX in vehFastRope)) then
							{
							_proceed = false;
							//_groupX setVariable ["mrkAttack",_destination];
							[_veh,_groupX,_posDestination,_posOrigin,_groupVeh] spawn A3A_fnc_fastrope;
							};
						};
					};
				}
			else
				{
				if !(_veh isKindOf "Helicopter") then
					{
					_proceed = false;
					[_veh,_groupX,_posDestination,_side] spawn A3A_fnc_airdrop;
					};
				};
			if (_proceed) then
				{
				_landPos = [_posDestination, 300, 550, 10, 0, 0.20, 0,[],[[0,0,0],[0,0,0]]] call BIS_fnc_findSafePos;
				if !(_landPos isEqualTo [0,0,0]) then
					{
					_landPos set [2, 0];
					_pad = createVehicle ["Land_HelipadEmpty_F", _landpos, [], 0, "NONE"];
					_vehiclesX pushBack _pad;
					_wp0 = _groupVeh addWaypoint [_landpos, 0];
					_wp0 setWaypointType "TR UNLOAD";
					_wp0 setWaypointStatements ["true", "(vehicle this) land 'GET OUT';[vehicle this] call A3A_fnc_smokeCoverAuto"];
					_wp0 setWaypointBehaviour "CARELESS";
					_wp3 = _groupX addWaypoint [_landpos, 0];
					_wp3 setWaypointType "GETOUT";
					_wp3 setWaypointStatements ["true", "(group this) spawn A3A_fnc_attackDrillAI"];
					_wp0 synchronizeWaypoint [_wp3];
					_wp4 = _groupX addWaypoint [_posDestination, 1];
					_wp4 setWaypointType "MOVE";
					_wp4 setWaypointStatements ["true","{if (side _x != side this) then {this reveal [_x,4]}} forEach allUnits"];
					_wp2 = _groupVeh addWaypoint [_posOrigin, 1];
					_wp2 setWaypointType "MOVE";
					_wp2 setWaypointStatements ["true", "deleteVehicle (vehicle this); {deleteVehicle _x} forEach thisList"];
					[_groupVeh,1] setWaypointBehaviour "AWARE";
					}
				else
					{
					if (_typeVehX in vehFastRope) then
						{
						[_veh,_groupX,_posDestination,_posOrigin,_groupVeh] spawn A3A_fnc_fastrope;
						}
					else
						{
						[_veh,_groupX,_destination,_side] spawn A3A_fnc_airdrop;
						};
					};
				};
			};
		sleep 30;
		_vehPool = _vehPool select {[_x] call A3A_fnc_vehAvailable};
		[3, format ["PatrolCA vehicle %1 sent with %2 soldiers", typeof _veh, count crew _veh], _filename] call A3A_fnc_log;
		};
	[2, format ["Air patrolCA performed on %1, type %2, veh count %3, troop count %4", _destination,_typeOfAttack,count _vehiclesX,count _soldiers], _filename] call A3A_fnc_log;
	};

if (_isMarker) then
	{
	_timeX = time + 3600;
	_size = [_destination] call A3A_fnc_sizeMarker;
	if (_side == Occupants) then
		{
		waitUntil {sleep 5; (({!([_x] call A3A_fnc_canFight)} count _soldiers) >= 3*({([_x] call A3A_fnc_canFight)} count _soldiers)) or (time > _timeX) or (sidesX getVariable [_destination,sideUnknown] == Occupants) or (({[_x,_destination] call A3A_fnc_canConquer} count _soldiers) > 3*({(side _x != _side) and (side _x != civilian) and ([_x,_destination] call A3A_fnc_canConquer)} count allUnits))};
		if  ((({[_x,_destination] call A3A_fnc_canConquer} count _soldiers) > 3*({(side _x != _side) and (side _x != civilian) and ([_x,_destination] call A3A_fnc_canConquer)} count allUnits)) and (not(sidesX getVariable [_destination,sideUnknown] == Occupants))) then
			{
			[Occupants,_destination] remoteExec ["A3A_fnc_markerChange",2];
			[3, format ["PatrolCA from %1 or %2 to retake %3 has outnumbered the enemy, changing marker!", _side,_base,_destination], _filename] call A3A_fnc_log;
			};
		sleep 10;
		if (!(sidesX getVariable [_destination,sideUnknown] == Occupants)) then
			{
			{_x doMove _posOrigin} forEach _soldiers;
			if (sidesX getVariable [_side,sideUnknown] == Occupants) then
				{
				_killZones = killZones getVariable [_side,[]];
				_killZones = _killZones + [_destination,_destination];
				killZones setVariable [_side,_killZones,true];
				};
			[3, format ["PatrolCA from %1 or %2 to retake %3 has failed as the marker is not changed!", _side,_base,_destination], _filename] call A3A_fnc_log;
			}
		}
	else
		{
		waitUntil {sleep 5; (({!([_x] call A3A_fnc_canFight)} count _soldiers) >= 3*({([_x] call A3A_fnc_canFight)} count _soldiers))or (time > _timeX) or (sidesX getVariable [_destination,sideUnknown] == Invaders) or (({[_x,_destination] call A3A_fnc_canConquer} count _soldiers) > 3*({(side _x != _side) and (side _x != civilian) and ([_x,_destination] call A3A_fnc_canConquer)} count allUnits))};
		if  ((({[_x,_destination] call A3A_fnc_canConquer} count _soldiers) > 3*({(side _x != _side) and (side _x != civilian) and ([_x,_destination] call A3A_fnc_canConquer)} count allUnits)) and (not(sidesX getVariable [_destination,sideUnknown] == Invaders))) then
			{
			[Invaders,_destination] remoteExec ["A3A_fnc_markerChange",2];
			[3, format ["PatrolCA from %1 or %2 to retake %3 has outnumbered the enemy, changing marker!", _side,_base,_destination], _filename] call A3A_fnc_log;
			};
		sleep 10;
		if (!(sidesX getVariable [_destination,sideUnknown] == Invaders)) then
			{
			{_x doMove _posOrigin} forEach _soldiers;
			if (sidesX getVariable [_side,sideUnknown] == Invaders) then
				{
				_killZones = killZones getVariable [_side,[]];
				_killZones = _killZones + [_destination,_destination];
				killZones setVariable [_side,_killZones,true];
				};
			[3, format ["PatrolCA from %1 or %2 to retake %3 has failed as the marker is not changed!", _side,_base,_destination], _filename] call A3A_fnc_log;
			}
		};
	}
else
	{
	_sideEnemy = if (_side == Occupants) then {Invaders} else {Occupants};
	if (_typeOfAttack != "Air") then {waitUntil {sleep 1; (!([distanceSPWN1,1,_posDestination,teamPlayer] call A3A_fnc_distanceUnits) and !([distanceSPWN1,1,_posDestination,_sideEnemy] call A3A_fnc_distanceUnits)) or (({!([_x] call A3A_fnc_canFight)} count _soldiers) >= 3*({([_x] call A3A_fnc_canFight)} count _soldiers))}} else {waitUntil {sleep 1; (({!([_x] call A3A_fnc_canFight)} count _soldiers) >= 3*({([_x] call A3A_fnc_canFight)} count _soldiers))}};
	if (({!([_x] call A3A_fnc_canFight)} count _soldiers) >= 3*({([_x] call A3A_fnc_canFight)} count _soldiers)) then
		{
		_markersX = resourcesX + factories + airportsX + outposts + seaports select {getMarkerPos _x distance _posDestination < distanceSPWN};
		_nearestMarker = if (_base != "") then {_base} else {_side};
		_killZones = killZones getVariable [_nearestMarker,[]];
		_killZones append _markersX;
		killZones setVariable [_nearestMarker,_killZones,true];
		[3, format ["PatrolCA from %1 or %2 on position %3 defeated", _side,_base,_destination], _filename] call A3A_fnc_log;
		}
	else {
		[3, format ["PatrolCA from %1 or %2 on position %3 despawned", _side,_base,_destination], _filename] call A3A_fnc_log;
		};
	};
[2, format ["PatrolCA on %1 finished",_destination], _filename] call A3A_fnc_log;

//if (_destination in forcedSpawn) then {forcedSpawn = forcedSpawn - [_destination]; publicVariable "forcedSpawn"};

{
_veh = _x;
if (!([distanceSPWN,1,_veh,teamPlayer] call A3A_fnc_distanceUnits) and (({_x distance _veh <= distanceSPWN} count (allPlayers - (entities "HeadlessClient_F"))) == 0)) then {deleteVehicle _x};
} forEach _vehiclesX;
{
_veh = _x;
if (!([distanceSPWN,1,_veh,teamPlayer] call A3A_fnc_distanceUnits) and (({_x distance _veh <= distanceSPWN} count (allPlayers - (entities "HeadlessClient_F"))) == 0)) then {deleteVehicle _x; _soldiers = _soldiers - [_x]};
} forEach _soldiers;

if (count _soldiers > 0) then
	{
	{
	[_x] spawn
		{
		private ["_veh"];
		_veh = _this select 0;
		waitUntil {sleep 1; !([distanceSPWN,1,_veh,teamPlayer] call A3A_fnc_distanceUnits) and (({_x distance _veh <= distanceSPWN} count (allPlayers - (entities "HeadlessClient_F"))) == 0)};
		deleteVehicle _veh;
		};
	} forEach _soldiers;
	};

{deleteGroup _x} forEach _groups;

sleep ((300 - ((tierWar + difficultyCoef) * 5)) max 0);
if (_isMarker) then {smallCAmrk = smallCAmrk - [_destination]; publicVariable "smallCAmrk"} else {smallCApos = smallCApos - [_posDestination]};
