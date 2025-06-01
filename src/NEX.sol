// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/*
    * NEX : Decentralized Stable Coin
    * Author : 0xminer11
    * NEX is a decentralized stable coin that is pegged to the US Dollar.
    * It is backed by a basket of cryptocurrencies and is governed by a DAO.
    * The NEX token is used for governance and as a medium of exchange.
    * Minting : Algorithmic
    * This contract is meant to be governed by a NEXEngine. This contract is just ERC20 Implementation of our stable coin.
*/

contract NEX is ERC20Burnable, Ownable {

    constructor(string memory _name, string memory _symbol,address initialOwner) ERC20(_name, _symbol) Ownable(initialOwner){
        trustedMinters[initialOwner]=true;
    }
    error NEX_MustBeGreaterThanZero();
    error NEX_InsufficientBalance();
    error NotZeroAddress();

    mapping(address user=> bool ) private trustedMinters;

    modifier isTrustedMinter(address _user) {
        require(trustedMinters[_user],"Not Trusted Minter");
        _;
    }

    function burn(uint256 amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (amount == 0) {
            revert NEX_MustBeGreaterThanZero();
        }
        if (amount > balance) {
            revert NEX_InsufficientBalance();
        }
        super.burn(amount);
    }

    function mint(address to, uint256 amount) public isTrustedMinter(msg.sender) {
        require(to != address(0), "NEX: mint to the zero address");
        require(amount > 0, "NEX: mint amount must be greater than zero");
        _mint(to, amount);
    }

    function setauthorisedEngine(address _engine) external onlyOwner {
     require(!trustedMinters[_engine], "NEX: Allready trusted minter");
     require(_engine != address(0), "NEX: Authorised Engine cannot be zero");
     trustedMinters[_engine] = true;
    }
}
