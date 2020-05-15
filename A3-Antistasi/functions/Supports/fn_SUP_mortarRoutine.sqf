params ["_mortar", "_crewGroup", "_supportName", "_side"];

/*  The routine which controls the mortar support in all aspects

    Execution on: Server

    Scope: Internal

    Params:
        _mortar: OBJECT : The actual mortar object
        _crewGroup: GROUP : The crewgroup of the mortar
        _supportName: STRING : The callsign of the support
        _side: SIDE : The side of the support

    Returns:
        Nothing
*/

private _fileName = "SUP_mortarRoutine";

//Sleep to simulate the time it would need to set the support up
sleep (random (300 - (27 * tierWar)));

//Decrease number of rounds and time alive if aggro is low
private _sideAggression = if(_side == Occupants) then {aggressionOccupants} else {aggressionInvaders};
private _numberOfRounds = 32;
private _timeAlive = 1800;

if(_sideAggression < 70) then
{
    if(_sideAggression < 30) then
    {
        _numberOfRounds = 16;
        _timeAlive = 900;
    }
    else
    {
        if((30 + (random 40)) < _sideAggression) then
        {
            _numberOfRounds = 16;
            _timeAlive = 900;
        };
    };
};
private _shotsPerVoley = _numberOfRounds / 4;

_fn_executeMortarFire =
{
    params ["_mortar"];

    private _targets = _mortar getVariable ["FireOrder", []];
    private _target = _targets deleteAt 0;
    _mortar setVariable ["FireOrder", _targets, true];

    _mortar addEventHandler
    [
        "Fired",
        {
            params ["_mortar"];

            private _targets = _mortar getVariable ["FireOrder", []];

            if(count _targets == 0) exitWith
            {
                _mortar removeAllEventHandlers "Fired";
                _mortar setVariable ["CurrentlyFiring", false, true];
                _mortar setVariable ["FireOrder", nil, true];
            };

            private _target = _targets deleteAt 0;
            _mortar setVariable ["FireOrder", _targets, true];

            _target spawn
            {
                _mortar doArtilleryFire [_this, _mortar getVariable "shellType", 1];
            }
        }
    ];
    _mortar doArtilleryFire [_target, _mortar getVariable "shellType", 1];
};

_mortar setVariable ["CurrentlyFiring", false, true];
while {_timeAlive > 0} do
{
    if !(_mortar getVariable "CurrentlyFiring") then
    {
        //Mortar is currently not attacking a target, search for new order
        private _targetList = server getVariable [format ["%1_targets", _supportName], []];
        if (count _targetList > 0) then
        {
            //New target active, read in
            private _target = _targetList deleteAt 0;
            server setVariable [format ["%1_targets", _supportName], _targetList, true];

            //Parse targets
            private _targetParams = _target select 0;
            private _reveal = _target select 1;

            private _subTargets = [];
            private _targetPos = _targetParams select 0;
            private _precision = _targetParams select 1;
            private _distance = random (125 - ((_precision/4) * (_precision/4) * 100));

            for "_i" from 1 to _shotsPerVoley do
            {
                _subTargets pushBack (_targetPos getPos [random _distance, random 360]);
            };

            //Show target to players if change is high enough
            //TODO create target marker
            [_reveal] spawn A3A_fnc_showInterceptedSupportCall;

            _mortar setVariable ["CurrentlyFiring", true, true];
            _mortar setVariable ["FireOrder", true, true];

            [_mortar] spawn _fn_executeMortarFire;
            _numberOfRounds = _numberOfRounds - _shotsPerVoley;
        };
    };

    //Mortar somehow destroyed
    if
    (
        !(alive _mortar) ||
        {((alive _x) count (units _crewGroup)) == 0 ||
        {_mortar getVariable ["Stolen", false]}}
    ) exitWith
    {
        [
            2,
            format ["%1 has been destroyed or crew killed, aborting routine", _supportName],
            _fileName
        ] call A3A_fnc_log;
    };

    if !(_mortar getVariable "CurrentlyFiring" && _numberOfRounds <= 0) exitWith
    {
        [
            2,
            format ["%1 has no more rounds left to fire, aborting routine", _supportName],
            _fileName
        ] call A3A_fnc_log;
    };

    sleep 5;
    _timeAlive = _timeAlive - 5;
};

//Mortar already destroyed
_mortar removeAllEventHandlers "Fired";
if((alive _x) count (units _crewGroup) != 0) then
{
    //Crew left, activating despawner
    [_crewGroup] spawn A3A_fnc_groupDespawner;
};

if(alive _mortar && {!(_mortar getVariable ["Stolen", false])}) then
{
    //Mortar left, activating despawner
    [_mortar] spawn A3A_fnc_VEHdespawner;
};

//Deleting all the support data here
[_supportName, _side] call A3A_fnc_endSupport;
