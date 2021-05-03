// This is an ERC20PresetFixedSupply contract.
// This is used to create Richedu tokens RCED.
// This contract is deployed first.
// The contract address is given as the input parameter for deploying ERC721 contract.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol';

contract Cybercafe is ERC20PresetFixedSupply {
    constructor() ERC20PresetFixedSupply('Richedu','RCED', 10000000000000000000000, msg.sender) {}
}
