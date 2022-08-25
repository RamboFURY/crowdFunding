// SPDX-License-Identifier: RamboFURY

pragma solidity 0.8.7; //default version of solidity selected as in remix ide

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

contract Link is ERC20 {
     
     constructor() ERC20("chainlink","LINK") {

         _mint(msg.sender,10000000000000000000000);

     }

     function _approve(address owner, uint amount) public {

         ERC20.approve(owner,amount); 
         
     }
}
