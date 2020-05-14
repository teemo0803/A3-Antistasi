params ["_timeArray"];

/*  Checks if the given time array lays in the past or future to determine if a unit is available

    Scope: Internal

    Params:
        _timeArray : ARRAY or NUMBER : The time array [year, number] or -1

    Returns:
        true if date lays in the past or input is -1, false otherwise
*/

if(_timeArray isEqualType -1) exitWith {true};

private _year = _timeArray select 0;
private _date = _timeArray select 1;

private _currentDate = date;
private _currentYear = _currentDate select 0;
_currentDate = dateToNumber _currentDate;

//Fix year switch, unlikely case, but better safe than sorry
if (_currentYear > _year) then
{
    _date = _date - 1;
};

private _result = _date < _currentDate;
_result;
