// SPDX-License-Identifier: NLC@2021

pragma solidity =0.7.6;

import "./SafeMath.sol";
import "./Interfaces.sol";
import "./Events.sol";

abstract contract Global is Events {

    using SafeMath for uint256;

    struct Globals {
        uint256 totalStaked;
        uint256 STStaked;
        uint256 MTStaked;
        uint256 LTStaked;
    }

    Globals public globals;

    function _increaseGlobals(
        uint8 _stakeType, 
        uint256 _staked
    )
        internal
    {
        globals.totalStaked =
        globals.totalStaked.add(_staked);

        if (_stakeType == 0) // SHORT_TERM STAKER
        {
            globals.STStaked = 
                globals.STStaked.add(_staked);
        }
        else if (_stakeType == 1) // MEDIUM_TERM STAKER
        {
            globals.MTStaked = 
                globals.MTStaked.add(_staked);
        }
        else  // LONG_TERM STAKER
        {
            globals.LTStaked = 
                globals.LTStaked.add(_staked);
        }

        _logGlobals();
    }

    function _decreaseGlobals(
        uint8 _stakeType,
        uint256 _staked
    )
        internal
    {
        globals.totalStaked =
        globals.totalStaked > _staked ?
        globals.totalStaked - _staked : 0;

        if (_stakeType == 0) // SHORT_TERM STAKER
        {
            globals.STStaked = 
                globals.STStaked > _staked ?
                globals.STStaked - _staked : 0;
        }
        else if (_stakeType == 1) // MEDIUM_TERM STAKER
        {
            globals.MTStaked = 
                globals.MTStaked > _staked ?
                globals.MTStaked - _staked : 0;
        }
        else // LONG_TERM STAKER
        {
            globals.LTStaked = 
                globals.LTStaked > _staked ?
                globals.LTStaked - _staked : 0;
        }
        
        _logGlobals();
    }

    function _logGlobals()
        private
    {
        emit NewGlobals(
            block.timestamp,
            globals.totalStaked,
            globals.LTStaked,
            globals.MTStaked,
            globals.LTStaked
        );
    }
}