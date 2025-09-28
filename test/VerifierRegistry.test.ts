import { expect } from "./helpers/setup";
import hre from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import { getAddress } from "viem";

describe("VerifierRegistry", function () {
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

        // Deploy VerifierRegistry
        const verifierRegistry = await hre.viem.deployContract("VerifierRegistry", [
            verifierStaking.address,
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
            verifierRegistry,
            verifierStaking,
            dcuToken,
            owner,
            user1,
            user2,
            publicClient,
        };
    }

    describe("Deployment", function () {
        it("Should set the correct VerifierStaking address", async function () {
            const { verifierRegistry, verifierStaking } = await loadFixture(deployContractsFixture);
            expect(await verifierRegistry.read.verifierStaking()).to.equal(getAddress(verifierStaking.address));
        });

        it("Should revert if VerifierStaking address is zero", async function () {
            await expect(
                hre.viem.deployContract("VerifierRegistry", [
                    "0x0000000000000000000000000000000000000000",
                ])
            ).to.be.rejectedWith("REGISTRY__InvalidVerifierStaking");
        });
    });

    describe("Verifier Status", function () {
        it("Should recognize staked verifiers", async function () {
            const { verifierRegistry, verifierStaking, user1 } = await loadFixture(deployContractsFixture);
            const amount = 1000n * 10n ** 18n; // 1,000 DCU

            // Initially not a verifier
            expect(await verifierRegistry.read.isVerifier([getAddress(user1.account.address)])).to.equal(false);

            // Stake and become a verifier
            await verifierStaking.write.stakeDCU([amount], {
                account: user1.account,
            });
            expect(await verifierRegistry.read.isVerifier([getAddress(user1.account.address)])).to.equal(true);
        });

        it("Should recognize additional verifiers", async function () {
            const { verifierRegistry, user2, owner } = await loadFixture(deployContractsFixture);

            // Initially not a verifier
            expect(await verifierRegistry.read.isVerifier([getAddress(user2.account.address)])).to.equal(false);

            // Add as additional verifier
            await verifierRegistry.write.addVerifier([getAddress(user2.account.address)], {
                account: owner.account,
            });
            expect(await verifierRegistry.read.isVerifier([getAddress(user2.account.address)])).to.equal(true);
        });

        it("Should revert isVerifier check for zero address", async function () {
            const { verifierRegistry } = await loadFixture(deployContractsFixture);

            await expect(
                verifierRegistry.read.isVerifier(["0x0000000000000000000000000000000000000000"])
            ).to.be.rejectedWith("REGISTRY__InvalidAddress");
        });
    });

    describe("Additional Verifiers Management", function () {
        it("Should allow owner to add verifier", async function () {
            const { verifierRegistry, user1, owner } = await loadFixture(deployContractsFixture);

            await verifierRegistry.write.addVerifier([getAddress(user1.account.address)], {
                account: owner.account,
            });

            expect(await verifierRegistry.read.isAdditionalVerifier([getAddress(user1.account.address)])).to.equal(true);
        });

        it("Should revert when adding zero address as verifier", async function () {
            const { verifierRegistry, owner } = await loadFixture(deployContractsFixture);

            await expect(
                verifierRegistry.write.addVerifier(["0x0000000000000000000000000000000000000000"], {
                    account: owner.account,
                })
            ).to.be.rejectedWith("REGISTRY__InvalidAddress");
        });

        it("Should revert when adding existing verifier", async function () {
            const { verifierRegistry, user1, owner } = await loadFixture(deployContractsFixture);

            await verifierRegistry.write.addVerifier([getAddress(user1.account.address)], {
                account: owner.account,
            });

            await expect(
                verifierRegistry.write.addVerifier([getAddress(user1.account.address)], {
                    account: owner.account,
                })
            ).to.be.rejectedWith("REGISTRY__AlreadyVerifier");
        });

        it("Should allow owner to remove verifier", async function () {
            const { verifierRegistry, user1, owner } = await loadFixture(deployContractsFixture);

            await verifierRegistry.write.addVerifier([getAddress(user1.account.address)], {
                account: owner.account,
            });
            await verifierRegistry.write.removeVerifier([getAddress(user1.account.address)], {
                account: owner.account,
            });

            expect(await verifierRegistry.read.isAdditionalVerifier([getAddress(user1.account.address)])).to.equal(false);
        });

        it("Should revert when removing non-existent verifier", async function () {
            const { verifierRegistry, user1, owner } = await loadFixture(deployContractsFixture);

            await expect(
                verifierRegistry.write.removeVerifier([getAddress(user1.account.address)], {
                    account: owner.account,
                })
            ).to.be.rejectedWith("REGISTRY__NotVerifier");
        });

        it("Should revert when non-owner adds verifier", async function () {
            const { verifierRegistry, user1, user2 } = await loadFixture(deployContractsFixture);

            await expect(
                verifierRegistry.write.addVerifier([getAddress(user1.account.address)], {
                    account: user2.account,
                })
            ).to.be.rejectedWith("OwnableUnauthorizedAccount");
        });

        it("Should revert when non-owner removes verifier", async function () {
            const { verifierRegistry, user1, user2, owner } = await loadFixture(deployContractsFixture);

            await verifierRegistry.write.addVerifier([getAddress(user1.account.address)], {
                account: owner.account,
            });

            await expect(
                verifierRegistry.write.removeVerifier([getAddress(user1.account.address)], {
                    account: user2.account,
                })
            ).to.be.rejectedWith("OwnableUnauthorizedAccount");
        });
    });

    describe("Contract Updates", function () {
        it("Should allow owner to update VerifierStaking contract", async function () {
            const { verifierRegistry, verifierStaking, owner } = await loadFixture(deployContractsFixture);
            const newAddress = verifierStaking.address; // Using same address for simplicity

            await verifierRegistry.write.updateVerifierStaking([getAddress(newAddress)], {
                account: owner.account,
            });

            expect(await verifierRegistry.read.verifierStaking()).to.equal(getAddress(newAddress));
        });

        it("Should revert when updating to zero address", async function () {
            const { verifierRegistry, owner } = await loadFixture(deployContractsFixture);

            await expect(
                verifierRegistry.write.updateVerifierStaking(["0x0000000000000000000000000000000000000000"], {
                    account: owner.account,
                })
            ).to.be.rejectedWith("REGISTRY__InvalidVerifierStaking");
        });

        it("Should revert when non-owner updates contract", async function () {
            const { verifierRegistry, verifierStaking, user1 } = await loadFixture(deployContractsFixture);

            await expect(
                verifierRegistry.write.updateVerifierStaking([getAddress(verifierStaking.address)], {
                    account: user1.account,
                })
            ).to.be.rejectedWith("OwnableUnauthorizedAccount");
        });
    });
}); 