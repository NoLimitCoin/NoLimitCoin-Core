// SPDX-License-Identifier: NLC@2021

pragma solidity =0.7.6;

contract Events {
    
    event StakeStart(
        bytes16 indexed stakeID,
        address indexed stakerAddress,
        uint256 stakeType,
        uint256 stakedAmount,
        uint256 startDay,
        uint256 lockDays
    );

    event StakeEnd(
        bytes16 indexed stakeID,
        address indexed stakerAddress,
        uint256 stakeType,
        uint256 stakedAmount,
        uint256 rewardAmount,
        uint256 closeDay
    );

    event InterestScraped(
        bytes16 indexed stakeID,
        address indexed stakerAddress,
        uint256 scrapeAmount,
        uint256 scrapeDay
    );

    event NewGlobals(
        uint256 indexed currentDay,
        uint256 totalStaked,
        uint256 STStaked,
        uint256 MTStaked,
        uint256 LTStaked
    );

    event OwnershipTransferred(
        address indexed previousOwner, 
        address indexed newOwner
    );
}