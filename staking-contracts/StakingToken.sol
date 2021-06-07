// SPDX-License-Identifier: NLC@2021

pragma solidity =0.7.6;

import "./ownable.sol";

contract StakingToken is Ownable {

    using SafeMath for uint256;
    receive() payable external {}

    constructor(address _stakingTokenAddress) 
            Declaration(_stakingTokenAddress) {}

    /**
     * @notice A method for a staker to create a stake
     * @param _stakedAmount amount of token to be staked.
     * @param _stakeType SHORT_TERM/MEDIUM_TERM/LONG_TERM.
     */
    function createStake(
        uint256 _stakedAmount,
        StakeType _stakeType
    )
        external
        returns (bytes16, uint256)
    {
        uint64 _lockDays;
        if (_stakeType == StakeType.SHORT_TERM)
        {
            _lockDays = WEEK;
        }
        else if(_stakeType == StakeType.MEDIUM_TERM)
        {
            _lockDays = 1*MONTH;
        }
        else if (_stakeType == StakeType.LONG_TERM)
        {
            _lockDays = 3*MONTH;
        }
        else
        {
            revert('NLC: _StakeType is Invalid');
        }
        
        (
            Stake memory newStake,
            bytes16 stakeID,
            uint256 _startDay
        ) =
        _createStake(_msgSender(), _stakedAmount, _lockDays, _stakeType);

        stakes[_msgSender()][stakeID] = newStake;

        _increaseStakeCount(
            _msgSender()
        );

        _increaseGlobals(
            uint8(newStake.stakeType),
            newStake.stakedAmount
        );

        stakeCaps[_stakeType]++;

        emit StakeStart(
            stakeID,
            _msgSender(),
            uint256(newStake.stakeType),
            newStake.stakedAmount,
            newStake.startDay,
            newStake.lockDays
        );

        return (stakeID, _startDay);
    }

    /**
    * @notice A method for a staker to start a stake
    * @param _staker ...
    * @param _stakedAmount ...
    * @param _lockDays ...
    * @param _stakeType ...
    */
    function _createStake(
        address _staker,
        uint256 _stakedAmount,
        uint64 _lockDays,
        StakeType  _stakeType
    )
        private
        returns (
            Stake memory _newStake,
            bytes16 _stakeID,
            uint256 _startDay
        )
    {
        require(
            STAKING_TOKEN.balanceOf(_staker) >= _stakedAmount,
            "NLC: Staker doesn't have enough balance"
        );

        STAKING_TOKEN.transferFrom(
            _staker,
            address(this),
            _stakedAmount
        );

        _startDay = currentDay();
        _stakeID = generateStakeID(_staker);

        _newStake.stakedAmount = _stakedAmount;
        _newStake.stakeType = _stakeType;
        _newStake.lockDays = _lockDays;
        _newStake.startDay = _startDay;
        _newStake.finalDay = _startDay + _lockDays;
        _newStake.isActive = true;
    }

    /**
    * @notice A method for a staker to remove a stake
    * belonging to his address by providing ID of a stake.
    * @param _stakeID unique bytes sequence reference to the stake
    */
    function endStake(
        bytes16 _stakeID
    )
        external
        returns (uint256)
    {
        (
            Stake memory endedStake
        ) =
        _endStake(_msgSender(), _stakeID);

        _decreaseGlobals(
            uint8(endedStake.stakeType),
            endedStake.stakedAmount
        );

        stakeCaps[endedStake.stakeType]--;

        emit StakeEnd(
            _stakeID,
            _msgSender(),
            uint256(endedStake.stakeType),
            endedStake.stakedAmount,
            endedStake.rewardAmount,
            endedStake.closeDay
        );

        return endedStake.rewardAmount;
    }

    /**
    * @notice A method for a staker to end a stake
    * @param _staker ...
    * @param _stakeID ...
    */
    function _endStake(
        address _staker,
        bytes16 _stakeID
    )
        private
        returns (
            Stake storage _stake
        )
    {
        require(
            stakes[_staker][_stakeID].isActive,
            'NLC: Not an active stake'
        );

        _stake = stakes[_staker][_stakeID];
        _stake.closeDay = currentDay();
        _stake.rewardAmount = _calculateRewardAmount(_staker, _stakeID);

        _stake.isActive = false;

        STAKING_TOKEN.transfer(
            _staker,
            _stake.stakedAmount
        );

        if (_stake.rewardAmount > 0) {
            REWARD_TOKEN.transferFrom(
                reward_wallet,
                _staker,
                _stake.rewardAmount
            );    
        }
        
    }

    /**
    * @notice alloes to scrape Reward from active stake
    * @param _stakeID unique bytes sequence reference to the stake
    */
    function scrapeReward(
        bytes16 _stakeID
    )
        external
        returns (
            uint256 scrapeDay,
            uint256 scrapeAmount
        )
    {
        require(
            stakes[_msgSender()][_stakeID].isActive,
            'NLC: Not an active stake'
        );

        Stake memory stake = stakes[_msgSender()][_stakeID];

        require(
                currentDay() >= stake.finalDay,
                'NLC: Stake is not yet mature to claim Reward'
        );

        scrapeDay = currentDay();
        scrapeAmount = _calculateRewardAmount(_msgSender(), _stakeID);

        scrapes[_msgSender()][_stakeID] =
        scrapes[_msgSender()][_stakeID].add(scrapeAmount);
        
        stake.scrapeDay = scrapeDay;
        stakes[_msgSender()][_stakeID] = stake;

        if (scrapeAmount > 0) {
            REWARD_TOKEN.transferFrom(
                reward_wallet,
                _msgSender(),
                scrapeAmount
            );
        }

        emit InterestScraped(
            _stakeID,
            _msgSender(),
            scrapeAmount,
            scrapeDay
        );
    }

    function updateRewardWalletAddress(
            address _walletAddress
    )
        external
        onlyOwner
        validAddress(_walletAddress)
    {
        reward_wallet = address(_walletAddress);
    }

    function checkMatureStake(
        address _staker,
        bytes16 _stakeID
    )
        external
        view
        returns (bool isMature)
    {
        Stake memory stake = stakes[_staker][_stakeID];
        isMature = _isMatureStake(stake);
    }

    function checkStakeByID(
        address _staker,
        bytes16 _stakeID
    )
        external
        view
        returns 
    (
        uint256 startDay,
        uint256 lockDays,
        uint256 finalDay,
        uint256 closeDay,
        uint256 scrapeDay,
        StakeType stakeType,
        uint256 stakedAmount,
        uint256 rewardAmount,
        bool isActive,
        bool isMature
    )
    {
        Stake memory stake = stakes[_staker][_stakeID];
        startDay = stake.startDay;
        lockDays = stake.lockDays;
        finalDay = stake.finalDay;
        closeDay = stake.closeDay;
        scrapeDay = stake.scrapeDay;
        stakeType = stake.stakeType;
        stakedAmount = stake.stakedAmount;
        rewardAmount = _calculateRewardAmount(_staker, _stakeID);
        isActive = stake.isActive;
        isMature = _isMatureStake(stake);
    }

    function getPendingReward(
        address _staker,
        bytes16 _stakeID
    )
        external
        view
        returns (uint256 rewardAmount)
    {
        require(
            stakes[_staker][_stakeID].isActive,
            'NLC: Not an active stake'
        );
        
        rewardAmount = _calculateRewardAmount(_staker, _stakeID);
    }
        
    function _calculateRewardAmount(
        address _staker,
        bytes16 _stakeID
    )
        internal view
        returns 
    (
        uint256 rewardAmount
    )
    {
        Stake memory stake = stakes[_staker][_stakeID];
        uint256 rewardDays;
        
        if(!_isMatureStake(stake) || 
                    _startingDay(stake) >= (YEAR * YEAR_4) ||
                        !stake.isActive)
        {
            return 0;
        }

        if (currentYear() >= YEAR_1)
        {    
            if (_startingDay(stake) <= (YEAR * YEAR_1))
            {
                rewardDays =  _daysDiff(_startingDay(stake), YEAR*YEAR_1);
                if(rewardDays != 0)
                {
                    rewardAmount += (stake.stakedAmount
                            .mul(interest[stake.stakeType][YEAR_0])
                            .mul(rewardDays)).div(YEAR*100);
                    stake.scrapeDay = (YEAR * YEAR_1);
                }
            }

            if (currentYear() >= YEAR_2 && 
                    _startingDay(stake) <= (YEAR * YEAR_2))
            {
                rewardDays =  _daysDiff(_startingDay(stake), YEAR*YEAR_2);
                if(rewardDays != 0)
                {
                    rewardAmount += (stake.stakedAmount
                            .mul(interest[stake.stakeType][YEAR_1])
                            .mul(rewardDays)).div(YEAR*100);
                    stake.scrapeDay = (YEAR * YEAR_2);
                }
            }

            if (currentYear() >= YEAR_3 && 
                    _startingDay(stake) <= (YEAR * YEAR_3))
            {
                rewardDays =  _daysDiff(_startingDay(stake), YEAR*YEAR_3);
                if(rewardDays != 0)
                {
                    rewardAmount += (stake.stakedAmount
                            .mul(interest[stake.stakeType][YEAR_2])
                            .mul(rewardDays)).div(YEAR*100);
                    stake.scrapeDay = (YEAR * YEAR_3);
                }
            }
            
            if (currentYear() >= YEAR_4 && 
                    _startingDay(stake) <= (YEAR * YEAR_4))
            {
                rewardDays =  _daysDiff(_startingDay(stake), YEAR*YEAR_4);
                if(rewardDays != 0)
                {
                    rewardAmount += (stake.stakedAmount
                            .mul(interest[stake.stakeType][YEAR_3])
                            .mul(rewardDays)).div(YEAR*100);
                    stake.scrapeDay = (YEAR * YEAR_4);
                    return rewardAmount;
                }
            }

        }

        rewardDays = _daysDiff(_startingDay(stake), currentDay());
        if(rewardDays != 0)
        {
            rewardAmount += (stake.stakedAmount
                            .mul(interest[stake.stakeType][currentYear()])
                            .mul(rewardDays)).div(YEAR*100);
        }
    }

    function getStakeCount() 
        external view 
        returns 
    (
        uint256 STStakeCount, 
        uint256 MTStakeCount,
        uint256 LTStakeCount
    )
    {
        STStakeCount = stakeCaps[StakeType.SHORT_TERM];
        MTStakeCount = stakeCaps[StakeType.MEDIUM_TERM];
        LTStakeCount = stakeCaps[StakeType.LONG_TERM];
    }

    function getTotalStakedToken()
        external    
        view 
        returns (uint256) 
    {
        return globals.totalStaked;
    }
}
