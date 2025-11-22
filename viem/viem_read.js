import { createPublicClient, http } from 'viem';
import { mainnet } from 'viem/chains';

const client = createPublicClient({
  chain: mainnet,
  transport: http('https://mainnet.infura.io/v3/YOUR_INFURA_PROJECT_ID'),
});

async function getOwnerOf(tokenId) {
  const contractAddress = '0x0483b0dfc6c78062b9e999a82ffb795925381415';
  const abi = [
    'function ownerOf(uint256 tokenId) view returns (address)',
  ];

  try {
    const owner = await client.readContract({
      address: contractAddress,
      abi: abi,
      functionName: 'ownerOf',
      args: [BigInt(tokenId)],
    });
    console.log(`Owner of token ${tokenId}:`, owner);
    return owner;
  } catch (error) {
    console.error('Error getting owner:', error);
  }
}

async function getTokenURI(tokenId) {
  const contractAddress = '0x0483b0dfc6c78062b9e999a82ffb795925381415';
  const abi = [
    'function tokenURI(uint256 tokenId) view returns (string)',
  ];

  try {
    const uri = await client.readContract({
      address: contractAddress,
      abi: abi,
      functionName: 'tokenURI',
      args: [BigInt(tokenId)],
    });
    console.log(`Token URI for token ${tokenId}:`, uri);
    return uri;
  } catch (error) {
    console.error('Error getting token URI:', error);
  }
}

const tokenId = 1; // 替换为你想要查询的 NFT 的 tokenId

getOwnerOf(tokenId).then(owner => {
  if (owner) {
    getTokenURI(tokenId).then(uri => {
      if (uri) {
        console.log(`Token ${tokenId} is owned by ${owner} and has metadata URI: ${uri}`);
      }
    });
  }
});