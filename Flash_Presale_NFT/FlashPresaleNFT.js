const Web3 = require('web3');
const { FlashbotsBundleProvider, Flashbots } = require('@flashbots/mev-boost');
const web3 = new Web3('https://sepolia.infura.io/v3/YOUR_INFURA_PROJECT_ID');

// 请替换为你的私钥
const PRIVATE_KEY = 'YOUR_PRIVATE_KEY';
const ACCOUNT = web3.eth.accounts.privateKeyToAccount(PRIVATE_KEY);

// 替换为你的合约地址
const CONTRACT_ADDRESS = 'YOUR_CONTRACT_ADDRESS';

// 合约 ABI
const abi = [
    // 这里应该包含所有你需要调用的方法的 ABI
    // 例如：
    "function enablePresale() external",
    "function presale(uint256) external payable"
];

const contract = new web3.eth.Contract(abi, CONTRACT_ADDRESS);

async function main() {
    const provider = web3.currentProvider;
    const flashbotsProvider = await FlashbotsBundleProvider.create(provider, ACCOUNT.address, provider);

    // 创建 Flashbots 实例
    const flashbots = new Flashbots(flashbotsProvider, ACCOUNT.address);

    // 构建交易
    const enablePresaleTx = contract.methods.enablePresale().encodeABI();
    const presaleTx = contract.methods.presale(10).encodeABI();

    // 创建交易对象
    const txs = [
        {
            to: CONTRACT_ADDRESS,
            data: enablePresaleTx,
            gas: 210000,
            value: 0,
            nonce: await web3.eth.getTransactionCount(ACCOUNT.address),
            gasPrice: await web3.eth.getGasPrice()
        },
        {
            to: CONTRACT_ADDRESS,
            data: presaleTx,
            gas: 210000,
            value: web3.utils.toWei('0.1', 'ether'), // 假设每个 NFT 价格为 0.01 ETH
            nonce: (await web3.eth.getTransactionCount(ACCOUNT.address)) + 1,
            gasPrice: await web3.eth.getGasPrice()
        }
    ];

    // 签名交易
    const signedTxs = await Promise.all(txs.map(async (tx) => {
        return await ACCOUNT.signTransaction(tx);
    }));

    // 发送捆绑包
    const blockNumber = await web3.eth.getBlockNumber();
    const bundle = signedTxs.map((stx) => ({
        signedTransaction: stx.rawTransaction
    }));

    const response = await flashbots.sendBundle(bundle, blockNumber + 1);

    // 查询捆绑包状态
    const stats = await flashbots.getBundleStats(response.bundleHash, blockNumber + 1);

    console.log(`Transaction Hashes: ${response.bundleHash}`);
    console.log(`Bundle Stats: ${JSON.stringify(stats, null, 2)}`);
}

main().catch(console.error);