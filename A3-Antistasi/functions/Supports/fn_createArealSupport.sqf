params ["_side", "_supportType", "_supportPos", "_precision"];

/*  Creates an support type that attacks areas

    Execution on: Server

    Scope: Internal

    Parameters:
        _side: SIDE: The side of the support unit
        _supportType: STRING : The type of support to send
        _supportPos: POSITION : The position which will be attack
        _precision: NUMBER : How precise the target info is
*/

//Selecting the first available name of support type
private _supportIndex = 0;
private _supportName = format ["%1%2_targets", _supportType, _supportIndex];
while {(server getVariable [_supportName, -1]) isEqualType []} do
{
    _supportIndex = _supportIndex + 1;
    _supportName = format ["%1%2_targets", _supportType, _supportIndex];
};

//Setting the support initial target
server setVariable [format ["%1_targets", _supportName], [_supportPos, _precision], true];
if (_side == Occupants) then
{
    occupantsSupports pushBack [_supportType, _supportPos, _supportName];
};
if(_side == Invaders) then
{
    invadersSupports pushBack [_supportType, _supportPos, _supportName];
};

switch (_supportType) do
{
    case ("QRF"):
    {

    };
    case ("AIRSTRIKE"):
    {

    };
    case ("MORTAR"):
    {

    };
    default
    {
        server setVariable [format ["%1_targets", _supportName], nil, true];
        if (_side == Occupants) then
        {
            private _index = occupantsSupports findIf {(_x select 2) == _supportName};
            occupantsSupports deleteAt _index;
        };
        if (_side == Invaders) then
        {
            private _index = invadersSupports findIf {(_x select 2) == _supportName};
            invadersSupports deleteAt _index;
        };
    };
};
