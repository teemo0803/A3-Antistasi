/*  Sends a QRF force towards the given position

    Execution on: Server

    Scope: External

    Params:
        _markerDestination: MARKER : The target position where the QRF will be send to
        _side: SIDE or MARKER : The start parameter of the QRF
        _super: BOOLEAN : Determine if the attack should be super strong
*/


//[position player,Occupants,"Normal",false] spawn A3A_Fnc_patrolCA
params ["_markerDestination", "_side", "_super"];
private _filename = "singleAttack";

[2, format ["Starting single attack with parameters %1", _this], _fileName] call A3A_fnc_log;

private _markerOrigin = "";
private _posOrigin = [];

private _posDestination = getMarkerPos _markerDestination;

//Parameter is the starting base
if(_side isEqualType "") then
{
    _markerOrigin = _side;
    _posOrigin = getMarkerPos _markerOrigin;
    _side = sidesX getVariable [_markerOrigin, sideUnknown];
    [2, format ["Adapting attack params, side is %1, start base is %2", _side, _markerOrigin], _fileName] call A3A_fnc_log;
};

if(_side == sideUnknown) exitWith
{
    [1, format ["Could not retrieve side for %1", _markerOrigin], _fileName] call A3A_fnc_log;
};

//Check if unit count isnt reached
//There might be an exploit here with spawning alot of rebel units to prevent attacks from happening
private _allAIUnits = {(alive _x) && {!(isPlayer _x)}} count allUnits;
private _allUnitsSide = 0;
private _maxUnitsSide = maxUnits;

if (gameMode <3) then
{
	_allUnitsSide = {(alive _x) && {(side group _x == _side) && {!(isPlayer _x)}}} count allUnits;
	_maxUnitsSide = round (maxUnits * 0.7);
};
if ((_allAIUnits + 4 > maxUnits) || (_allUnitsSide + 4 > _maxUnitsSide)) exitWith
{
    [2, format ["Small attack to %1 cancelled because maximum unit count reached",_markerDestination], _filename] call A3A_fnc_log;
};

//If too foggy for anything abort here
if ([_posDestination,false] call A3A_fnc_fogCheck < 0.3) exitWith
{
    [2, format ["Small attack to %1 cancelled due to heavy fog", _markerDestination], _filename] call A3A_fnc_log;
};

//Search for nearby enemies
private _enemyGroups = allGroups select
{
    (side _x != _side) &&
    {side _x != civilian &&
    {(getPos (leader _x) distance2D _posDestination) < distanceSPWN2}}
};
private _nearEnemies = [];
{
    _nearEnemies append ((units _x) select {alive _x});
} forEach _enemyGroups;

//Select the type of attack (or more precise against what the attack will fight)
private _typeOfAttack = "Normal";
{
	if !(isNull (objectParent _x)) then
	{
		private _enemyVehicle = objectParent _x;
		if (_enemyVehicle isKindOf "Plane") exitWith
        {
            _typeOfAttack = "Air"
        };
		if (_enemyVehicle isKindOf "Helicopter") then
		{
			_weapons = getArray (configfile >> "CfgVehicles" >> (typeOf _enemyVehicle) >> "weapons");
			if (_weapons isEqualType []) then
			{
				if (count _weapons > 1) then
                {
                    _typeOfAttack = "Air"
                };
			};
		}
		else
		{
			if (_enemyVehicle isKindOf "Tank") then
            {
                _typeOfAttack = "Tank"
            };
		};
	};
	if (_typeOfAttack != "Normal") exitWith {};
} forEach _nearEnemies;

private _threatEvalLand = [_posDestination,_side] call A3A_fnc_landThreatEval;;

//No start based selected by now
if(_markerOrigin == "") then
{
    //Start selecting the starting base
    private _availableAirports = airportsX select
    {
        (sidesX getVariable [_x,sideUnknown] == _side) &&
        {([_x,true] call A3A_fnc_airportCanAttack) &&
        {(getMarkerPos _x) distance2D _posDestination < distanceForAirAttack}}
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
};

if (_markerOrigin == "") exitWith
{
    [2, format ["Small attack to %1 cancelled because no usable bases in vicinity",_markerDestination], _filename] call A3A_fnc_log
};

//Base selected, select units now
private _vehicles = [];
private _groups = [];
private _landPosBlacklist = [];
private _vehicleCount = if(_side == Occupants) then
{
    2
    + (aggressionOccupants/16)
    + ([0, 2] select _super)
    + ([-0.5, 0, 0.5] select (skillMult - 1))
}
else
{
    2
    + (aggressionInvaders/16)
    + ([0, 3] select _super)
    + ([0, 0.5, 1.5] select (skillMult - 1))
};
_vehicleCount = (round (_vehicleCount)) max 1;

[
    3,
    format ["Due to %1 aggression, sending %2 vehicles", (if(_side == Occupants) then {aggressionOccupants} else {aggressionInvaders}), _vehicleCount],
    _fileName
] call A3A_fnc_log;

//The attack will be carried out by land and air vehicles
if ((_posOrigin distance2D _posDestination < distanceForLandAttack) && {[_posOrigin, _posDestination] call A3A_fnc_isTheSameIsland}) then
{
    private _index = -1;
	if (_markerOrigin in outposts) then
    {
        [_markerOrigin, 40] call A3A_fnc_addTimeForIdle;
    }
    else
    {
        [_markerOrigin, 20] call A3A_fnc_addTimeForIdle;
        _index = airportsX find _markerOrigin;
    };
	private _spawnPoint = objNull;
	private _pos = [];
	private _dir = 0;
	if (_index > -1) then
	{
		_spawnPoint = server getVariable (format ["spawn_%1", _base]);
		_pos = getMarkerPos _spawnPoint;
		_dir = markerDir _spawnPoint;
	}
	else
	{
		_spawnPoint = [_posOrigin] call A3A_fnc_findNearestGoodRoad;
		_pos = position _spawnPoint;
        //Always returns 0 but fine
		_dir = getDir _spawnPoint;
	};

	private _vehPool = [_side] call A3A_fnc_getVehiclePoolForAttacks;
	private _road = [_posDestination] call A3A_fnc_findNearestGoodRoad;

	for "_i" from 1 to _vehicleCount do
	{
        private _vehicleType = "";
        if(_vehPool isEqualTo []) then
        {
            if(_side == Occupants) then
            {
                _vehicleType = selectRandom (vehNATOTransportHelis + vehNATOTrucks);
            }
            else
            {
                _vehicleType = selectRandom (vehCSATTransportHelis + vehCSATTrucks);
            };
        }
        else
        {
            _vehicleType = selectRandomWeighted _vehPool;
        };
        private _vehicle = [_vehicleType, _pos, 100, 5, true] call A3A_fnc_safeVehicleSpawn;
        private _crewGroup = createVehicleCrew _vehicle;

        if(_vehicle isKindOf "Air") then
        {
            _vehicle setPos ((getPos _vehicle) vectorAdd [0, 0, 100]);
        };

		{
            [_x] call A3A_fnc_NATOinit
        } forEach (units _crewGroup);
		[_vehicle] call A3A_fnc_AIVEHinit;

		_groups pushBack _crewGroup;
		_vehicles pushBack _vehicle;

        private _cargoGroup = grpNull;
		if ((([_vehicleType, true] call BIS_fnc_crewCount) - ([_vehicleType, false] call BIS_fnc_crewCount)) > 0) then
		{
            //Vehicle is able to transport units
			private _groupType = if (_typeOfAttack == "Normal") then
			{
				[_vehicleType,_side] call A3A_fnc_cargoSeats;
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
			_cargoGroup = [_posOrigin,_side,_groupType] call A3A_fnc_spawnGroup;
			{
                _x assignAsCargo _vehicle;
                _x moveInCargo _vehicle;
                if !(isNull objectParent _x) then
                {
                    [_x] call A3A_fnc_NATOinit;
                    _x setVariable ["originX",_markerOrigin];
                }
                else
                {
                    deleteVehicle _x;
                };
            } forEach units _cargoGroup;
            _groups pushBack _cargoGroup;
		};
        _landPosBlacklist = [_vehicle, _crewGroup, _cargoGroup, _posDestination, _markerOrigin, _landPosBlacklist] call A3A_fnc_createVehicleQRFBehaviour;
		[3, format ["Small attack vehicle %1 sent with %2 soldiers", typeof _vehicle, count crew _vehicle], _filename] call A3A_fnc_log;
	};
	[2, format ["Small %1 attack sent with %2 vehicles", _typeOfAttack, count _vehicles], _filename] call A3A_fnc_log;
}
else
{
    //The attack will be carried out by air vehicles only
	[_markerOrigin, 20] call A3A_fnc_addTimeForIdle;
	private _vehPool = [_side, ["LandVehicle"]] call A3A_fnc_getVehiclePoolForAttacks;
	for "_i" from 1 to _vehicleCount do
	{
        private _vehicleType = "";
        if(_vehPool isEqualTo []) then
        {
            if(_side == Occupants) then
            {
                _vehicleType = selectRandom vehNATOTransportHelis;
            }
            else
            {
                _vehicleType = selectRandom vehCSATTransportHelis;
            };
        }
        else
        {
            _vehicleType = selectRandomWeighted _vehPool;
        };
		private _pos = _posOrigin;
		private _ang = 0;

        //Search for runway
		private _size = [_markerOrigin] call A3A_fnc_sizeMarker;
		private _buildings = nearestObjects [_posOrigin, ["Land_LandMark_F","Land_runway_edgelight"], _size / 2];
		if (count _buildings > 1) then
		{
			private _pos1 = getPos (_buildings select 0);
			private _pos2 = getPos (_buildings select 1);
			_ang = [_pos1, _pos2] call BIS_fnc_DirTo;
			_pos = [_pos1, 5,_ang] call BIS_fnc_relPos;
		};
		if (count _pos == 0) then {_pos = _posOrigin};
        //Runway found or not found, position selected

		private _vehicleParams = [_pos, _ang + 90,_vehicleType, _side] call bis_fnc_spawnvehicle;
		private _vehicle = _vehicleParams select 0;
		private _crewGroup = _vehicleParams select 2;

		_groups pushBack _crewGroup;
		_vehicles pushBack _vehicle;

		{
            [_x] call A3A_fnc_NATOinit
        } forEach (units _crewGroup);
		[_vehicle] call A3A_fnc_AIVEHinit;

        if (hasIFA) then
        {
            _vehicle setVelocityModelSpace [((velocityModelSpace _vehicle) select 0) + 0,((velocityModelSpace _vehicle) select 1) + 150,((velocityModelSpace _vehicle) select 2) + 50]
        };

        private _cargoGroup = grpNull;
		if ((([_vehicleType, true] call BIS_fnc_crewCount) - ([_vehicleType, false] call BIS_fnc_crewCount)) > 0) then
		{
			private _groupType = if (_typeOfAttack == "Normal") then
			{
				[_vehicleType, _side] call A3A_fnc_cargoSeats;
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
			_cargoGroup = [_posOrigin,_side,_groupType] call A3A_fnc_spawnGroup;
			{
                _x assignAsCargo _vehicle;
                _x moveInCargo _vehicle;
                if !(isNull (objectParent _x)) then
                {
                    [_x] call A3A_fnc_NATOinit;
                    _x setVariable ["originX",_markerOrigin];
				}
                else
                {
                    deleteVehicle _x;
				};
			} forEach (units _cargoGroup);
			_groups pushBack _cargoGroup;
		};

        _landPosBlacklist = [_vehicle, _crewGroup, _cargoGroup, _posDestination, _markerOrigin, _landPosBlacklist] call A3A_fnc_createVehicleQRFBehaviour;
		[3, format ["Small attack vehicle %1 sent with %2 soldiers", typeof _vehicle, count crew _vehicle], _filename] call A3A_fnc_log;
        sleep 10;
	};
	[2, format ["Small %1 attack sent with %2 vehicles", _typeOfAttack, count _vehicles], _filename] call A3A_fnc_log;
};

//Prepare despawn conditions
private _endTime = time + 2700;
private _qrfHasArrived = false;
private _qrfHasWon = false;

while {true} do
{
    private _markerSide = sidesX getVariable [_markerDestination, sideUnknown];

    if(_markerSide == _side) exitWith
    {
        [2, format ["Small attack to %1 captured the marker, starting despawn routines", _markerDestination], _fileName] call A3A_fnc_log;
    };

    //Trying to flip marker
    [_markerDestination, _markerSide] remoteExec ["A3A_fnc_zoneCheck", 2];

    private _groupAlive = false;
    {
        private _index = (units _x) findIf {[_x] call A3A_fnc_canFight};
        if(_index != -1) exitWith
        {
            _groupAlive = true;
        };
    } forEach _groups;

    if !(_groupAlive) exitWith
    {
        [2, format ["Small attack to %1 has been eliminated, starting despawn routines", _markerDestination], _fileName] call A3A_fnc_log;
    };

    sleep 60;
    if(_endTime < time) exitWith
    {
        [2, format ["Small attack to %1 timed out without winning or losing, starting despawn routines", _markerDestination], _fileName] call A3A_fnc_log;
    };
};

{
    [_x] spawn A3A_fnc_VEHDespawner;
} forEach _vehicle;

{
    [_x] spawn A3A_fnc_groupDespawner;
} forEach _groups;
