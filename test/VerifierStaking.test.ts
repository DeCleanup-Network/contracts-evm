import { expect } from "chai";
import hre from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import { getAddress } from "viem";
import { time } from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";

describe("VerifierStaking", function () {
    async function deployContractsFixture() {
        const [owner, user1, user2] = await hre.viem.getWalletClients();
        const publicClient = await hre.viem.getPublicClient();

        // Deploy DCU token with owner as temporary reward logic
        const dcuToken = await hre.viem.deployContract("DCUToken", [
            owner.account.address, // Use owner as temporary reward logic
        ]);

        // Deploy VerifierStaking
        const verifierStaking = await hre.viem.deployContract("VerifierStaking", [
            dcuToken.address,
        ]);

        // Mint some tokens to users for testing
        await dcuToken.write.mint([getAddress(user1.account.address), 2000n * 10n ** 18n], {
            account: owner.account,
        });
        await dcuToken.write.mint([getAddress(user2.account.address), 2000n * 10n ** 18n], {
            account: owner.account,
        });

        // Approve staking contract
        await dcuToken.write.approve(
            [getAddress(verifierStaking.address), 2000n * 10n ** 18n],
            { account: user1.account }
        );
        await dcuToken.write.approve(
            [getAddress(verifierStaking.address), 2000n * 10n ** 18n],
            { account: user2.account }
        );

        return {
            verifierStaking,
            dcuToken,
            owner,
            user1,
            user2,
            publicClient,
        };
    }

    describe("Deployment", function () {
        it("Should set the correct DCU token address", async function () {
            const { verifierStaking, dcuToken } = await loadFixture(deployContractsFixture);
            expect(await verifierStaking.read.dcuToken()).to.equal(getAddress(dcuToken.address));
        });

        it("Should revert if DCU token address is zero", async function () {
            await expect(
                hre.viem.deployContract("VerifierStaking", [
                    "0x0000000000000000000000000000000000000000",
                ])
            ).to.be.rejectedWith("STAKE__InvalidDCUToken");
        });
    });

    describe("Staking", function () {
        it("Should allow staking minimum amount", async function () {
            const { verifierStaking, user1 } = await loadFixture(deployContractsFixture);
            const amount = 1000n * 10n ** 18n; // 1,000 DCU

            await verifierStaking.write.stakeDCU([amount], {
                account: user1.account,
            });

            const stakeInfo = await verifierStaking.read.getStakeInfo([getAddress(user1.account.address)]);
            expect(stakeInfo[0]).to.equal(amount); // amount
            expect(stakeInfo[2]).to.equal(true); // isActive
        });

        it("Should revert when staking below minimum", async function () {
            const { verifierStaking, user1 } = await loadFixture(deployContractsFixture);
            const belowMinimum = 999n * 10n ** 18n; // 999 DCU

            await expect(
                verifierStaking.write.stakeDCU([belowMinimum], {
                    account: user1.account,
                })
            ).to.be.rejectedWith("STAKE__InsufficientStakeAmount");
        });

        it("Should revert when staking zero amount", async function () {
            const { verifierStaking, user1 } = await loadFixture(deployContractsFixture);

            await expect(
                verifierStaking.write.stakeDCU([0n], {
                    account: user1.account,
                })
            ).to.be.rejectedWith("STAKE__InvalidAmount");
        });

        it("Should revert when staking twice", async function () {
            const { verifierStaking, user1 } = await loadFixture(deployContractsFixture);
            const amount = 1000n * 10n ** 18n; // 1,000 DCU

            await verifierStaking.write.stakeDCU([amount], {
                account: user1.account,
            });

            await expect(
                verifierStaking.write.stakeDCU([amount], {
                    account: user1.account,
                })
            ).to.be.rejectedWith("STAKE__StakeAlreadyExists");
        });
    });

    describe("Unstaking", function () {
        it("Should revert when unstaking before delay", async function () {
            const { verifierStaking, user1 } = await loadFixture(deployContractsFixture);
            const amount = 1000n * 10n ** 18n; // 1,000 DCU

            await verifierStaking.write.stakeDCU([amount], {
                account: user1.account,
            });

            await expect(
                verifierStaking.write.unstakeDCU({
                    account: user1.account,
                })
            ).to.be.rejectedWith("STAKE__UnstakingLocked");
        });

        it("Should allow unstaking after delay", async function () {
            const { verifierStaking, user1 } = await loadFixture(deployContractsFixture);
            const amount = 1000n * 10n ** 18n; // 1,000 DCU

            await verifierStaking.write.stakeDCU([amount], {
                account: user1.account,
            });

            await time.increase(7 * 24 * 60 * 60); // 7 days

            await verifierStaking.write.unstakeDCU({
                account: user1.account,
            });

            const stakeInfo = await verifierStaking.read.getStakeInfo([getAddress(user1.account.address)]);
            expect(stakeInfo[2]).to.equal(false); // isActive
            expect(stakeInfo[0]).to.equal(0n); // amount
        });

        it("Should revert when unstaking with no stake", async function () {
            const { verifierStaking, user2 } = await loadFixture(deployContractsFixture);

            await expect(
                verifierStaking.write.unstakeDCU({
                    account: user2.account,
                })
            ).to.be.rejectedWith("STAKE__NoStakeFound");
        });
    });

    describe("Increasing Stake", function () {
        it("Should allow increasing stake", async function () {
            const { verifierStaking, user1 } = await loadFixture(deployContractsFixture);
            const initialAmount = 1000n * 10n ** 18n; // 1,000 DCU
            const additionalAmount = 500n * 10n ** 18n; // 500 DCU

            await verifierStaking.write.stakeDCU([initialAmount], {
                account: user1.account,
            });

            await verifierStaking.write.increaseStake([additionalAmount], {
                account: user1.account,
            });

            const stakeInfo = await verifierStaking.read.getStakeInfo([getAddress(user1.account.address)]);
            expect(stakeInfo[0]).to.equal(initialAmount + additionalAmount);
        });

        it("Should revert when increasing stake with zero", async function () {
            const { verifierStaking, user1 } = await loadFixture(deployContractsFixture);
            const amount = 1000n * 10n ** 18n; // 1,000 DCU

            await verifierStaking.write.stakeDCU([amount], {
                account: user1.account,
            });

            await expect(
                verifierStaking.write.increaseStake([0n], {
                    account: user1.account,
                })
            ).to.be.rejectedWith("STAKE__InvalidAmount");
        });

        it("Should revert when increasing non-existent stake", async function () {
            const { verifierStaking, user2 } = await loadFixture(deployContractsFixture);
            const amount = 1000n * 10n ** 18n; // 1,000 DCU

            await expect(
                verifierStaking.write.increaseStake([amount], {
                    account: user2.account,
                })
            ).to.be.rejectedWith("STAKE__NoStakeFound");
        });
    });

    describe("Verifier Status", function () {
        it("Should correctly report verifier status", async function () {
            const { verifierStaking, user1 } = await loadFixture(deployContractsFixture);
            const amount = 1000n * 10n ** 18n; // 1,000 DCU

            expect(await verifierStaking.read.isVerifier([getAddress(user1.account.address)])).to.equal(false);

            await verifierStaking.write.stakeDCU([amount], {
                account: user1.account,
            });
            expect(await verifierStaking.read.isVerifier([getAddress(user1.account.address)])).to.equal(true);

            await time.increase(7 * 24 * 60 * 60); // 7 days
            await verifierStaking.write.unstakeDCU({
                account: user1.account,
            });
            expect(await verifierStaking.read.isVerifier([getAddress(user1.account.address)])).to.equal(false);
        });
    });

    describe("Admin Functions", function () {
        it("Should allow owner to update DCU token", async function () {
            const { verifierStaking, dcuToken, owner } = await loadFixture(deployContractsFixture);
            const newToken = dcuToken.address; // Using same token for simplicity

            await verifierStaking.write.updateDCUToken([getAddress(newToken)], {
                account: owner.account,
            });

            expect(await verifierStaking.read.dcuToken()).to.equal(getAddress(newToken));
        });

        it("Should revert when non-owner updates DCU token", async function () {
            const { verifierStaking, dcuToken, user1 } = await loadFixture(deployContractsFixture);

            await expect(
                verifierStaking.write.updateDCUToken([getAddress(dcuToken.address)], {
                    account: user1.account,
                })
            ).to.be.rejectedWith("OwnableUnauthorizedAccount");
        });

        it("Should revert when updating to zero address", async function () {
            const { verifierStaking, owner } = await loadFixture(deployContractsFixture);

            await expect(
                verifierStaking.write.updateDCUToken(["0x0000000000000000000000000000000000000000"], {
                    account: owner.account,
                })
            ).to.be.rejectedWith("STAKE__InvalidDCUToken");
        });
    });
});