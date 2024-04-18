module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545, // Default Ganache UI port
      network_id: "*", // Match any network id
    },
  },
  compilers: {
    solc: {
      version: "0.8.0", // Ensure this matches your contract's Solidity version
    },
  },
};
