params ["_side", "_supportPos", "_supportName"];

/*  Places the mortar used for fire support and initializes them

    Execution on: Server

    Scope: Internal

    Params:
        _side: SIDE : The side for which the support should be called in
        _supportPos: POSITION : The position the mortar should be able to target
        _supportName: STRING : The call name of the mortar support

    Returns:
        Nothing
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
        private _mortar = [_mortarType, _basePos, 5, 5, true] call A3A_fnc_safeVehicleSpawn;

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
    private _mortar = [_basePos, random 360, _mortarType, _side] call bis_fnc_spawnvehicle;

    _crew = _mortar select 1;
    _mortarGroup = _mortar select 2;
    {
        [_x] call A3A_fnc_NATOinit
    } forEach _crew;

    _mortar = _mortar select 0;
    [_mortar] call A3A_fnc_AIVEHinit;
};





//
