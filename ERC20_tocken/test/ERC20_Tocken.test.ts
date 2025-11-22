// const { expect } = require("chai");
import {expect} from 'chai';

// const { ethers } = require("hardhat");
import {ethers} from "hardhat";
import {BaseERC20} from '../typechain-types';
import {HardhatEthersSigner} from '@nomicfoundation/hardhat-ethers/signers';


describe("BaseERC20 Contract", function () {
    let addr1: HardhatEthersSigner;
    let addr2: HardhatEthersSigner;
    let contract: BaseERC20;
    let accounts: HardhatEthersSigner[];
    let owner: HardhatEthersSigner;

    async function init() {
        // 部署 BaseERC20
        accounts = await ethers.getSigners();
        owner = accounts[0];
        addr1 = accounts[1];
        addr2 = accounts[2];

        const factory = await ethers.getContractFactory('BaseERC20');
        contract = await factory.deploy();
        await contract.waitForDeployment();
    }

    beforeEach(async () => {
        await init();
    })

    describe("Deployment", function () {
        it("Should set the right owner", async function () {
            expect(await contract.balanceOf(owner.address)).to.equal(
                await contract.totalSupply()
            );
        });

        it("Should have the correct name and symbol", async function () {
            expect(await contract.name()).to.equal("BaseERC20");
            expect(await contract.symbol()).to.equal("BERC20");
        });
    });

    describe("Transactions", function () {
        it("Should transfer tokens between accounts", async function () {
            await contract.transfer(addr1.address, 50);

            const addr1Balance = await contract.balanceOf(addr1.address);
            expect(addr1Balance.toString()).to.equal("50"); // 使用 toString() 方法进行比较

            await contract.connect(addr1).transfer(addr2.address, 50);
            const addr2Balance = await contract.balanceOf(addr2.address);
            expect(addr2Balance.toString()).to.equal("50"); // 使用 toString() 方法进行比较
        });

        it("Should fail if sender doesn’t have enough tokens", async function () {
            const initialOwnerBalance = await contract.balanceOf(owner.address);

            await expect(
                contract.connect(addr1).transfer(owner.address, 1)
            ).to.be.revertedWith("ERC20: transfer amount exceeds balance");

            // Owner balance shouldn't have changed
            expect(await contract.balanceOf(owner.address)).to.equal(initialOwnerBalance);
        });

        it("Should update balances after transfers", async function () {
            await contract.transfer(addr1.address, 100);
            await contract.transfer(addr2.address, 50);

            const ownerBalance = await contract.balanceOf(owner.address);
            const totalSupply = await contract.totalSupply();
            // 应当等于总供应量减去两次转账
            expect(ownerBalance).to.equal(totalSupply - BigInt(100 + 50));

            const addr1Balance = await contract.balanceOf(addr1.address);
            expect(addr1Balance).to.equal(BigInt(100));

            const addr2Balance = await contract.balanceOf(addr2.address);
            expect(addr2Balance).to.equal(BigInt(50));
        });
    });

    describe("Minting and Burning", function () {
        it("Should mint new tokens", async function () {
            const oldBalance = await contract.balanceOf(addr1.address);
            await contract.mint(addr1.address, 100);
            const newBalance = await contract.balanceOf(addr1.address);
            expect(newBalance).to.equal(oldBalance + BigInt(100));
        });

        it("Should burn tokens", async function () {
            const totalSupply = await contract.totalSupply();
            const ownerBalance = await contract.balanceOf(owner.address);
            await contract.burn(50);
            const balanceAfterBurn = await contract.balanceOf(owner.address);
            // expect(ownerBalance).to.equal(ownerBalance - BigInt(50));
            expect(balanceAfterBurn).to.equal(ownerBalance - BigInt(50));
            // expect(totalSupply).to.equal(totalSupply - BigInt(50));
            // 还可以比较一下他们两个是否相同
            expect(ownerBalance).to.equal(totalSupply);
        });

        it("Should fail to burn more tokens than available", async function () {

            expect(await contract.burn(1000000)).to.be.revertedWith(
                "ERC20: burn amount exceeds balance"
            );
        });
    });

    describe("Role Management", function () {
        // TODO: 大病区,这个测试还需要再研究下怎么判定
        it("Should allow the owner to add a new owner", async function () {
            await contract.addOwner(addr1.address);
            contract.isOwner(addr1.address).then((res) => {
                expect(res).to.equal(true);
            })

        });

        it("Should allow the owner to remove an owner", async function () {
            await contract.addOwner(addr1.address);
            await contract.removeOwner(addr1.address);
            contract.isOwner(addr1.address).then((res) => {
                expect(res).to.equal(false);
            })
        });

        it("Should fail when a non-owner tries to add an owner", async function () {
            await expect(contract.connect(addr1).addOwner(addr2.address)).to.be.revertedWith("Caller is not the owner");
        });
    });
});
