import { createPublicClient, http, watchBlock, watchEvent } from 'viem';
import { mainnet } from 'viem/chains';

const client = createPublicClient({
  chain: mainnet,
  transport: http('https://mainnet.infura.io/v3/YOUR_INFURA_PROJECT_ID'),
});

function listenForNewBlocks() {
  const unwatch = watchBlock(client, ({ block }) => {
    console.log(`New block: ${block.number} (${block.hash})`);
  });

  // 如果需要停止监听，可以调用 unwatch()
  // unwatch();
}

function listenForUSDTTransfers() {
  const usdtAddress = '0xdac17f958d2ee523a2206206994597c13d831ec7';
  const usdtAbi = [
    'event Transfer(address indexed from, address indexed to, uint256 value)'
  ];

  const unwatch = watchEvent(client, {
    address: usdtAddress,
    abi: usdtAbi,
    eventName: 'Transfer',
  }, async (log) => {
    const { args, blockNumber, transactionHash } = log;
    const from = args.from;
    const to = args.to;
    const value = args.value / 10**6; // USDT 有 6 位小数

    console.log(`Transfer in block ${blockNumber} (${transactionHash}):`);
    console.log(`From: ${from}`);
    console.log(`To: ${to}`);
    console.log(`Amount: ${value} USDT`);
  });

  // 如果需要停止监听，可以调用 unwatch()
  // unwatch();
}

listenForNewBlocks();
listenForUSDTTransfers();