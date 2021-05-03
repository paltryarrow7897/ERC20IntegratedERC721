pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';

contract CryptoCoffee is ERC721Enumerable, ERC721URIStorage, Ownable {
    IERC20 private _token;                      // IERC20 token instance which will be used for payments.
    
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    constructor(IERC20 token) ERC721('CryptoCoffee', 'CRPTCF') {
    // This contract takes in ERC20 contract address for deployment.
        _token = token;
    }
    
    receive() external payable {}
    
    event nftPriceSet(uint256 tokenId, uint256 amount);                     // Emitted when an NFT price is set and put on sale.
    event SaleSuccessful(uint256 tokenId, uint256 price, address buyer);    // Emiited when a buyer successfully transfers RCED tokens to seller.
    
    struct NFT {
      // Edit: string asset has been removed, name change could be limited to web only, no requirement to put on blockchain.
      address owner;        // NFT owner.
      uint256 price;        // NFT sale price.
      bool onSale;          // NFT on sale bool.
      string metadata;      // NFT metadata.
      string hash;          // NFT hash.
    }
    
    mapping(string => bool) hashExists;                   // Map hash to bool.
    mapping(uint256 => NFT) tokenIdToNft;                 // Map token ID to NFT struct.
    mapping(uint256 => uint256) tokenIdToMintingCost;     // Map token ID to its minting cost.
    
    modifier onlySeller(uint256 _tokenId) {
    // Checks if caller is NFT owner or approved address.
        require(_exists(_tokenId));
        require(_isApprovedOrOwner(msg.sender, _tokenId));
        _;
    }
    
    // The following are virtual functions.
    // These do not have any use in this contract.
    // Required to override conflicting functions of ERC721Enumerable and ERC721URIStorage.    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC721) returns (bool) {
         return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    } 
    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
    function tokenURI(uint256 tokenId) public view virtual override(ERC721URIStorage, ERC721) returns (string memory) {
        return super.tokenURI(tokenId);
    }
    // Override functions end here.
    
    function buyRicheduToken() external payable {
    // The first function any new user will interact with.
    // This allows user to pay ether to this smart contract and get RCED tokens to execute all other functions.
        require(msg.value > 0);                                         // Check if user pays at least something.
        require(_token.balanceOf(address(this)) >= msg.value);          // Check if smart contract has enough RCED tokens to give to user.
        _token.transfer(msg.sender, msg.value);                         // Transfer RCED tokens from smart contract to caller.
    }
    
    function sellRicheduToken(uint256 _amount) external {
    // Function to exchange RCED to ETH. 
    // This function assumes user has approved the smart contract to transfer tokens on his behalf.
    // More details on how to approve can be found in README.
    // User inputs how much RCED he wants to exchange into ETH.
        require(_amount > 0);                                               // Check if user exchanges at least some tokens.
        require(_token.allowance(msg.sender, address(this)) >= _amount);    // Check if caller has approved this smart contract for transferring tokens.
        _token.transferFrom(msg.sender, address(this), _amount);            // Transfer RCED tokens from caller to smart contract.
        payable(msg.sender).transfer(_amount);                              // Send ETH to caller.
    }
    
    function mintNFT(string memory _hash, string memory _metadata, uint128 _mintingCost, uint256 userPays) external { 
    // Mint function.
    // _hash, _metadata, _mintingCost automatically fetched.
    // userPays is user input of amount of RCED tokens the user is paying.
        require(hashExists[_hash] != true);                                 // Check if NFT already exists.
        require(_mintingCost == userPays);                                  // Check if userPays is equal to generated mintingCost, revert if not equal.
        hashExists[_hash] = true;                                           // Set hash exists for new NFT.
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();                           // Set token ID for NFT.
        _safeMint(msg.sender, newTokenId);                                  // Mint NFT.
        _setTokenURI(newTokenId, _metadata);
        NFT storage nft = tokenIdToNft[newTokenId];
        nft.metadata = _metadata;                                           // Set metadata in struct.
        nft.hash = _hash;                                                   // Set hash in struct.
        tokenIdToMintingCost[newTokenId] = _mintingCost;                    // Map token ID to its minting cost.
        _token.transferFrom(msg.sender, address(this), _mintingCost);       // Transfer RCED tokens from caller to smart contract.
        nft.owner = msg.sender;                                             // Set owner in struct.
        emit Transfer(address(this), msg.sender, newTokenId);               // Transfer event.
    }
    
    function setPricePutOnSale(uint _tokenId, uint256 _amount) external onlySeller(_tokenId) {
    // Set price of NFT in RCED tokens. 
        NFT storage nft = tokenIdToNft[_tokenId];
        nft.price = _amount;                    // Set NFT price.
        nft.onSale = true;                      // Put NFT on sale.
        emit nftPriceSet(_tokenId, _amount);    // Price set event.
    }
    
    function burnNFT(uint256 _tokenId) external onlySeller(_tokenId) {
    // Burn NFT and send 75% of minting cost back to NFT owner.
        require(tokenIdToNft[_tokenId].onSale != true);           // Check if NFT is on sale. Revert if true.
        delete hashExists[tokenIdToNft[_tokenId].hash];           // Delete hash of the NFT. Allows same NFT to be minted again in future.
        delete tokenIdToNft[_tokenId];                            // Delete NFT struct.
        uint256 mintingCost = tokenIdToMintingCost[_tokenId];     // Get minting cost in RCED.
        uint256 backToUser = mintingCost - mintingCost/4;         // 75% of minting cost to be paid back to user in RCED.
        _token.transfer(msg.sender, backToUser);                  // Transfer RCED tokens.
        _burn(_tokenId);                                          // Burn the NFT.
    }
    
    function buyAtSale(uint256 _tokenId, uint256 userPays) external {
    // Buy NFT at a sale.
        NFT storage nft = tokenIdToNft[_tokenId];
        require(nft.onSale);                                                // Check if NFT is on sale. Revert if not on sale.
        require(nft.price == userPays);                                     // Check if user is paying what seller asks for. Transaction in RCED tokens. Revert if not equal.
        _removeSale(_tokenId);                                              // Remove NFT from sale to avoid someone else to accidentally pay for sold NFT.
        if (nft.price > 0) {
            _token.transferFrom(msg.sender, nft.owner, nft.price);          // Transfer RCED tokens from buyer to NFT owner.
        }
        emit SaleSuccessful(_tokenId, nft.price, msg.sender);               // Success event.
        _transfer(tokenIdToNft[_tokenId].owner, msg.sender, _tokenId);      // Transfer NFT ownership to buyer.
        emit Transfer(tokenIdToNft[_tokenId].owner, msg.sender, _tokenId);  // Transfer event.
        tokenIdToNft[_tokenId].owner = msg.sender;                          // Update owner in mapping.
    }
    
    function _removeSale(uint256 _tokenId) internal {
    // Internal function to remove an NFT from sale after a buyer purchases it.
        delete tokenIdToNft[_tokenId].onSale;
    }
    
    function stopSale(uint256 _tokenId) external onlySeller(_tokenId) {
    // Externally called function. Allows seller to make modifications to the sale.
        delete tokenIdToNft[_tokenId].onSale;
    }
    
    function giftNFT(address _giftTo, uint256 _tokenId) external onlySeller(_tokenId) {
    // Send an NFT for zero RCED tokens.
        require(tokenIdToNft[_tokenId].onSale != true);
        safeTransferFrom(msg.sender, _giftTo, _tokenId);
        emit Transfer(msg.sender, _giftTo, _tokenId);
    }
    
    function owned_NFTs() external view returns (uint256[] memory) {
    // Returns token IDs of all NFTs the caller has.
        uint256[] memory nftList = new uint256[](balanceOf(msg.sender));
        uint256 tokenIndex;
        
        for (tokenIndex = 0; tokenIndex < balanceOf(msg.sender); tokenIndex++) {
            nftList[tokenIndex] = tokenOfOwnerByIndex(msg.sender, tokenIndex);
            }
        return nftList;
    }
    
    function NFT_details(uint256 _tokenId) external view onlySeller(_tokenId) returns (NFT memory) {
    // Returns NFT struct of the token ID.
        return tokenIdToNft[_tokenId];
    }
}
