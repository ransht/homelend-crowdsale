pragma solidity ^0.4.17;

import './HomelendToken.sol';
import './crowdsale/RefundableCrowdsale.sol';
import './bancor/TokenHolder.sol';

contract HomelendTokenCrowdsale is TokenHolder,RefundableCrowdsale {


    // =================================================================================================================
    //                                      Constants
    // =================================================================================================================
    // Max amount of known addresses of which will get LDC by 'Grant' method.
    //
    // grantees addresses will be Homelend wallets addresses.
    // these wallets will contain LDC tokens that will be used for 2 purposes only -
    // 1. LDC tokens against raised fiat money
    // 2. LDC tokens for presale bonus.
    // we set the value to 10 (and not to 2) because we want to allow some flexibility for cases like fiat money that is raised close to the crowdsale.
    // we limit the value to 10 (and not larger) to limit the run time of the function that process the grantees array.
    uint8 public constant MAX_TOKEN_GRANTEES = 10;

    //we limit the amount of tokens we can mint to a grantee so it won't be exploit.
    uint256 public constant MAX_GRANTEE_TOKENS_ALLOWED = 250000000 * 10 ** 18;    

    // LDC to ETH base rate
    uint256 public constant BASE_EXCHANGE_RATE = 3200;

    //Grantees - used for non-ether and presale bonus token generation
    address[] public presaleGranteesMapKeys;
    mapping (address => uint256) public presaleGranteesMap;  //address=>wei token amount

    // =================================================================================================================
    //                                      Members
    // =================================================================================================================

    // wallets address for 20% of LDC allocation
    address public walletTeam;   //10% of the total number of LDC tokens will be allocated to the team
    address public walletAdvisor;       //10% of the total number of LDC tokens will be allocated to advisor.

    // Funds collected outside the crowdsale in wei
    uint256 public fiatRaisedConvertedToWei;

    // =================================================================================================================
    //                                      Events
    // =================================================================================================================
    event GrantAdded(address indexed _grantee, uint256 _amount);

    event GrantUpdated(address indexed _grantee, uint256 _oldAmount, uint256 _newAmount);

    event GrantDeleted(address indexed _grantee, uint256 _hadAmount);

    event FiatRaisedUpdated(address indexed _address, uint256 _fiatRaised);


    // =================================================================================================================
    //                                      modifiers
    // =================================================================================================================

      /**
     * @dev Throws if called not during the crowdsale time frame
     */
    modifier onlyWhileSale() {
        require(now >= startTime && now < endTime);
        _;
    }

    /**
    * @dev Throws if called after crowdsale was finalized
     */
    modifier beforeFinzalized() {
        require(!isFinalized);
        _;
    }
    /**
     * @dev Throws if called before crowdsale start time
     */
    modifier notBeforeSaleStarts() {
        require(now >= startTime);
        _;
    }

    // =================================================================================================================
    //                                      Constructors
    // =================================================================================================================

  function HomelendTokenCrowdsale(uint256 _startTime, uint256 _endTime, address _wallet,address _walletTeam,address _walletAdvistor,uint _goal,HomelendToken _token) 
    public
    RefundableCrowdsale(_goal) 
    Crowdsale(_startTime, _endTime, BASE_EXCHANGE_RATE, _wallet,_token) {
        require(_wallet != address(0));
        require(_walletTeam != address(0));
        require(_walletAdvistor != address(0));
        require(_goal > 0);

        walletTeam = _walletTeam;
        walletAdvisor = _walletAdvistor;
  }



  // creates the token to be sold.
  // override this method to have crowdsale of a specific MintableToken token.
  function createTokenContract() internal returns (MintableToken) {
    return new HomelendToken();
  }

    // =================================================================================================================
    //                                      Impl FinalizableCrowdsale
    // =================================================================================================================

    //@Override
    function finalization() internal onlyOwner {
        super.finalization();

        // granting bonuses for the pre crowdsale grantees:
        for (uint256 i = 0; i < presaleGranteesMapKeys.length; i++) {
            token.issue(presaleGranteesMapKeys[i], presaleGranteesMap[presaleGranteesMapKeys[i]]);
        }

        // Adding 50% of the total token supply (40% were generated during the crowdsale)
        // 50 * 2 = 100
        uint256 newTotalSupply = token.totalSupply().mul(125).div(100);

        // // 10% of the total number of LDC tokens will be allocated to the team
         token.issue(walletTeam, newTotalSupply.mul(10).div(100));

        // 10% of the total number of LDC tokens will be allocated to advisor.
        token.issue(walletAdvisor, newTotalSupply.mul(10).div(100));

        // Re-enable transfers after the token sale.
        token.disableTransfers(false);

        // Re-enable destroy function after the token sale.
        token.setDestroyEnabled(true);

        // transfer token ownership to crowdsale owner
        token.transferOwnership(owner);
    }

    // @Override Crowdsale#getTokenAmount
    function getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
        return weiAmount.mul(getRate());
    }

    // =================================================================================================================
    //                                      Public Methods
    // =================================================================================================================
    // @return the total funds collected in wei(ETH and none ETH).
    function getTotalFundsRaised() public view returns (uint256) {
        return fiatRaisedConvertedToWei.add(weiRaised);
    }

     // overriding Crowdsale#hasEnded to add cap logic
    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        bool capReached = getTotalFundsRaised() >= goal;
        return capReached || super.hasEnded();
    }

    // overriding Crowdsale#validPurchase to add extra cap logic
    // @return true if investors can buy at the moment
    function validPurchase() internal view returns (bool) {
        bool withinCap = getTotalFundsRaised() < goal;
        return withinCap && super.validPurchase();
    }

   function goalReached() public view returns (bool) {
    return getTotalFundsRaised() >= goal;
   }

//    function getRate() public view returns (uint256) {
//       if (now < (startTime.add(30 seconds))) {return BASE_EXCHANGE_RATE + 960;}  //30%
//       if (now < (startTime.add(60 seconds))) {return BASE_EXCHANGE_RATE + 640;}  //20%
//       if (now < (startTime.add(120 seconds))) {return BASE_EXCHANGE_RATE + 480;}  //15%
//       if (now < (startTime.add(180 seconds))) {return BASE_EXCHANGE_RATE + 320;}  //10%

//     return BASE_EXCHANGE_RATE;
//    }

    function getRate() public view returns (uint256) {
      if (now < (startTime.add(24 hours))) {return BASE_EXCHANGE_RATE + 960;}  //30%
      if (now < (startTime.add(7 days))) {return BASE_EXCHANGE_RATE + 640;}  //20%
      if (now < (startTime.add(14 days))) {return BASE_EXCHANGE_RATE + 480;}  //15%
      if (now < (startTime.add(21 days))) {return BASE_EXCHANGE_RATE + 320;}  //10%

      return BASE_EXCHANGE_RATE;
  }

    // =================================================================================================================
    //                                      External Methods
    // =================================================================================================================
    // @dev Adds/Updates address and token allocation for token grants.
    // Granted tokens are allocated to non-ether, presale, buyers.
    // @param _grantee address The address of the token grantee.
    // @param _value uint256 The value of the grant in wei token.
    function addUpdateGrantee(address _grantee, uint256 _value) external onlyOwner notBeforeSaleStarts beforeFinzalized {
        require(_grantee != address(0));
        require(_value > 0 && _value <= MAX_GRANTEE_TOKENS_ALLOWED);
        
        // Adding new key if not present:
        if (presaleGranteesMap[_grantee] == 0) {
            require(presaleGranteesMapKeys.length < MAX_TOKEN_GRANTEES);
            presaleGranteesMapKeys.push(_grantee);
            GrantAdded(_grantee, _value);
        } else {
            GrantUpdated(_grantee, presaleGranteesMap[_grantee], _value);
        }

        presaleGranteesMap[_grantee] = _value;
    }

    // @dev deletes entries from the grants list.
    // @param _grantee address The address of the token grantee.
    function deleteGrantee(address _grantee) external onlyOwner notBeforeSaleStarts beforeFinzalized {
        require(_grantee != address(0));
        require(presaleGranteesMap[_grantee] != 0);

        //delete from the map:
        delete presaleGranteesMap[_grantee];

        //delete from the array (keys):
        uint256 index;
        for (uint256 i = 0; i < presaleGranteesMapKeys.length; i++) {
            if (presaleGranteesMapKeys[i] == _grantee) {
                index = i;
                break;
            }
        }
        presaleGranteesMapKeys[index] = presaleGranteesMapKeys[presaleGranteesMapKeys.length - 1];
        delete presaleGranteesMapKeys[presaleGranteesMapKeys.length - 1];
        presaleGranteesMapKeys.length--;

        GrantDeleted(_grantee, presaleGranteesMap[_grantee]);
    }

    // @dev Set funds collected outside the crowdsale in wei.
    //  note: we not to use accumulator to allow flexibility in case of humane mistakes.
    // funds are converted to wei using the market conversion rate of USD\ETH on the day on the purchase.
    // @param _fiatRaisedConvertedToWei number of none eth raised.
    function setFiatRaisedConvertedToWei(uint256 _fiatRaisedConvertedToWei) external onlyOwner onlyWhileSale {
        fiatRaisedConvertedToWei = _fiatRaisedConvertedToWei;
        FiatRaisedUpdated(msg.sender, fiatRaisedConvertedToWei);
    }


    /// @dev Accepts new ownership on behalf of the HonelendCrowdsale contract. This can be used, by the token sale
    /// contract itself to claim back ownership of the HonelendToken contract.
    function claimTokenOwnership() external onlyOwner {
        token.claimOwnership();
    }
}