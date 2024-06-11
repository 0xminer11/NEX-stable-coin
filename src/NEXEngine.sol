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

    // *********************************** //
    //        State Variables              //
    // *********************************** //

    NEX private immutable _nex;

    mapping(address token => address priceFeed) private _priceFeeds;
    mapping(address token => uint256) private _collateralDeposited;


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
        emit DepositeColletral(msg.sender, _colletral, _amount)git ;
    }

    function redeemCollectral() external {}

    function redeemNEXForColletral() external {}

    function burnNEX() external {}

    function mintNEX() external {}

    function liquidate() external {}

    function getHealthFactor() external {}
}
