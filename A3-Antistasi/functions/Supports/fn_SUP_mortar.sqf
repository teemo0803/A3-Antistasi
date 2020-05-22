params ["_side", "_timerIndex", "_supportPos", "_supportName"];

/*  Places the mortar used for fire support and initializes them

    Execution on: Server

    Scope: Internal

    Params:
        _side: SIDE : The side for which the support should be called in
        _timerIndex: NUMBER
        _supportPos: POSITION : The position the mortar should be able to target
        _supportName: STRING : The call name of the mortar support

    Returns:
        The name of the marker, covering the whole support area
*/

private _fileName = "SUP_mortar";
private _mortarType = "";
private _shellType = "";
private _isMortar = false;

if (tierWar < 6) then
{
    _mortarType = if(_side == Occupants) then {NATOMortar} else {CSATMortar};
    _shellType = SDKMortarHEMag;
    _isMortar = true;
}
else
{
    if(tierWar > 8) then
    {
        _mortarType = if(_side == Occupants) then {vehNATOMRLS} else {vehCSATMRLS};
        _shellType = if(_side == Occupants) then {vehNATOMRLSMags} else {vehCSATMRLSMags};
    }
    else
    {
        private _mortarChange = 70 - (20 * (6 - tierWar));
        _isMortar = selectRandomWeighted [true, _mortarChange, false, (1 - _mortarChange)];
        if(_isMortar) then
        {
            _mortarType = if(_side == Occupants) then {NATOMortar} else {CSATMortar};
            _shellType = SDKMortarHEMag;
        }
        else
        {
            _mortarType = if(_side == Occupants) then {vehNATOMRLS} else {vehCSATMRLS};
            _shellType = if(_side == Occupants) then {vehNATOMRLSMags} else {vehCSATMRLSMags};
        };
    };
};

[
    2,
    format ["Mortar support to %1 will be carried out by a %2 with %3 mags", _supportPos, _mortarType, _shellType],
    _fileName
] call A3A_fnc_log;

private _mortar = objNull;
private _crew = [];
private _mortarGroup = grpNull;
private _crewType = if (_side == Occupants) then {staticCrewOccupants} else {staticCrewInvaders};

//Spawning in the units
if(_isMortar) then
{
    //Search for a outpost, that isnt more than 2 kilometers away, which isnt spawned
    private _possibleBases = (outposts + airportsX) select
    {
        (sidesX getVariable [_x, sideUnknown] == _side) &&
        {((getMarkerPos _x) distance2D _supportPos <= 2000) &&
        {spawner getVariable [_x, -1] == 2}}
    };

    if(count _possibleBases == 0) exitWith {};

    //Search for an outpost with a designated mortar position if possible
    private _spawnParams = -1;
    private _index = _possibleBases findIf
    {
        _spawnParams = [_x, "Mortar"] call A3A_fnc_findSpawnPosition;
        _spawnParams != -1
    };

    _mortarGroup = createGroup _side;
    if(_index != -1) then
    {
        //Spawn in mortar
        _mortar = _mortarType createVehicle (_spawnParams select 0);
    	_mortar setDir (_spawnParams select 1);
        [_possibleBases select _index] spawn A3A_fnc_freeSpawnPositions;

        //Spawn in crew
    	private _unit = [_mortarGroup, _crewType, (_spawnParams select 0), [], 5, "NONE"] call A3A_fnc_createUnit;
    	[_unit] call A3A_fnc_NATOinit;

        //Moving crew in
    	_unit moveInGunner _mortar;
    	_crew pushBack _unit;

        //Init mortar (needed?)
        [_mortar] call A3A_fnc_AIVEHinit;
    }
    else
    {
        private _base = selectRandom _possibleBases;
        private _basePos = getMarkerPos _base;

        //Spawn in mortar
        _mortar = [_mortarType, _basePos, 5, 5, true] call A3A_fnc_safeVehicleSpawn;

        //Spawn in crew
        private _unit = [_mortarGroup, _crewType, _basePos, [], 5, "NONE"] call A3A_fnc_createUnit;
    	[_unit] call A3A_fnc_NATOinit;

        //Moving crew in
        _unit moveInGunner _mortar;
    	_crew pushBack _unit;

        //Init mortar (needed?)
        [_mortar] call A3A_fnc_AIVEHinit;
    };
}
else
{
    private _possibleBases = airportsX select
    {
        (sidesX getVariable [_x, sideUnknown] == _side) &&
        {((getMarkerPos _x) distance2D _supportPos <= 8000) &&
        {((getMarkerPos _X) distance2D _supportPos > 2000) &&
        {spawner getVariable [_x, -1] == 2}}}
    };

    if(count _possibleBases == 0) exitWith {};

    private _base = selectRandom _possibleBases;
    private _basePos = getMarkerPos _base;

    //Spawn in mortar
    _mortar = [_basePos, random 360, _mortarType, _side] call bis_fnc_spawnvehicle;

    _crew = _mortar select 1;
    _mortarGroup = _mortar select 2;
    {
        [_x] call A3A_fnc_NATOinit
    } forEach _crew;

    _mortar = _mortar select 0;
    [_mortar] call A3A_fnc_AIVEHinit;
};

if(isNull _mortar) exitWith
{
    [
        2,
        format ["Couldn't spawn in mortar %1, no suitable position found!", _supportName],
        _fileName
    ] call A3A_fnc_log;
    "";
};

_mortar setVariable ["shellType", _shellType, true];

//Creates the marker which coveres the area in which the support can help
private _coverageMarker = createMarker [format ["%1_coverage", _supportName], getPos _mortar];
_coverageMarker setMarkerShape "ELLIPSE";
_coverageMarker setMarkerBrush "Grid";
if(_side == Occupants) then
{
    _coverageMarker setMarkerColor colorOccupants;
    if(_isMortar) then
    {
        _coverageMarker setMarkerSize [2000, 2000];
        occupantsMortarTimer set [_timerIndex, time + 1800];
    }
    else
    {
        _coverageMarker setMarkerSize [8000, 8000];
        occupantsMortarTimer set [_timerIndex, time + 3600];
    };
}
else
{
    _coverageMarker setMarkerColor colorInvaders;
    if(_isMortar) then
    {
        _coverageMarker setMarkerSize [2000, 2000];
        invadersMortarTimer set [_timerIndex, time + 1800];
    }
    else
    {
        _coverageMarker setMarkerSize [8000, 8000];
        invadersMortarTimer set [_timerIndex, time + 3600];
    };
};

_coverageMarker setMarkerAlpha 0;

private _timerArray = if(_side == Occupants) then {occupantsMortarTimer} else {invadersMortarTimer};

_mortar setVariable ["TimerArray", _timerArray, true];
_mortar setVariable ["TimerIndex", _timerIndex, true];

//Setting up the EH for support destruction
_mortar addEventHandler
[
    "Killed",
    {
        params ["_mortar"];
        ["TaskSucceeded", ["", "Mortar Support Destroyed"]] remoteExec ["BIS_fnc_showNotification", teamPlayer];
        private _timerArray = _mortar getVariable "TimerArray";
        private _timerIndex = _mortar getVariable "TimerIndex";
        _timerArray set [_timerIndex, (_timerArray select _timerIndex) + 3600];
    }
];

_mortar addEventHandler
[
    "GetIn",
    {
        params ["_vehicle", "_role", "_unit", "_turret"];
        if(side (group _unit) == teamPlayer) then
        {
            ["TaskSucceeded", ["", "Mortar Support Stolen"]] remoteExec ["BIS_fnc_showNotification", teamPlayer];
            _vehicle setVariable ["Stolen", true, true];
            _vehicle removeAllEventHandlers "GetIn";
            private _timerArray = _vehicle getVariable "TimerArray";
            private _timerIndex = _vehicle getVariable "TimerIndex";
            _timerArray set [_timerIndex, (_timerArray select _timerIndex) + 3600];
        };
    }
];

_mortarGroup setVariable ["Mortar", _mortar, true];
{
    _x addEventHandler
    [
        "Killed",
        {
            params ["_unit"];
            private _group = group _unit;
            if({alive _x} count (units _group) == 0) then
            {
                ["TaskSucceeded", ["", "Mortar Support crew killed"]] remoteExec ["BIS_fnc_showNotification", teamPlayer];
                private _mortar = _group getVariable "Mortar";
                private _timerArray = _mortar getVariable "TimerArray";
                private _timerIndex = _mortar getVariable "TimerIndex";
                _timerArray set [_timerIndex, (_timerArray select _timerIndex) + 1800];
            };
        }
    ];
} forEach _crew;

_mortarGroup deleteGroupWhenEmpty true;
[_mortar, _mortarGroup, _supportName, _side] spawn A3A_fnc_SUP_mortarRoutine;

_coverageMarker;
