// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract JuneToken is ERC20 {
    address public _adminAddress;

    constructor(string memory _name, string memory _symbol, uint _initSupply) ERC20(_name, _symbol){
        _adminAddress = msg.sender;
        _mint(msg.sender, _initSupply * (10 ** uint256(decimals())));        
    }  
}
