import { ethers, network } from "hardhat";
import { Signer } from "ethers";
import { expect } from "chai";

describe("DAO Contract", function() {
    let DAO, Token;
    let dao: any, token: any;
    let owner: Signer;
    let member: Signer;
    let nonMember: Signer;
    let multisig: Signer;

    const testProposal = "Test Proposal";
    const proposalText = ethers.toUtf8Bytes(testProposal); 

    beforeEach(async function() {
        [owner, member, nonMember, multisig] = await ethers.getSigners();

        Token = await ethers.getContractFactory("Token");
        token = await Token.deploy("TokenBoi", "TBOI", 1000000);
        
        DAO = await ethers.getContractFactory("DAO");
        dao = await DAO.deploy("DAO 2.0", token.getAddress());

        await token.waitForDeployment();
        await dao.waitForDeployment();
    });

    it("Should deploy the DAO contract successfully", async function() {
        expect(await dao.getAddress()).to.properAddress;
    });

    it("Should allow the owner to set the multisig successfully", async () => {
        expect(await dao.connect(owner).setMultisigWallet(multisig)).to.emit(dao, "SetMultisig").withArgs(multisig);
    })

    describe("When user has tokens", function() {
        beforeEach(async function() {
            await token.transfer(member.getAddress(), ethers.parseEther("1000"));
        });

        describe("and multisig wallet is not set", async () => {
            it("User cannot create a proposal", async function() {
                await expect(dao.connect(nonMember).createProposal(ethers.MaxUint256, proposalText)).to.be.revertedWith("Multisig wallet not set");
            });
        })

        describe("and multisig wallet is set", async () => {
            beforeEach(async () => {
                await dao.connect(owner).setMultisigWallet(multisig);
                await dao.connect(member).createProposal(ethers.MaxUint256, proposalText);
            });

            it("User can create a proposal", async function() {
                const proposalCount = await(dao.proposalCount());
                expect(proposalCount).to.eq(1);
                const proposalText = await dao.getProposalText(proposalCount);
                const proposalTextStr = ethers.toUtf8String(proposalText); 
                expect(proposalTextStr).to.equal(testProposal);
            });

            it("User can vote on a proposal", async function() {
                const proposalCount = await(dao.proposalCount());
                await dao.connect(member).vote(proposalCount, true);
            });

            // TODO: write tests for checking votes
        })
    });

    describe("When user does not have tokens but multisig is set", function() {
        beforeEach(async () => {
            await dao.connect(owner).setMultisigWallet(multisig);
        });

        it("User cannot create a proposal", async function() {
            await expect(dao.connect(nonMember).createProposal(ethers.MaxUint256, proposalText)).to.be.revertedWith("Caller is not a member");
        });

        it("User cannot vote on a proposal", async function() {
            await expect(dao.connect(nonMember).vote(1, true)).to.be.revertedWith("Caller is not a member");
        });
    });
});
