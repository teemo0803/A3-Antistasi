params ["_side"];

//if(tierWar < 2) exitWith {-1};

//Select a timer index and the max number of timers available
private _timerIndex = -1;
private _playerAdjustment = ceil (sqrt (count allPlayers));

//Search for a timer which allows the support to be fired
if(_side == Occupants) then
{
    if(isNil "occupantsMortarTimer") then
    {
        occupantsMortarTimer = [];
    };
    if(count occupantsMortarTimer < _playerAdjustment) then
    {
        _timerIndex = count occupantsMortarTimer;
        for "_i" from ((count occupantsMortarTimer) + 1) to _playerAdjustment do
        {
            occupantsMortarTimer pushBack -1;
        };
    }
    else
    {
        _timerIndex = occupantsMortarTimer findIf {_x < time};
        if(_playerAdjustment <= _timerIndex) then
        {
            _timerIndex = -1;
        };
    };
};
if(_side == Invaders) then
{
    if(isNil "invadersMortarTimer") then
    {
        invadersMortarTimer = [];
    };
    if(count invadersMortarTimer < _playerAdjustment) then
    {
        _timerIndex = count invadersMortarTimer;
        for "_i" from ((count invadersMortarTimer) + 1) to _playerAdjustment do
        {
            invadersMortarTimer pushBack -1;
        };
    }
    else
    {
        _timerIndex = invadersMortarTimer findIf {_x < time};
        if(_playerAdjustment <= _timerIndex) then
        {
            _timerIndex = -1;
        };
    };
};

//No timer available
_timerIndex;
