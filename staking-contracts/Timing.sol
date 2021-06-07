// SPDX-License-Identifier: NLC@2021

pragma solidity =0.7.6;

import "./Declaration.sol";

abstract contract Timing is Declaration {

    function currentYear() public view returns (uint8) {
        return uint8(currentDay() / YEAR);
    }

    function currentMonth() public view returns (uint256) {
        return (currentDay() / MONTH);
    }

    function currentWeek() public view returns (uint256) {
        return (currentDay() / WEEK);
    }

    function currentDay() public view returns (uint256) {
        return _getNow() >= LAUNCH_TIME ? _currentDay() : 0;
    }

    function _currentDay() internal view returns (uint256) {
        return _getDayFromStamp(_getNow());
    }

    function _nextDay() internal view returns (uint256) {
        return _currentDay() + 1;
    }

    function _previousDay() internal view returns (uint256) {
        return _currentDay() - 1;
    }

    function _getDayFromStamp(uint256 _timestamp) internal view returns (uint256) {
        return uint256((_timestamp - LAUNCH_TIME) / SECONDS_IN_DAY);
    }

    function _getNow() internal view returns (uint256) {
        return block.timestamp;
    }
}