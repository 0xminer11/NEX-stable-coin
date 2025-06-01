// SPDX-License-Identifier: UNLICENSED
import {NEX} from "./NEX.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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
    error NEXEngine_RedeemFailed();
    error NEXEngine_burnFailed();

    // *********************************** //
    //        State Variables              //
    // *********************************** //

    NEX private immutable _nex;

    mapping(address token => address priceFeed) private _priceFeeds;
    mapping(address token => uint256) private _collateralDeposited;
    mapping(address user => uint256 amount) private s_NexMinted;

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
            _;
        }
    }

    constructor(address _colletral, address _priceFeed, address _stableCoin) {
        _priceFeeds[_colletral] = _priceFeed;
        _nex = NEX(_stableCoin);
    }

    // *********************************** //
    //        External Functions           //
    // *********************************** //
    function depositeColletralMintNEX(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        uint256 amountNexToMint) external nonReentrant {
            _depositeCollateral(tokenCollateralAddress,amountCollateral);
            mintNEX(amountNexToMint);
    }

    function _depositeCollateral(address _colletral, uint256 _amount) internal{
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

    function redeemCollectral(
        address tokenCollateralAddress,
        uint256 amountCollateral ) 
        external 
        nonReentrant
        moreThanZero(amountCollateral)
        {
            _redeemCollateral(tokenCollateralAddress, amountCollateral, msg.sender);
        }

    function redeemColletralForNex(
        address tokenCollateralAddress,
        uint256 collateralAmount,
        uint256 nexAmount)
        external {
        _burnNEX(nexAmount,msg.sender,msg.sender);
        _redeemCollateral(tokenCollateralAddress,collateralAmount,msg.sender);
    }   

    function _burnNEX(uint256 amountNexToburn, address onbehalf,address fromnex) internal {
        s_NexMinted[onbehalf] -= amountNexToburn;

        bool success = _nex.transferFrom(fromnex,address(this), amountNexToburn);

        if(!success){
            revert NEXEngine_burnFailed();
        }
    }

    function mintNEX(uint256 _amountNexToMint) internal {
        s_NexMinted[msg.sender] += _amountNexToMint;

        // check health Factor of user
        // logic Here

        // Mint Nex Stable Coin
        _nex.mint(msg.sender, _amountNexToMint);

    }

    function liquidate() external {}

    function getHealthFactor() external {}

    function _redeemCollateral(address collateralAddress,uint256 amountCollateral,address to) private {
        _collateralDeposited[msg.sender] -= amountCollateral;

        bool success = IERC20(collateralAddress).transfer(to, amountCollateral);

        if (!success){
            revert NEXEngine_RedeemFailed();
        }
    }
}
