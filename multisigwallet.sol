// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7; //default version of solidity selected as in remix ide

contract MultiSig{

    address mainOwner;
    address[] walletOwners; //array to append the wallet owners
    uint limit;
    uint depositId = 0;
    uint withdrawalId = 0;
    uint transferId =0;

    constructor (){

        mainOwner = msg.sender; //contract creator
        walletOwners.push(mainOwner); //the deployer is pushed to owners array at first 
        limit = walletOwners.length - 1;

    }

    modifier onlyOwners(){ //modifier is used to reduce recurring code snippets

        bool isOwner=false;
        for(uint i=0; i<walletOwners.length; i++){ //#1 security issue - only existing owners should call this function not anyone from outside
            if(walletOwners[i]==msg.sender){
                isOwner=true;
                break;
            }
        }

        require(isOwner==true,"Only wallet owners can call this function.");
        _;
    }

    mapping(address=>uint) balance; //key-value pair

    struct Transfer{

        address sender;
        address receiver;
        uint amount;
        uint id;
        uint approvals;
        uint timeOfTransaction;

    }

    Transfer[] transferRequest;//array to store transfer requests

    event walletOwnerAdded(address addedBy, address ownerAdded,uint timeOfTransaction); // logs of transactions
    event walletOwnerRemoved(address removedBy, address ownerRemoved,uint timeOfTransaction);
    event fundsDeposited(address sender, uint amount,uint depositId, uint timeOfTransaction);
    event fundsWithdrawed(address sender, uint amount,uint withdrawlId, uint timeOfTransaction);
    event transferCreated(address sender,address receiver,uint amount,uint transferId,uint approvals,uint timeOfTransaction);

    function getWalletOwners() public view returns(address[] memory){ //view keyword makes the function read only
    
    return walletOwners;

    }

    function addWalletOwner(address owner) public onlyOwners{

        for(uint i=0; i<walletOwners.length; i++) //#2 security issue - remove duplicacy of owners
        {
            if(walletOwners[i]==owner){
                revert("Cannot add duplicate owners.");
            }

        }

        walletOwners.push(owner); //to add a new owner
        limit = walletOwners.length - 1;
        emit walletOwnerAdded(msg.sender,owner,block.timestamp);
    }

    function removeWalletOwner(address owner) public onlyOwners {
        
        bool hasBeenFound=false;
        uint ownerIndex;
        for(uint i=0; i<walletOwners.length; i++){
            if(walletOwners[i]==owner){
                hasBeenFound=true;
                ownerIndex=i;
                break;
            }
        }

        require(hasBeenFound==true,"Wallet owner not detected.");
        walletOwners[ownerIndex] = walletOwners[walletOwners.length-1];
        walletOwners.pop(); //solidity allows deletion in an array by moving the element to the last index and then remove
        emit walletOwnerRemoved(msg.sender,owner,block.timestamp);
    }

    function deposit() public payable onlyOwners{

        require(balance[msg.sender]>=0,"Can not deposit a value 0 or less.");
        balance[msg.sender]=msg.value;
        emit fundsDeposited(msg.sender,msg.value,depositId,block.timestamp);
        depositId++;
        
    }

    function withdraw(uint amount) public onlyOwners{

        require(balance[msg.sender]>=amount);
        balance[msg.sender]-=amount;
        payable(msg.sender).transfer(amount);
        emit fundsWithdrawed(msg.sender,amount,withdrawalId,block.timestamp);
        withdrawalId++;

    }

    function getBalance() public view returns(uint){

        return balance[msg.sender];
    }

    function getContractBalance() public view returns(uint){

        return address(this).balance;
    }   

    function createTrnsferRequest(address receiver, uint amount) public onlyOwners{

    require(balance[msg.sender]>=amount,"Insufficient funds.");
    require(msg.sender!=receiver,"Can not self transfer.") //#3 security check to not send amount to oneself 
    
    balance[msg.sender]-=amount;
    transferRequest.push(Transfer(msg.sender,receiver,amount,transferId,0,block.timestamp));
    transferId++;
    emit transferCreated(msg.sender,receiver,amount,transferId,0,block.timestamp);

    }


}