pragma solidity ^0.4.17;

import './bancor/LimitedTransferBancorSmartToken.sol';
import './bancor/TokenHolder.sol';

contract HomelendToken is TokenHolder, LimitedTransferBancorSmartToken {
  string public name = "Homelend Token";
  string public symbol = "HLD";
  uint8 public decimals = 18;

      function HomelendToken() public {
        //Apart of 'Bancor' computability - triggered when a smart token is deployed
        NewSmartToken(address(this));
    }
}

