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

    function invest() external payable {

    }

    function GetEther() external view returns (uint) {
        return address(this).balance;
    }

    function getbalancetest() external view returns (uint) {
        return balanceOf(_adminAddress);
    }

    function Buy() payable public{
        uint256 amountTobuy = msg.value;
        uint256 dexBalance = balanceOf(_adminAddress);
        require(amountTobuy > 0, "You need to send some ether");
        require(amountTobuy <= dexBalance, "Not enough tokens in the reserve");
        transferFrom(_adminAddress, msg.sender, amountTobuy);
        emit Bought(amountTobuy);
    }

    function sell(uint256 amount) payable public{
        require(amount > 0, "You need to sell at least some tokens");
        uint256 allowance = allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        transferFrom(msg.sender, address(this), amount);
        payable(msg.sender).transfer(amount);
        emit Sold(amount);
    }
}
