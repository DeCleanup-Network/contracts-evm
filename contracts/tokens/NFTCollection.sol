// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTCollection is ERC721, Ownable {
    uint256 private _tokenIdCounter;
    
    constructor() ERC721("DCU NFT Collection", "DCUNFT") Ownable(msg.sender) {
        _tokenIdCounter = 0;
    }

    function mint(address to) external onlyOwner returns (uint256) {
        uint256 tokenId = _tokenIdCounter;
        _safeMint(to, tokenId);
        _tokenIdCounter++;
        return tokenId;
    }
} 