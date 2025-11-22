const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTRental", function () {
  let nftContract;
  let rentalContract;
  let owner;
  let renter;
  let accounts;
  let tokenId = 1;

  beforeEach(async function () {
    // 获取帐户
    [owner, renter, ...accounts] = await ethers.getSigners();

    // 部署NFT合约 (使用OpenZeppelin的ERC721合约)
    const ERC721Mock = await ethers.getContractFactory("ERC721PresetMinterPauserAutoId");
    nftContract = await ERC721Mock.deploy("TestNFT", "TNFT", "https://token.com/");
    await nftContract.deployed();

    // 给owner mint一个NFT
    await nftContract.mint(owner.address);
    expect(await nftContract.ownerOf(tokenId)).to.equal(owner.address);

    // 部署NFTRental合约
    const NFTRental = await ethers.getContractFactory("NFTRental");
    rentalContract = await NFTRental.deploy();
    await rentalContract.deployed();
  });

  it("should verify valid EIP712 signature and rent NFT", async function () {
    const rentoutOrder = {
      maker: owner.address,
      nft_ca: nftContract.address,
      token_id: tokenId,
      daily_rent: ethers.utils.parseEther("0.01"), // 每日租金0.01ETH
      max_rental_duration: 7, // 最长租赁7天
      min_collateral: ethers.utils.parseEther("0.05"), // 押金0.05ETH
      list_endtime: Math.floor(Date.now() / 1000) + 86400, // 挂单24小时后过期
    };

    // 计算租赁订单的哈希
    const domainSeparator = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        ["bytes32", "bytes32", "bytes32", "uint256", "address"],
        [
          ethers.utils.keccak256(
            ethers.utils.toUtf8Bytes("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
          ),
          ethers.utils.keccak256(ethers.utils.toUtf8Bytes("NFTRental")),
          ethers.utils.keccak256(ethers.utils.toUtf8Bytes("1")),
          ethers.provider.network.chainId,
          rentalContract.address
        ]
      )
    );

    const rentoutOrderHash = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        ["bytes32", "address", "address", "uint256", "uint256", "uint256", "uint256", "uint256"],
        [
          ethers.utils.keccak256(
            ethers.utils.toUtf8Bytes("RentoutOrder(address maker,address nft_ca,uint256 token_id,uint256 daily_rent,uint256 max_rental_duration,uint256 min_collateral,uint256 list_endtime)")
          ),
          rentoutOrder.maker,
          rentoutOrder.nft_ca,
          rentoutOrder.token_id,
          rentoutOrder.daily_rent,
          rentoutOrder.max_rental_duration,
          rentoutOrder.min_collateral,
          rentoutOrder.list_endtime
        ]
      )
    );

    const messageHash = ethers.utils.keccak256(
      ethers.utils.solidityPack(
        ["string", "bytes32", "bytes32"],
        ["\x19\x01", domainSeparator, rentoutOrderHash]
      )
    );

    // owner 对租赁订单进行离线签名
    const signature = await owner.signMessage(ethers.utils.arrayify(messageHash));

    // Renter进行租赁支付和签名验证
    const rentDuration = 3; // 租赁3天
    const totalRent = ethers.utils.parseEther("0.03"); // 总租金为 0.01 * 3
    const collateral = ethers.utils.parseEther("0.05"); // 押金为0.05 ETH

    await nftContract.connect(owner).approve(rentalContract.address, tokenId);

    await expect(
      rentalContract.connect(renter).rentNFT(rentoutOrder, signature, rentDuration, {
        value: totalRent.add(collateral),
      })
    ).to.emit(rentalContract, "Rented")
      .withArgs(renter.address, tokenId);

    // 检查NFT是否已经转移到租户 (renter) 的地址
    expect(await nftContract.ownerOf(tokenId)).to.equal(renter.address);
  });

  it("should fail when signature is invalid", async function () {
    const rentoutOrder = {
      maker: owner.address,
      nft_ca: nftContract.address,
      token_id: tokenId,
      daily_rent: ethers.utils.parseEther("0.01"),
      max_rental_duration: 7,
      min_collateral: ethers.utils.parseEther("0.05"),
      list_endtime: Math.floor(Date.now() / 1000) + 86400,
    };

    // 生成无效签名（使用renter的私钥签名而不是owner）
    const invalidSignature = await renter.signMessage(ethers.utils.arrayify(ethers.utils.randomBytes(32)));

    await nftContract.connect(owner).approve(rentalContract.address, tokenId);

    await expect(
      rentalContract.connect(renter).rentNFT(rentoutOrder, invalidSignature, 3, {
        value: ethers.utils.parseEther("0.08"),
      })
    ).to.be.revertedWith("Invalid signature");
  });
});
