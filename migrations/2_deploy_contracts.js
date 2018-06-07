var HomelendTokenCrowdsale = artifacts.require("HomelendTokenCrowdsale");
var HomelendToken = artifacts.require("HomelendToken");


// module.exports = async function (deployer, network, accounts) {
//   const startTime = web3.eth.getBlock(web3.eth.blockNumber).timestamp + 1 // one second in the future
//   const endTime = startTime + (86400 * 20) // 20 days
//   const rate = new web3.BigNumber(3200)
//   const goal = web3.toWei(10000, 'ether')
//   const wallet = accounts[3];
//   //const token = accounts[4];

//   console.log("ran");
//   console.log(startTime, endTime, rate, goal, wallet)

//   var token = await deployer.deploy(HomelendToken);
//   deployer.deploy(HomelendTokenCrowdsale, startTime, endTime, rate, wallet, goal, token).then(() => console.log('address: ', token.address));
// };

module.exports = async function (deployer, network, accounts) {
  const startTime = web3.eth.getBlock(web3.eth.blockNumber).timestamp + 1 // one second in the future
  const endTime = startTime + (60 * 5)
  const goal = web3.toWei( 12 , 'ether')
  const wallet = accounts[3];
  const walletTeam = accounts[4];
  const walletAdvisor = accounts[5];

  console.log("ran");
  console.log(startTime, endTime, goal, wallet,walletTeam,walletAdvisor)


  deployer.deploy(HomelendToken).then(() => {
    return deployer.deploy(HomelendTokenCrowdsale, startTime, endTime, wallet,walletTeam,walletAdvisor, goal, HomelendToken.address);
  }).then(async () => {
    console.log("deployed!");
    console.log("HomelendTokenCrowdsale", HomelendTokenCrowdsale.address);
    console.log("HomelendToken", HomelendToken.address);
    console.log("transferOwnership -start");
    var token = await HomelendToken.deployed();
    var crowdsale = await HomelendTokenCrowdsale.deployed();

    let owner = await token.owner();
    console.log("token owner - before",owner);

    await token.transferOwnership(HomelendTokenCrowdsale.address);
    // let pendingOwner = await token.pendingOwner();
    // console.log("pend",pendingOwner);
    
    // await token.claimOwnership({from: pendingOwner});

    await crowdsale.claimTokenOwnership();
    let ownerNow = await token.owner();

    console.log("token owner - now",ownerNow);
  });
};