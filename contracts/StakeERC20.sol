// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakingContract is ReentrancyGuard, Ownable {
    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 duration;
        uint256 earned;
        uint256 claimedRewards;
        bool rewardsClaimed;
    }

    struct StakedInfo {
        uint256 totalLocked;
        uint256 totalRewardsPending;
        uint256 totalClaimedRewards;
        Stake[] stakes;
    }

    mapping(address => StakedInfo) public stakedInfo;
    mapping(uint256 => uint256) public apyRates;
    mapping(uint256 => uint256) public maxStakePerApy;
    mapping(uint256 => uint256) public totalStakeReached;

    uint256 public totalValueLocked;
    uint256 public stakersCount;
    uint256 public earlyWithdrawalPenalty = 50; // 50% penalty
    bool public paused;

    IERC20 public stakingToken;

    event Staked(address indexed user, uint256 amount, uint256 duration, uint256 stakeId);
    event Withdrawn(address indexed user, uint256 amount, uint256 stakeId);
    event RewardsClaimed(address indexed user, uint256 reward, uint256 stakeId);

    constructor(address _stakingToken) {
        require(_stakingToken != address(0), "Invalid token address");
        stakingToken = IERC20(_stakingToken);

        // Set initial APY rates (in %)
        apyRates[30] = 15;
        apyRates[90] = 20;
        apyRates[180] = 25;
        apyRates[360] = 30;

        // Set max stake limits for each APY (in wei)
        maxStakePerApy[30] = 10_00_000 * 10**18; // 10 lakh
        maxStakePerApy[90] = 15_00_000 * 10**18; // 15 lakh
        maxStakePerApy[180] = 20_00_000 * 10**18; // 20 lakh
        maxStakePerApy[360] = 30_00_000 * 10**18; // 30 lakh
    }

    modifier whenNotPaused() {
        require(!paused, "Staking is paused");
        _;
    }

    function stake(uint256 _amount, uint256 _duration) external nonReentrant whenNotPaused {
        require(_amount > 0, "Stake amount must be greater than 0");
        require(apyRates[_duration] > 0, "Invalid staking duration");
        require(_amount <= stakingToken.balanceOf(msg.sender), "Not enough tokens");

        // Check if staking limit for the APY is not exceeded
        require(
            totalStakeReached[_duration] + _amount <= maxStakePerApy[_duration],
            "Stake exceeds allowed limit for this APY"
        );

        stakingToken.transferFrom(msg.sender, address(this), _amount);

        StakedInfo storage userStakedInfo = stakedInfo[msg.sender];
        if (userStakedInfo.stakes.length == 0) {
            stakersCount++;
        }

        Stake memory newStake = Stake({
            amount: _amount,
            startTime: block.timestamp,
            duration: _duration * 1 days,
            earned: 0,
            claimedRewards: 0,
            rewardsClaimed: false
        });

        userStakedInfo.stakes.push(newStake);
        userStakedInfo.totalLocked += _amount;
        totalValueLocked += _amount;
        totalStakeReached[_duration] += _amount;

        uint256 stakeId = userStakedInfo.stakes.length - 1;
        emit Staked(msg.sender, _amount, _duration, stakeId);
    }

    function withdrawAndClaim(uint256 _stakeId) external nonReentrant whenNotPaused {
        StakedInfo storage userStakedInfo = stakedInfo[msg.sender];
        require(_stakeId < userStakedInfo.stakes.length, "Invalid stake ID");

        Stake storage userStake = userStakedInfo.stakes[_stakeId];
        require(userStake.amount > 0, "No active stake");
        require(!userStake.rewardsClaimed, "Already Claimed");

        uint256 reward = _calculateRewards(msg.sender, _stakeId);
        uint256 totalWithdrawAmount;

        if (block.timestamp < userStake.startTime + userStake.duration) {
            uint256 penalty = (userStake.amount * earlyWithdrawalPenalty) / 100;
            totalWithdrawAmount = userStake.amount - penalty;
            require(totalWithdrawAmount > 0, "Withdrawal amount too low after penalty");
        } else {
            totalWithdrawAmount = userStake.amount;
        }

        userStakedInfo.totalLocked -= userStake.amount; 
        totalValueLocked -= userStake.amount;
        totalStakeReached[userStake.duration / 1 days] -= userStake.amount; // Reduce total stake count
        userStake.amount = 0; 
        userStake.rewardsClaimed = true; 
        userStake.claimedRewards = reward; 

        uint256 totalAmount = totalWithdrawAmount + reward;
        require(stakingToken.transfer(msg.sender, totalAmount), "Transfer failed");

        userStakedInfo.totalClaimedRewards += reward;
        emit Withdrawn(msg.sender, totalAmount, _stakeId);
    }

    function _calculateRewards(address _user, uint256 _stakeId) internal view returns (uint256) {
        StakedInfo storage userStakedInfo = stakedInfo[_user];
        require(_stakeId < userStakedInfo.stakes.length, "Invalid stake ID");

        Stake storage userStake = userStakedInfo.stakes[_stakeId];
        uint256 timeElapsed = block.timestamp - userStake.startTime;

        if (timeElapsed >= userStake.duration) {
            return (userStake.amount * apyRates[userStake.duration / 1 days] * userStake.duration / 365 days) / 100;
        } else {
            return (userStake.amount * apyRates[userStake.duration / 1 days] * timeElapsed / 365 days) / 100;
        }
    }

    function getMaxStakeInfo(uint256 _duration) external view returns (uint256 maxStake, uint256 totalStake) {
        return (maxStakePerApy[_duration], totalStakeReached[_duration]);
    }

    function setAPY(uint256 _duration, uint256 _apy) external onlyOwner {
        require(_duration > 0, "Duration must be positive");
        require(_apy > 0, "APY must be greater than zero");
        apyRates[_duration] = _apy;
    }

    function setMaxStakeForApy(uint256 _duration, uint256 _maxStake) external onlyOwner {
        require(_duration > 0, "Duration must be positive");
        maxStakePerApy[_duration] = _maxStake;
    }

    function setEarlyWithdrawalPenalty(uint256 _penalty) external onlyOwner {
        require(_penalty <= 50, "Penalty cannot exceed 50%");
        earlyWithdrawalPenalty = _penalty;
    }

    function togglePause() external onlyOwner {
        paused = !paused;
    }

    function getTotalValueLocked() external view returns (uint256) {
        return totalValueLocked;
    }

    function getStakersCount() external view returns (uint256) {
        return stakersCount;
    }

    function transferAccidentallyLockedTokens(IERC20 token, uint256 amount) public onlyOwner nonReentrant {
        require(address(token) != address(0), "Token address cannot be zero");
        require(token != stakingToken, "Cannot withdraw staking token");
        token.transfer(owner(), amount);
    }
       function getLockedAmount(address _user) external view returns (uint256) {
        return stakedInfo[_user].totalLocked;
    }

    function getClaimableRewards(address _user) external view returns (uint256) {
        StakedInfo storage userStakedInfo = stakedInfo[_user];
        uint256 totalRewards = 0;
        for (uint256 i = 0; i < userStakedInfo.stakes.length; i++) {
            if (!userStakedInfo.stakes[i].rewardsClaimed) {
                totalRewards += _calculateRewards(_user, i);
            }
        }
        return totalRewards;
    }

    function getStakeInfo(address _user, uint256 _stakeId) external view returns (Stake memory) {
        StakedInfo storage userStakedInfo = stakedInfo[_user];
        require(_stakeId < userStakedInfo.stakes.length, "Invalid stake ID");
        Stake memory stakeInfo = userStakedInfo.stakes[_stakeId];
        if (!stakeInfo.rewardsClaimed) {
            stakeInfo.earned = _calculateRewards(_user, _stakeId);
        }
        return stakeInfo;
    }

    function getTotalStakes(address _user) external view returns (uint256) {
        return stakedInfo[_user].stakes.length;
    }

    function getAllStakedInfo(address _user) external view returns (
        uint256 totalLocked,
        uint256 totalRewardsPending,
        uint256 totalClaimedRewards,
        Stake[] memory stakes
    ) {
        StakedInfo storage userStakedInfo = stakedInfo[_user];
        Stake[] memory updatedStakes = new Stake[](userStakedInfo.stakes.length);
        uint256 totalPendingRewards = 0;

        for (uint256 i = 0; i < userStakedInfo.stakes.length; i++) {
            Stake memory stakeInfo = userStakedInfo.stakes[i];
            if (!stakeInfo.rewardsClaimed) {
                stakeInfo.earned = _calculateRewards(_user, i);
                totalPendingRewards += stakeInfo.earned;
            }
            updatedStakes[i] = stakeInfo;
        }

        return (
            userStakedInfo.totalLocked,
            totalPendingRewards,
            userStakedInfo.totalClaimedRewards,
            updatedStakes
        );
    }
}
