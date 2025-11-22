const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("Upgradable Contract Tests", function() {
    let factory, proxy, tokenAddr, initialSupply, perMint, price;

    beforeEach(async function() {
        // 部署初始版本的合约
        factory = await ethers.getContractFactory("FactoryV2");
        proxy = await upgrades.deployProxy(factory, ["TEST", "TST", 1000, 100, ethers.utils.parseEther("0.01")]);
        await proxy.deployed();
        tokenAddr = proxy.address;

        // 设置初始供应量和每次铸造的数量
        initialSupply = await proxy.totalSupply();
        perMint = await proxy.perMint();
        price = await proxy.price();  // 获取初始价格
    });

    it("Should mint tokens before upgrade", async function() {
        // 测试升级前的铸造功能，传入需要的以太币
        await proxy.mintInscription(tokenAddr, { value: price });
        let supplyAfterMint = await proxy.totalSupply();
        expect(supplyAfterMint).to.equal(initialSupply.add(perMint));
    });

    it("Should upgrade contract and keep state", async function() {
        // 升级合约
        const UpgradedVersion = await ethers.getContractFactory("UpgradedVersion");
        await upgrades.upgradeProxy(proxy.address, UpgradedVersion);

        // 验证状态未改变
        expect(await proxy.totalSupply()).to.equal(initialSupply);
        expect(await proxy.perMint()).to.equal(perMint);
        expect(await proxy.price()).to.equal(price); // 验证价格没有变化
    });

    it("Should work correctly after upgrade", async function() {
        // 升级合约
        const UpgradedVersion = await ethers.getContractFactory("UpgradedVersion");
        await upgrades.upgradeProxy(proxy.address, UpgradedVersion);

        // 再次测试铸造功能，传入需要的以太币
        await proxy.mintInscription(tokenAddr, { value: price });
        let supplyAfterUpgradeMint = await proxy.totalSupply();
        expect(supplyAfterUpgradeMint).to.equal(initialSupply.add(perMint));
    });
});
