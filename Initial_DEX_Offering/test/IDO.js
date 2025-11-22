const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("IDO Contract", function () {
  let IDO, ido, Token, token;
  let owner, addr1, addr2;
  let price = ethers.utils.parseEther("0.001"); // 每个 Token 的价格为 0.001 ETH
  let target = ethers.utils.parseEther("1");   // 募集目标为 1 ETH
  let cap = ethers.utils.parseEther("2");      // 募集上限为 2 ETH
  let duration = 60 * 60 * 24;                 // 预售时长 24 小时

  beforeEach(async function () {
    // 部署 ERC20 Token 合约
    Token = await ethers.getContractFactory("ERC20Mock"); // 使用ERC20标准或Mock合约
    token = await Token.deploy("Test Token", "TTK", ethers.utils.parseEther("1000000"));
    await token.deployed();

    // 部署 IDO 合约
    IDO = await ethers.getContractFactory("IDO");
    ido = await IDO.deploy();
    await ido.deployed();

    [owner, addr1, addr2] = await ethers.getSigners();
  });

  describe("Presale", function () {
    it("Should start the presale", async function () {
      await ido.startPresale(token.address, price, target, cap, duration);
      const presaleActive = await ido.presaleActive();
      expect(presaleActive).to.equal(true);
    });

    it("Should allow users to participate in the presale", async function () {
      await ido.startPresale(token.address, price, target, cap, duration);

      // addr1 参与预售，支付 0.5 ETH
      await ido.connect(addr1).participate({ value: ethers.utils.parseEther("0.5") });

      // 检查参与后的贡献
      const contribution = await ido.ethContributions(addr1.address);
      expect(contribution).to.equal(ethers.utils.parseEther("0.5"));
    });

    it("Should prevent over contribution above the cap", async function () {
      await ido.startPresale(token.address, price, target, cap, duration);

      // addr1 参与预售，支付 1 ETH
      await ido.connect(addr1).participate({ value: ethers.utils.parseEther("1") });

      // addr2 参与预售，支付 1.5 ETH，超出 cap
      await expect(
        ido.connect(addr2).participate({ value: ethers.utils.parseEther("1.5") })
      ).to.be.revertedWith("Exceeds cap");
    });

    it("Should allow users to claim tokens after successful presale", async function () {
      await ido.startPresale(token.address, price, target, cap, duration);

      // addr1 参与预售，支付 1 ETH
      await ido.connect(addr1).participate({ value: ethers.utils.parseEther("1") });

      // 模拟项目方存入足够的Token供领取
      await token.transfer(ido.address, ethers.utils.parseEther("1000"));

      // 结束预售
      await ethers.provider.send("evm_increaseTime", [duration]); // 快进时间
      await ido.finalizePresale();

      // addr1 领取 Token
      await ido.connect(addr1).claimTokens();
      const balance = await token.balanceOf(addr1.address);
      expect(balance).to.equal(ethers.utils.parseEther("1000")); // 假设价格是0.001ETH, 那么1ETH购买1000个Token
    });

    it("Should allow users to refund if presale fails", async function () {
      await ido.startPresale(token.address, price, target, cap, duration);

      // addr1 参与预售，支付 0.5 ETH (低于目标)
      await ido.connect(addr1).participate({ value: ethers.utils.parseEther("0.5") });

      // 结束预售
      await ethers.provider.send("evm_increaseTime", [duration]);
      await ido.finalizePresale();

      // addr1 退款
      await ido.connect(addr1).refund();
      const balance = await ethers.provider.getBalance(addr1.address);
      expect(balance).to.be.above(ethers.utils.parseEther("99.9")); // 确保退款完成
    });

    it("Should allow owner to withdraw ETH after successful presale", async function () {
      await ido.startPresale(token.address, price, target, cap, duration);

      // addr1 参与预售，支付 1 ETH
      await ido.connect(addr1).participate({ value: ethers.utils.parseEther("1") });

      // 模拟项目方存入足够的Token供领取
      await token.transfer(ido.address, ethers.utils.parseEther("1000"));

      // 结束预售
      await ethers.provider.send("evm_increaseTime", [duration]);
      await ido.finalizePresale();

      // 项目方提现ETH
      const ownerBalanceBefore = await ethers.provider.getBalance(owner.address);
      await ido.connect(owner).finalizePresale();
      const ownerBalanceAfter = await ethers.provider.getBalance(owner.address);

      expect(ownerBalanceAfter).to.be.above(ownerBalanceBefore);
    });
  });
});
