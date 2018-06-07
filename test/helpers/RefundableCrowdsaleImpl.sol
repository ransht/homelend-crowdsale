pragma solidity ^0.4.18;


import "../../contracts/crowdsale/RefundableCrowdsale.sol";

contract RefundableCrowdsaleImpl is RefundableCrowdsale {

  function RefundableCrowdsaleImpl (
    uint256 _startTime,
    uint256 _endTime,
    uint256 _rate,
    address _wallet,
    uint256 _goal,
    HomelendToken _token
  ) public
    Crowdsale(_startTime, _endTime, _rate, _wallet, _token)
    RefundableCrowdsale(_goal)
  {
  }

      function claimTokenOwnership() external onlyOwner {
        token.claimOwnership();
    }
}