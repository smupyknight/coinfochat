pragma solidity ^0.4.17;

contract Donation {

  struct Payer {
    bool status;
    uint weight;
    uint balance;
  }

  address public owner;

  mapping(address => Payer) public payers;

  mapping(int8 => address) public payerIndexes;

  int8 public indexSize;

  event NewDonation(address indexed donator, uint amount);

  event Transfer(address indexed from, address indexed to, uint amount);

  event Withdrawal(address indexed payer, uint amount);

  event ContractDestroyed(address indexed contractAddress);


  function Donation() {
    owner = msg.sender;
    payers[owner].status = true;
    payers[owner].weight = 5;
    payerIndexes[0] = owner;
    indexSize = 1;
  }

  modifier isOwner() {

    if (msg.sender != owner) throw;
      _;

  }

  modifier isPayer() {

    if (payers[msg.sender].status != true) throw;
      _;

  }

  function getTotalWeight() private returns (uint) {

    int8 i;
    uint totalWeight = 0;

    for (i = 0; i < indexSize; i++) {
      if (payers[payerIndexes[i]].status == true) {
        totalWeight += payers[payerIndexes[i]].weight;
      }
    }

    return totalWeight;
  }

  function deposit() payable {

    if (msg.value == 0) {
      throw;
    }

    int8 i;
    uint totalWeight = 0;

    totalWeight = getTotalWeight();

    for (i = 0; i < indexSize; i++) {
      if (payers[payerIndexes[i]].status == true) {
        uint divisor = (totalWeight / payers[payerIndexes[i]].weight);
        payers[payerIndexes[i]].balance = msg.value / divisor;
      }
    }

    NewDonation(msg.sender, msg.value);
  }

  function appendPayer(address _payer, uint _weight) isOwner returns (bool) {
    payers[_payer].weight = _weight;
    payers[_payer].status = true;
    payerIndexes[indexSize] = _payer;
    indexSize ++;
  }

  function updatePayerWeight(address _payer, uint _weight) isOwner {
    payers[_payer].weight = _weight;
  }

  function lockPayer(address _payer) isOwner returns (bool) {
    if (_payer == owner) {
      throw;
    }

    payers[_payer].status = false;
  }

  function unlockPayer(address _address) isOwner {
    payers[_address].status = true;
  }

  function withdraw(uint amount) payable isPayer {
    if (payers[msg.sender].status != true || amount > payers[msg.sender].balance) {
      throw;
    }

    if (!msg.sender.send(amount)) {
      throw;
    }

    Withdrawal(msg.sender, amount);
    payers[msg.sender].balance -= amount;
  }

  function transferBalance(address _from, address _to, uint amount) isOwner {
    if (payers[_from].balance < amount) {
      throw;
    }

    payers[_from].balance -= amount;
    payers[_to].balance += amount;
    Transfer(_from, _to, amount);
  }


  function getBalance(address _address) isPayer returns (uint) {
    return payers[_address].balance;
  }


  function getWeight(address _address) isPayer returns(uint) {
    return payers[_address].weight;
  }


  function getStatus(address _address) returns(bool) {
    return payers[_address].status;
  }

  function transferOwner(address newOwner) isOwner returns (bool) {
    if (!payers[newOwner].status == true) {
      throw;
    }

    owner = newOwner;
  }

  function kill() payable isOwner {
    int8 i;
    address payer;

    for (i = 0; i < indexSize; i++) {
      payer = payerIndexes[i];
      if (payers[payer].balance > 0 ) {
        if (payer.send(payers[payer].balance)) {
          Withdrawal(payer, payers[payer].balance);
        }
      }
    }

    ContractDestroyed(this);
    selfdestruct(owner);
  }
}