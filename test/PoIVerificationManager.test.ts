import { expect } from "./helpers/setup";
import hre from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import { getAddress } from "viem";
import { PoIVerificationManagerErrorMap } from "./helpers/errorMessages";

describe("PoIVerificationManager", function () {
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

        // Deploy PoIVerificationManager
        const poiManager = await hre.viem.deployContract("PoIVerificationManager", [
            verifierRegistry.address,
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
            poiManager,
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
        it("Should set the correct VerifierRegistry address", async function () {
            const { poiManager, verifierRegistry } = await loadFixture(deployContractsFixture);
            expect(await poiManager.read.verifierRegistry()).to.equal(getAddress(verifierRegistry.address));
        });

        it("Should revert if VerifierRegistry address is zero", async function () {
            await expect(
                hre.viem.deployContract("PoIVerificationManager", [
                    "0x0000000000000000000000000000000000000000",
                ])
            ).to.be.rejectedWith(PoIVerificationManagerErrorMap.POIVERIFICATION__InvalidVerifierRegistry);
        });
    });

    describe("Verification Submission", function () {
        it("Should allow authorized verifier to submit verification", async function () {
            const { poiManager, verifierStaking, user1 } = await loadFixture(deployContractsFixture);
            const amount = 1000n * 10n ** 18n; // 1,000 DCU

            // Make user1 a verifier through staking
            await verifierStaking.write.stakeDCU([amount], {
                account: user1.account,
            });

            const poiId = 1n;
            const status = 1; // Approved
            const reason = "Valid submission";

            await poiManager.write.submitVerification(
                [poiId, status, reason],
                { account: user1.account }
            );

            const result = await poiManager.read.getLatestVerification([poiId]);
            expect(result.verifier).to.equal(getAddress(user1.account.address));
            expect(result.status).to.equal(1);
            expect(result.reason).to.equal(reason);
        });

        it("Should allow additional verifier to submit verification", async function () {
            const { poiManager, verifierRegistry, user2, owner } = await loadFixture(deployContractsFixture);

            // Add user2 as additional verifier
            await verifierRegistry.write.addVerifier([getAddress(user2.account.address)], {
                account: owner.account,
            });

            const poiId = 1n;
            const status = 1; // Approved
            const reason = "Valid submission";

            await poiManager.write.submitVerification(
                [poiId, status, reason],
                { account: user2.account }
            );

            const result = await poiManager.read.getLatestVerification([poiId]);
            expect(result.verifier).to.equal(getAddress(user2.account.address));
            expect(result.status).to.equal(1);
            expect(result.reason).to.equal(reason);
        });

        it("Should revert when non-verifier tries to submit verification", async function () {
            const { poiManager, user1 } = await loadFixture(deployContractsFixture);

            await expect(
                poiManager.write.submitVerification(
                    [1n, 1, "Valid submission"],
                    { account: user1.account }
                )
            ).to.be.rejectedWith(PoIVerificationManagerErrorMap.POIVERIFICATION__NotAuthorizedVerifier);
        });

        it("Should revert when submitting verification with invalid PoI ID", async function () {
            const { poiManager, verifierRegistry, user1, owner } = await loadFixture(deployContractsFixture);

            // Add user1 as verifier
            await verifierRegistry.write.addVerifier([getAddress(user1.account.address)], {
                account: owner.account,
            });

            await expect(
                poiManager.write.submitVerification(
                    [0n, 1, "Valid submission"],
                    { account: user1.account }
                )
            ).to.be.rejectedWith(PoIVerificationManagerErrorMap.POIVERIFICATION__InvalidPoiId);
        });

        it("Should revert when submitting verification with invalid status", async function () {
            const { poiManager, verifierRegistry, user1, owner } = await loadFixture(deployContractsFixture);

            // Add user1 as verifier
            await verifierRegistry.write.addVerifier([getAddress(user1.account.address)], {
                account: owner.account,
            });

            await expect(
                poiManager.write.submitVerification(
                    [1n, 0, "Valid submission"], // 0 = Pending
                    { account: user1.account }
                )
            ).to.be.rejectedWith(PoIVerificationManagerErrorMap.POIVERIFICATION__InvalidStatus);
        });

        it("Should revert when verifier tries to verify same PoI twice", async function () {
            const { poiManager, verifierRegistry, user1, owner } = await loadFixture(deployContractsFixture);

            // Add user1 as verifier
            await verifierRegistry.write.addVerifier([getAddress(user1.account.address)], {
                account: owner.account,
            });

            // First verification
            await poiManager.write.submitVerification(
                [1n, 1, "Valid submission"],
                { account: user1.account }
            );

            // Second verification attempt
            await expect(
                poiManager.write.submitVerification(
                    [1n, 1, "Valid submission"],
                    { account: user1.account }
                )
            ).to.be.rejectedWith(PoIVerificationManagerErrorMap.POIVERIFICATION__AlreadyVerified);
        });
    });

    describe("Verification Queries", function () {
        it("Should return all verification results for a PoI", async function () {
            const { poiManager, verifierRegistry, user1, user2, owner } = await loadFixture(deployContractsFixture);

            // Add both users as verifiers
            await verifierRegistry.write.addVerifier([getAddress(user1.account.address)], {
                account: owner.account,
            });
            await verifierRegistry.write.addVerifier([getAddress(user2.account.address)], {
                account: owner.account,
            });

            await poiManager.write.submitVerification(
                [1n, 1, "Approved by user1"],
                { account: user1.account }
            );
            await poiManager.write.submitVerification(
                [1n, 2, "Rejected by user2"],
                { account: user2.account }
            );

            const results = await poiManager.read.getVerificationResults([1n]);
            expect(results.length).to.equal(2);
            expect(results[0].verifier).to.equal(getAddress(user1.account.address));
            expect(results[0].status).to.equal(1);
            expect(results[0].reason).to.equal("Approved by user1");
            expect(results[1].verifier).to.equal(getAddress(user2.account.address));
            expect(results[1].status).to.equal(2);
            expect(results[1].reason).to.equal("Rejected by user2");
        });

        it("Should correctly report PoI approval status", async function () {
            const { poiManager, verifierRegistry, user1, user2, owner } = await loadFixture(deployContractsFixture);

            // Add both users as verifiers
            await verifierRegistry.write.addVerifier([getAddress(user1.account.address)], {
                account: owner.account,
            });
            await verifierRegistry.write.addVerifier([getAddress(user2.account.address)], {
                account: owner.account,
            });

            // Submit verifications
            await poiManager.write.submitVerification(
                [1n, 1, "First verification"],
                { account: user1.account }
            );
            expect(await poiManager.read.getVerificationCount([1n])).to.equal(1n);

            await poiManager.write.submitVerification(
                [1n, 2, "Second verification"],
                { account: user2.account }
            );
            expect(await poiManager.read.getVerificationCount([1n])).to.equal(2n);
        });

        it("Should revert when getting latest verification for non-existent PoI", async function () {
            const { poiManager } = await loadFixture(deployContractsFixture);

            await expect(
                poiManager.read.getLatestVerification([1n])
            ).to.be.rejectedWith(PoIVerificationManagerErrorMap.POIVERIFICATION__InvalidPoiId);
        });

        it("Should correctly report PoI approval status with multiple verifications", async function () {
            const { poiManager, verifierRegistry, user1, user2, owner } = await loadFixture(deployContractsFixture);

            // Add both users as verifiers
            await verifierRegistry.write.addVerifier([getAddress(user1.account.address)], {
                account: owner.account,
            });
            await verifierRegistry.write.addVerifier([getAddress(user2.account.address)], {
                account: owner.account,
            });

            // Submit verifications for PoI #1
            await poiManager.write.submitVerification(
                [1n, 2, "Rejected first"], // Rejected
                { account: user1.account }
            );
            expect(await poiManager.read.isPoIApproved([1n])).to.equal(false);

            await poiManager.write.submitVerification(
                [1n, 1, "Approved later"], // Approved
                { account: user2.account }
            );
            expect(await poiManager.read.isPoIApproved([1n])).to.equal(true);

            // Submit verifications for PoI #2
            await poiManager.write.submitVerification(
                [2n, 2, "Rejected only"], // Rejected
                { account: user1.account }
            );
            expect(await poiManager.read.isPoIApproved([2n])).to.equal(false);
        });

        it("Should return empty array for PoI with no verifications", async function () {
            const { poiManager } = await loadFixture(deployContractsFixture);
            const results = await poiManager.read.getVerificationResults([1n]);
            expect(results.length).to.equal(0);
        });

        it("Should handle multiple PoIs with multiple verifications", async function () {
            const { poiManager, verifierRegistry, user1, user2, owner } = await loadFixture(deployContractsFixture);

            // Add both users as verifiers
            await verifierRegistry.write.addVerifier([getAddress(user1.account.address)], {
                account: owner.account,
            });
            await verifierRegistry.write.addVerifier([getAddress(user2.account.address)], {
                account: owner.account,
            });

            // Submit verifications for multiple PoIs
            await poiManager.write.submitVerification(
                [1n, 1, "PoI 1 - First verification"],
                { account: user1.account }
            );
            await poiManager.write.submitVerification(
                [2n, 1, "PoI 2 - First verification"],
                { account: user1.account }
            );
            await poiManager.write.submitVerification(
                [1n, 2, "PoI 1 - Second verification"],
                { account: user2.account }
            );

            // Check PoI 1 verifications
            const results1 = await poiManager.read.getVerificationResults([1n]);
            expect(results1.length).to.equal(2);
            expect(results1[0].status).to.equal(1);
            expect(results1[1].status).to.equal(2);

            // Check PoI 2 verifications
            const results2 = await poiManager.read.getVerificationResults([2n]);
            expect(results2.length).to.equal(1);
            expect(results2[0].status).to.equal(1);
        });
    });

    describe("Contract Updates", function () {
        it("Should allow owner to update VerifierRegistry", async function () {
            const { poiManager, verifierRegistry, owner } = await loadFixture(deployContractsFixture);
            const newAddress = verifierRegistry.address; // Using same address for simplicity

            await poiManager.write.updateVerifierRegistry([getAddress(newAddress)], {
                account: owner.account,
            });

            expect(await poiManager.read.verifierRegistry()).to.equal(getAddress(newAddress));
        });

        it("Should revert when updating to zero address", async function () {
            const { poiManager, owner } = await loadFixture(deployContractsFixture);

            await expect(
                poiManager.write.updateVerifierRegistry(["0x0000000000000000000000000000000000000000"], {
                    account: owner.account,
                })
            ).to.be.rejectedWith(PoIVerificationManagerErrorMap.POIVERIFICATION__InvalidVerifierRegistry);
        });

        it("Should revert when non-owner updates registry", async function () {
            const { poiManager, verifierRegistry, user1 } = await loadFixture(deployContractsFixture);

            await expect(
                poiManager.write.updateVerifierRegistry([getAddress(verifierRegistry.address)], {
                    account: user1.account,
                })
            ).to.be.rejectedWith("OwnableUnauthorizedAccount");
        });
    });

    describe("Event Emission", function () {
        it("Should emit PoIVerified event on verification submission", async function () {
            const { poiManager, verifierRegistry, user1, owner, publicClient } = await loadFixture(deployContractsFixture);

            // Add user1 as verifier
            await verifierRegistry.write.addVerifier([getAddress(user1.account.address)], {
                account: owner.account,
            });

            const poiId = 1n;
            const status = 1; // Approved
            const reason = "Event test verification";

            // Watch for the event
            const unwatch = await publicClient.watchEvent({
                address: poiManager.address,
                event: {
                    type: 'event',
                    name: 'PoIVerified',
                    inputs: [
                        { type: 'uint256', name: 'poiId', indexed: true },
                        { type: 'address', name: 'verifier', indexed: true },
                        { type: 'uint8', name: 'status' },
                        { type: 'uint256', name: 'timestamp' },
                        { type: 'string', name: 'reason' }
                    ]
                },
                onLogs: logs => {
                    const log = logs[0];
                    expect(log.args.poiId).to.equal(poiId);
                    expect(log.args.verifier).to.equal(getAddress(user1.account.address));
                    expect(log.args.status).to.equal(status);
                    expect(log.args.reason).to.equal(reason);
                    unwatch();
                }
            });

            await poiManager.write.submitVerification(
                [poiId, status, reason],
                { account: user1.account }
            );
        });

        it("Should emit VerifierRegistryUpdated event on registry update", async function () {
            const { poiManager, verifierRegistry, owner, publicClient } = await loadFixture(deployContractsFixture);
            const oldRegistry = await poiManager.read.verifierRegistry();

            // Watch for the event
            const unwatch = await publicClient.watchEvent({
                address: poiManager.address,
                event: {
                    type: 'event',
                    name: 'VerifierRegistryUpdated',
                    inputs: [
                        { type: 'address', name: 'oldRegistry', indexed: true },
                        { type: 'address', name: 'newRegistry', indexed: true }
                    ]
                },
                onLogs: logs => {
                    const log = logs[0];
                    expect(log.args.oldRegistry).to.equal(oldRegistry);
                    expect(log.args.newRegistry).to.equal(getAddress(verifierRegistry.address));
                    unwatch();
                }
            });

            await poiManager.write.updateVerifierRegistry(
                [getAddress(verifierRegistry.address)],
                { account: owner.account }
            );
        });
    });

    describe("Edge Cases", function () {
        it("Should handle empty reason string in verification", async function () {
            const { poiManager, verifierRegistry, user1, owner } = await loadFixture(deployContractsFixture);

            await verifierRegistry.write.addVerifier([getAddress(user1.account.address)], {
                account: owner.account,
            });

            await poiManager.write.submitVerification(
                [1n, 1, ""], // Empty reason
                { account: user1.account }
            );

            const result = await poiManager.read.getLatestVerification([1n]);
            expect(result.reason).to.equal("");
        });

        it("Should handle maximum uint256 PoI ID", async function () {
            const { poiManager, verifierRegistry, user1, owner } = await loadFixture(deployContractsFixture);

            await verifierRegistry.write.addVerifier([getAddress(user1.account.address)], {
                account: owner.account,
            });

            const maxUint256 = 2n ** 256n - 1n;
            await poiManager.write.submitVerification(
                [maxUint256, 1, "Max PoI ID test"],
                { account: user1.account }
            );

            const result = await poiManager.read.getLatestVerification([maxUint256]);
            expect(result.verifier).to.equal(getAddress(user1.account.address));
        });
    });
});