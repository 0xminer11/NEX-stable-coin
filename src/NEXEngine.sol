// SPDX-License-Identifier: UNLICENSED
import {NEX} from "./NEX.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

pragma solidity ^0.8.19;

/**
 * NEX : Decentralized Stable Coin
 * @author : 0xminer11
 * NEX is a decentralized stable coin that is pegged to the US Dollar.
 * This contract will handle the minting and burning of the NEX token.
 *
 */
contract NEXEngine is ReentrancyGuard {
    // ************************** //
    //        Errors               //
    // *************************** //

    error NEXEngine_NeedsMoreThanZero();
    error NEXEngine_ColletralNotAllowed();
    error NEXEngine_DepositeFailed();
    error NEXEngine_HealthFactorIsLessThanOne();

    // *********************************** //
    //        State Variables              //
    // *********************************** //

    NEX private immutable _nex;
    uint256 private ADDITIONAL_FEED_PRECISION = 1e18;
    uint256 private PRECISION = 1e10;
    uint256 private MIN_HEALTH_FACTOR = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50;
    uint256 private constant LIQUIDATION_PRICISION = 100; 
    address private COLLETRAL;

    mapping(address token => address priceFeed) private _priceFeeds;
    mapping(address token => uint256) private _collateralDeposited;
    mapping(address user => uint256) private s_nexMinted;


    // *********************//
    //       Events         //
    // ******************** //

    event DepositeColletral(address indexed user, address indexed colletral, uint256 amount);

    // ************************** //
    //        Modifiers           //
    // ************************** //

    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert NEXEngine_NeedsMoreThanZero();
        }
        _;
    }

    modifier isAllowed(address _collateral) {
        if (_priceFeeds[_collateral] == address(0)) {
            revert NEXEngine_ColletralNotAllowed();
        }
        _;
    }

    constructor(address _colletral, address _priceFeed, address _stableCoin) {
        _priceFeeds[_colletral] = _priceFeed;
        _nex = NEX(_stableCoin);
        COLLETRAL= _colletral;
    }

    // *********************************** //
    //        External Functions           //
    // *********************************** //
    function depositeColletralMintNEX() external {}

    function depositeColletral(address _colletral, uint256 _amount)
        external
        moreThanZero(_amount)
        isAllowed(_colletral)
        nonReentrant
    {
        // Transfer the colletral to this contract
        // Calculate the value of the colletral
        // Mint NEX tokens
        _collateralDeposited[msg.sender] += _amount;
        bool success =IERC20(_colletral).transferFrom(msg.sender, address(this), _amount);
        if (!success) {
            revert NEXEngine_DepositeFailed();
        }
        emit DepositeColletral(msg.sender, _colletral, _amount) ;
    }

    function redeemCollectral() external {}

    function redeemNEXForColletral() external {}

    function burnNEX() external {}

    /*
     * @dev Mint NEX tokens
     * @param _amountToMintNEX Amount of NEX decentralized stable coins to mint
     * @notice They should have deposited more collateral than the minimum threshold
     */
    function mintNEX(uint256 _amountToMintNEX) moreThanZero(_amountToMintNEX) nonReentrant() external {
        s_nexMinted[msg.sender] += _amountToMintNEX;
        _revertIFHealthFactorIsLessThanOne(msg.sender);
        _nex.mint(msg.sender, _amountToMintNEX);
    }

    function _healthFactor(address _user) public view returns(uint256) {
        (uint256 totalNEXMinted, uint256 totalColletralInUSD) = getAccountInformation(_user);
        uint256 colletrlAdjustedThreshould = (totalColletralInUSD * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRICISION;
        // return (totalColletralInUSD / totalNEXMinted);
        return (colletrlAdjustedThreshould * PRECISION) / totalNEXMinted;
    }

    function _revertIFHealthFactorIsLessThanOne(address _user) private view{
        uint256 healthFactor = _healthFactor(_user);
        if (healthFactor < MIN_HEALTH_FACTOR) {
            revert NEXEngine_HealthFactorIsLessThanOne();
        }
    }

    function getAccountInformation(address user) private view returns(uint256 totalNEXMinted,uint256 totalColletralInUSD ) {
        totalNEXMinted = s_nexMinted[user];
        totalColletralInUSD = getUSDValueOfColletral(COLLETRAL, totalNEXMinted);
        return (totalNEXMinted, totalColletralInUSD);
    }

    function getUSDValueOfColletral(address _colletral, uint256 _amount) internal view returns(uint256) {
        address priceFeed = _priceFeeds[_colletral];
        (,int256 price,,,) = AggregatorV3Interface(priceFeed).latestRoundData();
        return ((uint256(price) * ADDITIONAL_FEED_PRECISION * _amount) / PRECISION);
    }



    function liquidate() external {}

    function getHealthFactor() external {}
}
