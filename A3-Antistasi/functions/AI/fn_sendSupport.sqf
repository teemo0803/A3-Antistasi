params ["_target", "_precision", "_supportTypes", "_side"];

/*  Selects the support based on the needs and the availability (Is this even a word?)

    Execution on: Server

    Scope: Internal

    Parameters:
        _target: OBJECT : The target object to attack
        _precision: NUMBER : The precision on the target data in range 0 to 4
        _supportTypes: ARRAY of STRINGs : The requested support types
        _side: SIDE : The side of the support callers
*/
private _fileName = "sendSupport";

//Calculate deprecision on position
private _deprecisionRange = random (300 - ((_precision/4) * (_precision/4) * 275));
private _randomDir = random 360;
private _supportPos = _target getPos [_deprecisionRange, _randomDir];

//Search for any support already active in the area matching the _supportTypes
private _supportObject = "";
private _supportType = "";
if(_side == Occupants) then
{
    {
        _supportType = _x;
        private _index = -1;
        if(_supportType != "AIRSTRIKE") then
        {
            _index = occupantsSupports findIf {((_x select 0) == _supportType) && {_supportPos inArea (_x select 1)}};
        };
        if(_index != -1) exitWith
        {
            _supportObject = occupantsSupports select _index select 2;
        };
    } forEach _supportTypes;
};
if(_side == Invaders) then
{
    {
        _supportType = _x;
        private _index = -1;
        if(_supportType != "AIRSTRIKE") then
        {
            _index = invadersSupports findIf {((_x select 0) == _supportType) && {_supportPos inArea (_x select 1)}};
        };
        if(_index != -1) exitWith
        {
            _supportObject = invadersSupports select _index select 2;
        };
    } forEach _supportTypes;
};

//Support is already in the area, send instructions to them
if (_supportObject != "") exitWith
{
    if(_supportType != "QRF") then
    {
        //Attack with already existing support
        if(_supportType in ["MORTAR"]) then
        {
            //Areal support methods, transmit position info
            [_supportObject, [_supportPos, _precision]] call A3A_fnc_addSupportTarget;
        };
        if(_supportType in ["CAS", "AAPLANE", "SAM", "GUNSHIP"]) then
        {
            //Target support methods, transmit target info
            [_supportObject, [_target, _precision]] call A3A_fnc_addSupportTarget;
        };
    }
    else
    {
        [
            2,
            format ["QRf to %1 cancelled as another QRF is already in the area", _supportPos],
            _fileName
        ] call A3A_fnc_log;
    };
};
