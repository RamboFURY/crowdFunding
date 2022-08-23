// SPDX-License-Identifier: RamboFURY

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

    //key-value pairs
    mapping(address=>uint) balance;
    mapping(address=>mapping(uint=>bool))approvals;

    struct Transfer{

        address sender;
        address payable receiver;
        uint amount;
        uint id;
        uint approvals;
        uint timeOfTransaction;

    }

    Transfer[] transferRequests;//array to store transfer requests

    // logs of transactions
    event walletOwnerAdded(address addedBy, address ownerAdded,uint timeOfTransaction);
    event walletOwnerRemoved(address removedBy, address ownerRemoved,uint timeOfTransaction);
    event fundsDeposited(address sender, uint amount,uint depositid, uint timeOfTransaction);
    event fundsWithdrawed(address sender, uint amount,uint withdrawlid, uint timeOfTransaction);
    event transferCreated(address sender,address receiver,uint amount,uint transferid,uint approvals,uint timeOfTransaction);
    event transferCancelled(address sender,address receiver,uint amount,uint transferid,uint approvals,uint timeOfTransaction);
    event transferApproved(address sender,address receiver,uint amount,uint transferid,uint approvals,uint timeOfTransaction);
    event fundsTransferred(address sender,address receiver,uint amount,uint transferid,uint approvals,uint timeOfTransaction);

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

    function createTransferRequest(address payable receiver, uint amount) public onlyOwners{

    require(balance[msg.sender]>=amount,"Insufficient funds.");
    for(uint i=0; i<walletOwners.length; i++){

        require(walletOwners[i] != receiver, "Cannot transfer funds within the wallet.");

    }
    
    balance[msg.sender]-=amount;
    transferRequests.push(Transfer(msg.sender,receiver,amount,transferId,0,block.timestamp));
    transferId++;
    emit transferCreated(msg.sender,receiver,amount,transferId,0,block.timestamp);

    }

    function cancelTransferRequest(uint id) public onlyOwners{

        bool hasBeenFound=false;
        uint transferIndex=0;
        for(uint i=0; i<transferRequests.length; i++){

            if(transferRequests[i].id==id){

                hasBeenFound=true;
                break;
            }

            transferIndex++;
        }

        require(hasBeenFound,"Transfer id not found.");
        require(msg.sender==transferRequests[transferIndex].sender);

        balance[msg.sender]+=transferRequests[transferIndex].amount;
        transferRequests[transferIndex]=transferRequests[transferRequests.length-1];
        transferRequests.pop();

        emit transferCancelled(msg.sender,transferRequests[transferIndex].receiver,transferRequests[transferIndex].amount,transferRequests[transferIndex].id,transferRequests[transferIndex].approvals,transferRequests[transferIndex].timeOfTransaction);

    }

    function approveTransferRequest(uint id) public onlyOwners {

        bool hasBeenFound=false;
        uint transferIndex=0;
        for(uint i=0; i<transferRequests.length-1; i++){

            if(transferRequests[i].id==id){

                hasBeenFound=true;
                break;
            }

            transferIndex++;

        }

        require(hasBeenFound);
        require(transferRequests[transferIndex].receiver==msg.sender,"Cannot approve your own transfer.");  //#4 security check so that sender does not send to itself
        require(approvals[msg.sender][id]==false,"Cannot approve twice.");

        transferRequests[transferIndex].approvals +=1;
        approvals[msg.sender][id]=true;

        emit transferApproved(msg.sender,transferRequests[transferIndex].receiver,transferRequests[transferIndex].amount,transferRequests[transferIndex].id,transferRequests[transferIndex].approvals,transferRequests[transferIndex].timeOfTransaction);


        if(transferRequests[transferIndex].approvals==limit){

            transferFunds(transferIndex);
        }
    }

    function transferFunds(uint id) private {

        balance[transferRequests[id].receiver]+=transferRequests[id].amount;
        transferRequests[id].receiver.transfer(transferRequests[id].amount);

        emit fundsTransferred(msg.sender,transferRequests[id].receiver,transferRequests[id].amount,transferRequests[id].id,transferRequests[id].approvals,transferRequests[id].timeOfTransaction);
        
        transferRequests[id]=transferRequests[transferRequests.length-1];
        transferRequests.pop();

    }

    function getApprovals(uint id) public view returns(bool){

        return approvals[msg.sender][id];

    }

    function getTransferRequests() public view returns(Transfer[] memory){

        return transferRequests;

    }

    function getBalance() public view returns(uint){

        return balance[msg.sender];
    }

    function getApprovalLimit() public view returns (uint) {

        return limit;

    }

    function getContractBalance() public view returns(uint){

        return address(this).balance;
    } 
}