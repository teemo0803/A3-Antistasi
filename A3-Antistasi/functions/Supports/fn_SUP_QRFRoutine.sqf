params ["_side", "_vehicles", "_groups", "_posDestination", "_supportName"];

//Prepare despawn conditions
private _endTime = time + 2700;
private _qrfHasArrived = false;
private _qrfHasWon = false;

private _targetList = server getVariable [format ["%1_targets", _supportName], []];
private _reveal = _targetList select 0 select 1;

while {true} do
{
    if !(_qrfHasArrived) then
    {
        //Not yet arrived
        private _index = _vehicles findIf {getPos _x distance2D _posDestination < 300};
        if(_index != -1) then
        {
            [2, format ["%1 has arrived with at least one vehicle, attacking now", _supportName], _fileName] call A3A_fnc_log;
            _qrfHasArrived = true;

            private _textMarker = createMarker [format ["%1_text", _supportName], _targetPos];
            _textMarker setMarkerShape "ICON";
            _textMarker setMarkerType "mil_dot";
            _textMarker setMarkerText "QRF";
            if(_side == Occupants) then
            {
                _textMarker setMarkerColor colorOccupants;
            }
            else
            {
                _textMarker setMarkerColor colorInvaders;
            };
            [_reveal, _posDestination, _side, "QRF", format ["%1_coverage", _supportName], _textMarker] spawn A3A_fnc_showInterceptedSupportCall;
        };
    }
    else
    {
        //QRF in combat, check if won
        private _nearbyEnemyGroups = allGroups select {getPos (leader _x) distance2D _posDestination < 300};
        if(count _nearbyEnemyGroups == 0) then
        {
            [2, format ["%1 has cleared the area, starting despawn routines", _supportName], _fileName] call A3A_fnc_log;
            _qrfHasWon = true;
        };
    };
    if(_qrfHasWon) exitWith {};

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
        [2, format ["%1 has been eliminated, starting despawn routines", _supportName], _fileName] call A3A_fnc_log;
    };

    sleep 15;
    if(_endTime < time) exitWith
    {
        [2, format ["%1 timed out without winning or losing, starting despawn routines", _supportName], _fileName] call A3A_fnc_log;
    };
};

{
    [_x] spawn A3A_fnc_VEHDespawner;
} forEach _vehicle;

{
    [_x] spawn A3A_fnc_groupDespawner;
} forEach _groups;

[_supportName] call A3A_fnc_endSupport;
