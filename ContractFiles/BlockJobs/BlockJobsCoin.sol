// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract BlockJobsCoin is ERC20 {
    address public _adminAddress;

    event Bought(uint256 amount);
    event Sold(uint256 amount);
 
    //배포 전 openzepplin decimals setting 필수;
    constructor(string memory _name, string memory _symbol, uint _initSupply) ERC20(_name, _symbol){
        _adminAddress = msg.sender;
        _mint(msg.sender, _initSupply * (10 ** uint256(decimals())));        
    }  

    function CoinApprove(address _owner, address spender, uint256 amount) external returns (bool) {
        _approve(_owner, spender, amount);
        return true;
    }
}
