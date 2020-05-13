
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
