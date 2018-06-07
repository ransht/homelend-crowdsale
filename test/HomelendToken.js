const HomelendToken = artifacts.require('../contracts/HomelendToken.sol');
const utils = require('./helpers/Utils');

contract('HomelendToken', (accounts) => {
    let token;
    let owner = accounts[0];

    beforeEach(async () => {
        token = await HomelendToken.new();
    });

    describe('construction', async () => {
        it('should be ownable', async () => {
            assert.equal(await token.owner(), owner);
        });

        it('should return correct name after construction', async () => {
            assert.equal(await token.name(), "Homelend Token");
        });

        it('should return correct symbol after construction', async () => {
            assert.equal(await token.symbol(), 'HLD');
        });

        it('should return correct decimal points after construction', async () => {
            assert.equal(await token.decimals(), 18);
        });

        it('should be initialized as not transferable', async () => {
            assert.equal(await token.transfersEnabled(), false);
        });

        it('should throw when attempting to transfer by default', async () => {
            let token = await HomelendToken.new();
            await token.issue(accounts[0], 1000);
            let balance = await token.balanceOf.call(accounts[0]);
            assert.equal(balance, 1000);

            try {
                await token.transfer(accounts[1], 100);
                assert(false, "didn't throw");
            } catch (error) {
                return utils.ensureException(error);
            }
        });
    });
});
