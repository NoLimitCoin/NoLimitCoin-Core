// SPDX-License-Identifier: NLC@2021

pragma solidity =0.7.6;

import "./Global.sol";

abstract contract Declaration is Global {

    uint256 constant _decimals = 18;
    
    uint64 constant PRECISION_RATE = 1E18;
    uint32 constant REWARD_PRECISION_RATE = 1E8;

    uint32 constant SECONDS_IN_DAY = 86400 seconds; 
    uint16 constant WEEK = 7;
    uint16 constant MONTH = WEEK * 4;
    uint16 constant YEAR = MONTH * 12;
    uint8 constant YEAR_0 = 0;
    uint8 constant YEAR_1 = 1;
    uint8 constant YEAR_2 = 2;
    uint8 constant YEAR_3 = 3;
    uint8 constant YEAR_4 = 4;
    uint8 constant YEAR_5 = 5;
  
    address public reward_wallet = 0x35DAF7182B0637Db15377B7C45b328d2Dec21400;
    address public _owner;


    uint256 immutable LAUNCH_TIME;
    IBEPToken public REWARD_TOKEN;
    IBEPToken public STAKING_TOKEN;

    constructor(address _tokenAddress)
    {
        STAKING_TOKEN = IBEPToken(_tokenAddress);
        REWARD_TOKEN = IBEPToken(_tokenAddress);
        LAUNCH_TIME = 1627689600;// (31th JULY 2021 @00:00 GMT == day 0)

        interest[StakeType.SHORT_TERM][YEAR_0] = 5;
        interest[StakeType.SHORT_TERM][YEAR_1] = 5;
        interest[StakeType.MEDIUM_TERM][YEAR_0] = 10;
        interest[StakeType.MEDIUM_TERM][YEAR_1] = 10;
        interest[StakeType.MEDIUM_TERM][YEAR_2] = 5;
        interest[StakeType.LONG_TERM][YEAR_0] = 20;
        interest[StakeType.LONG_TERM][YEAR_1] = 15;
        interest[StakeType.LONG_TERM][YEAR_2] = 10;
        interest[StakeType.LONG_TERM][YEAR_3] = 5;
    }

    struct Stake {
        uint256 stakedAmount;
        uint256 rewardAmount;
        StakeType stakeType;
        uint256 startDay;
        uint256 lockDays;
        uint256 finalDay;
        uint256 closeDay;
        uint256 scrapeDay;
        bool isActive;
    }

    enum StakeType {
        SHORT_TERM,
        MEDIUM_TERM,
        LONG_TERM
    }

    mapping(address => uint256) public stakeCount;
    mapping(address => mapping(bytes16 => uint256)) public scrapes;
    mapping(address => mapping(bytes16 => Stake)) public stakes;
    mapping(StakeType => uint256) public stakeCaps;
    mapping(StakeType => mapping(uint8 => uint256)) internal interest;
}
