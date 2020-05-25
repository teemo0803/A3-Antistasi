
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

if ((!_isMarker) and (_typeOfAttack != "Air") and (!_super) and ({sidesX getVariable [_x,sideUnknown] == _side} count airportsX > 0)) then
	{
	_plane = if (_side == Occupants) then {vehNATOPlane} else {vehCSATPlane};
	if ([_plane] call A3A_fnc_vehAvailable) then
		{
		_friendlies = if (_side == Occupants) then {allUnits select {(_x distance _posDestination < 200) and (alive _x) and ((side (group _x) == _side) or (side (group _x) == civilian))}} else {allUnits select {(_x distance _posDestination < 100) and ([_x] call A3A_fnc_canFight) and (side (group _x) == _side)}};
		if (count _friendlies == 0) then
			{
			_typeX = if (napalmEnabled) then {"NAPALM"} else {"HE"};
			{
			if (vehicle _x isKindOf "Tank") then
				{
				_typeX = "HE"
				}
			else
				{
				if (vehicle _x != _x) then
					{
					if !(vehicle _x isKindOf "StaticWeapon") then {_typeX = "CLUSTER"};
					};
				};
			if (_typeX == "HE") exitWith {};
			} forEach _nearEnemies;
			_exit = true;
			if (!_isMarker) then {smallCApos pushBack _posDestination};
			[_posDestination,_side,_typeX] spawn A3A_fnc_airstrike;
			[2, format ["PatrolCA airstrike of type %1 sent to %2",_typeX,_destination], _filename] call A3A_fnc_log;
			if (!_isMarker) then
				{
				sleep 120;
				smallCApos = smallCApos - [_posDestination];
				};
			};
		};
	};
if (_exit) exitWith {};



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
