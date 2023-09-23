const ethers = require("ethers");
const { PrivateKey } = require("@hashgraph/sdk");

// Generate a random secp256k1 private key
const commonPrivateKey = ethers.Wallet.createRandom().privateKey;

//create an ethereum wallet
const wallet = new ethers.Wallet(commonPrivateKey);

// Get the Ethereum address associated with the wallet
const ethereumAddress = wallet.address;

// Create a Hedera Hashgraph PrivateKey object from the common private key
const hederaPrivateKey = PrivateKey.fromString(commonPrivateKey);
const hederaPublicKey = hederaPrivateKey.publicKey;
const aliasAccountId = hederaPublicKey.toAccountId(0, 0);

// Both the Common Private Key and the Ethereum Private Key will be the same
console.log(`Common Private Key (secp256k1): ${commonPrivateKey}`);
console.log(`Ethereum Private Key: ${wallet.privateKey.toString()}`);
console.log(`Ethereum Address: ${ethereumAddress}`);

console.log(`Hedera Private Key: ${hederaPrivateKey.toString()}`);
console.log(`Hedera Public Key: ${hederaPublicKey.toString()}`);
console.log(`Hedera Alias Account ID: ${aliasAccountId}`);
